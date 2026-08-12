// Package keys handles Signal Protocol public key storage — the
// identity key, the (rotating) signed pre-key, and the batch of
// one-time pre-keys that let other users start an encrypted
// conversation with a device even while it's offline.
//
// This package only ever stores/serves PUBLIC keys. Private keys
// never leave the device — that's the entire point of the protocol,
// and matches the "server never sees plaintext or private key
// material" principle from the original security plan.
package keys

import (
	"context"
	"errors"
	"fmt"

	"whatsapp-clone-backend/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// Sentinel errors for GET /users/:userId/keys.
var (
	ErrUserNotFound     = errors.New("user not found")
	ErrNoKeysAvailable  = errors.New("this user has no devices with keys available yet")
)

// Service handles key storage.
type Service struct {
	db *gorm.DB
}

// NewService builds a keys Service.
func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

// UploadResult reports what was actually stored.
type UploadResult struct {
	IdentityKeyStored    bool
	SignedPrekeyStored   bool
	OneTimePrekeysStored int
}

// UploadKeys stores whichever key material is present in req for the
// given device.
func (s *Service) UploadKeys(ctx context.Context, deviceID uuid.UUID, req UploadKeysRequest) (*UploadResult, error) {
	result := &UploadResult{}

	// Explicit upsert via ON CONFLICT, not GORM's Save(). Save()'s
	// create-vs-update choice depends on whether the primary key looks
	// "already set" from GORM's point of view, which is exactly the
	// kind of implicit behavior that caused the UUID bug earlier this
	// week — being explicit here avoids relying on that ambiguity for
	// what is deliberately an insert-or-overwrite operation (a device
	// re-uploading its identity key, e.g. after reinstalling the app,
	// should replace the old one, not silently no-op).
	identityKey := models.SignalIdentityKey{
		DeviceID:          deviceID,
		IdentityPublicKey: req.IdentityPublicKey,
		RegistrationID:    req.RegistrationID,
	}
	if err := s.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "device_id"}},
		DoUpdates: clause.AssignmentColumns([]string{"identity_public_key", "registration_id"}),
	}).Create(&identityKey).Error; err != nil {
		return nil, fmt.Errorf("failed to store identity key: %w", err)
	}
	result.IdentityKeyStored = true

	if req.SignedPrekey != nil {
		// Rotation: deactivate any currently-active signed prekey for
		// this device before inserting the new one, so exactly one
		// stays active — matches the is_active column's purpose in the
		// schema. Old rows are kept (not deleted) for audit/history.
		if err := s.db.WithContext(ctx).Model(&models.SignalSignedPrekey{}).
			Where("device_id = ? AND is_active = ?", deviceID, true).
			Update("is_active", false).Error; err != nil {
			return nil, fmt.Errorf("failed to deactivate previous signed prekey: %w", err)
		}

		signedPrekey := models.SignalSignedPrekey{
			DeviceID:  deviceID,
			KeyID:     req.SignedPrekey.KeyID,
			PublicKey: req.SignedPrekey.PublicKey,
			Signature: req.SignedPrekey.Signature,
			IsActive:  true,
		}
		if err := s.db.WithContext(ctx).Create(&signedPrekey).Error; err != nil {
			return nil, fmt.Errorf("failed to store signed prekey: %w", err)
		}
		result.SignedPrekeyStored = true
	}

	if len(req.OneTimePrekeys) > 0 {
		rows := make([]models.SignalOneTimePrekey, 0, len(req.OneTimePrekeys))
		for _, k := range req.OneTimePrekeys {
			rows = append(rows, models.SignalOneTimePrekey{
				DeviceID:  deviceID,
				KeyID:     k.KeyID,
				PublicKey: k.PublicKey,
			})
		}
		// GORM calls BeforeCreate for every element of a batch insert,
		// so each row gets its own generated ID correctly.
		if err := s.db.WithContext(ctx).Create(&rows).Error; err != nil {
			return nil, fmt.Errorf("failed to store one-time prekeys: %w", err)
		}
		result.OneTimePrekeysStored = len(rows)
	}

	return result, nil
}

// GetUserKeyBundle returns a PreKeyBundle for every active device
// belonging to the given user — enough for a client to establish an
// encrypted session with each one. Devices that haven't finished
// uploading their keys yet (no identity key, or no active signed
// prekey) are silently skipped rather than causing the whole request
// to fail — a user with two devices, only one of which has set up
// keys, should still be reachable on the one that has.
func (s *Service) GetUserKeyBundle(ctx context.Context, userIDStr string) (*KeyBundleResponse, error) {
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return nil, ErrUserNotFound
	}

	var user models.User
	if err := s.db.WithContext(ctx).
		Where("id = ? AND account_status = ?", userID, "active").
		First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to look up user: %w", err)
	}

	var devices []models.Device
	if err := s.db.WithContext(ctx).
		Where("user_id = ? AND status = ?", userID, "active").
		Find(&devices).Error; err != nil {
		return nil, fmt.Errorf("failed to look up devices: %w", err)
	}

	bundles := make([]DeviceKeyBundle, 0, len(devices))
	for _, device := range devices {
		var identityKey models.SignalIdentityKey
		if err := s.db.WithContext(ctx).Where("device_id = ?", device.ID).First(&identityKey).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				continue // this device hasn't uploaded any keys yet
			}
			return nil, fmt.Errorf("failed to look up identity key: %w", err)
		}

		var signedPrekey models.SignalSignedPrekey
		if err := s.db.WithContext(ctx).
			Where("device_id = ? AND is_active = ?", device.ID, true).
			First(&signedPrekey).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				continue // no active signed prekey yet — bundle isn't ready
			}
			return nil, fmt.Errorf("failed to look up signed prekey: %w", err)
		}

		oneTimePrekey, err := s.claimOneTimePrekey(ctx, device.ID)
		if err != nil {
			return nil, fmt.Errorf("failed to claim one-time prekey: %w", err)
		}

		bundles = append(bundles, DeviceKeyBundle{
			DeviceID: device.ID.String(),
			IdentityKey: IdentityKeyOutput{
				PublicKey:      identityKey.IdentityPublicKey,
				RegistrationID: identityKey.RegistrationID,
			},
			SignedPrekey: SignedPrekeyOutput{
				KeyID:     signedPrekey.KeyID,
				PublicKey: signedPrekey.PublicKey,
				Signature: signedPrekey.Signature,
			},
			OneTimePrekey: oneTimePrekey, // nil is a valid, expected outcome
		})
	}

	if len(bundles) == 0 {
		return nil, ErrNoKeysAvailable
	}

	return &KeyBundleResponse{
		UserID:  user.ID.String(),
		Devices: bundles,
	}, nil
}

// claimOneTimePrekey atomically finds and consumes one unused
// one-time pre-key for a device, or returns (nil, nil) if the device
// has none left — running out is a normal, expected state (X3DH
// degrades gracefully to using just the signed pre-key), not an
// error condition.
//
// This is a deliberate exception to "GET requests should be safe/
// read-only": consuming a one-time pre-key as a side effect of
// fetching a key bundle is how the Signal Protocol itself works —
// each one-time key may only ever be handed out once, by design, so
// "fetch" and "consume" are the same operation here, not two steps
// that could be split apart.
//
// The single UPDATE ... WHERE id = (SELECT ... FOR UPDATE SKIP
// LOCKED) statement is atomic in Postgres on its own — no separate
// transaction wrapper needed. FOR UPDATE SKIP LOCKED specifically
// means two concurrent requests for the same device's keys (e.g. two
// people starting a chat with this device at nearly the same moment)
// can never both claim the same row: whichever request's subquery
// runs second simply skips the row the first one already locked and
// finds the next available one instead, rather than blocking or
// racing.
func (s *Service) claimOneTimePrekey(ctx context.Context, deviceID uuid.UUID) (*OneTimePrekeyOutput, error) {
	var claimed struct {
		KeyID     int
		PublicKey string
	}

	err := s.db.WithContext(ctx).Raw(`
		UPDATE signal_one_time_prekeys
		SET is_used = true, used_at = now()
		WHERE id = (
			SELECT id FROM signal_one_time_prekeys
			WHERE device_id = ? AND is_used = false
			ORDER BY created_at
			LIMIT 1
			FOR UPDATE SKIP LOCKED
		)
		RETURNING key_id, public_key
	`, deviceID).Scan(&claimed).Error
	if err != nil {
		return nil, err
	}

	if claimed.PublicKey == "" {
		// No unused row was found for this device — the subquery
		// matched nothing, so the UPDATE (and this RETURNING) produced
		// zero rows. A real stored key can never have an empty
		// public_key (enforced by "required" validation on upload), so
		// this is an unambiguous "none available" signal.
		return nil, nil
	}

	return &OneTimePrekeyOutput{KeyID: claimed.KeyID, PublicKey: claimed.PublicKey}, nil
}
