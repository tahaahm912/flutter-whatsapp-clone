// Package auth holds the registration/login/session business logic
// and its HTTP handlers. It's deliberately split into service.go
// (business rules, DB access) and handler.go (HTTP concerns only) so
// the business logic can be unit-tested later (Week 8) without
// spinning up an HTTP server.
package auth

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"
	"time"

	"whatsapp-clone-backend/internal/models"
	"whatsapp-clone-backend/internal/otp"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// Sentinel errors the handler maps to specific HTTP status codes.
var (
	ErrIdentifierRequired = errors.New("either phone_number or email is required")
	ErrIdentifierTaken    = errors.New("an account with this phone number or email already exists")
	ErrUserNotFound       = errors.New("no account found for that identifier")
	ErrInvalidCredentials = errors.New("invalid identifier or password")
	ErrAccountNotVerified = errors.New("account is not yet verified — complete OTP verification first")
	ErrAccountDisabled    = errors.New("this account is disabled")
	ErrRefreshTokenInvalid = errors.New("refresh token is invalid")
	ErrRefreshTokenExpired = errors.New("refresh token has expired — please log in again")
	ErrTooManyAttempts    = otp.ErrTooManyAttempts
	ErrInvalidOrExpired   = otp.ErrInvalidOrExpired
)

// Service holds everything auth needs: DB access, the OTP service,
// and the secret used to sign JWTs (added today, Week 2 Day 3).
type Service struct {
	db        *gorm.DB
	otp       *otp.Service
	jwtSecret string
}

// NewService builds an auth Service.
func NewService(db *gorm.DB, otpService *otp.Service, jwtSecret string) *Service {
	return &Service{db: db, otp: otpService, jwtSecret: jwtSecret}
}

// Register validates the business rule that at least one identifier
// is present, checks for an existing account, hashes the password,
// inserts the new user row as 'pending_verification', then generates
// and (for now) logs an OTP code for that identifier.
func (s *Service) Register(ctx context.Context, req RegisterRequest) (*models.User, error) {
	if req.PhoneNumber == "" && req.Email == "" {
		return nil, ErrIdentifierRequired
	}

	// Pre-check for a friendly error message. This alone isn't race-safe
	// under concurrent registrations for the exact same identifier — the
	// unique constraint on phone_number/email at the DB level (added in
	// migration 000001) is the actual source of truth. The duplicate-key
	// handling below on the Create() call is what makes this correct
	// even under a race, not this check.
	var count int64
	query := s.db.Model(&models.User{})
	switch {
	case req.PhoneNumber != "" && req.Email != "":
		query = query.Where("phone_number = ? OR email = ?", req.PhoneNumber, req.Email)
	case req.PhoneNumber != "":
		query = query.Where("phone_number = ?", req.PhoneNumber)
	default:
		query = query.Where("email = ?", req.Email)
	}
	if err := query.Count(&count).Error; err != nil {
		return nil, fmt.Errorf("failed to check existing user: %w", err)
	}
	if count > 0 {
		return nil, ErrIdentifierTaken
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	user := models.User{
		Name:          req.Name,
		PasswordHash:  string(hashed),
		AccountStatus: "pending_verification",
	}
	var identifier string
	if req.PhoneNumber != "" {
		phone := req.PhoneNumber
		user.PhoneNumber = &phone
		identifier = phone
	}
	if req.Email != "" {
		email := req.Email
		user.Email = &email
		if identifier == "" {
			identifier = email
		}
	}

	if err := s.db.Create(&user).Error; err != nil {
		if strings.Contains(err.Error(), "duplicate key value violates unique constraint") {
			return nil, ErrIdentifierTaken
		}
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Generate and "send" the OTP. No SMS/email provider is wired up
	// yet (deliberately out of V1's free-to-build scope), so the code
	// is logged for manual testing instead.
	code, err := s.otp.Generate(ctx, identifier)
	if err != nil {
		// The account was already created successfully; a failure here
		// shouldn't fail the whole registration, but it must be visible.
		log.Printf("WARNING: user %s created but OTP generation failed: %v", user.ID, err)
	} else {
		log.Printf("[DEV ONLY] OTP for %s is: %s (expires in 5 minutes)", identifier, code)
	}

	return &user, nil
}

// VerifyOTP checks a submitted code against the one generated for the
// given identifier, and if correct, activates the account and records
// when that identifier was verified.
func (s *Service) VerifyOTP(ctx context.Context, req VerifyOTPRequest) (*models.User, error) {
	if err := s.otp.Verify(ctx, req.Identifier, req.Code); err != nil {
		return nil, err // already one of otp.ErrTooManyAttempts / otp.ErrInvalidOrExpired
	}

	var user models.User
	if err := s.db.Where("phone_number = ? OR email = ?", req.Identifier, req.Identifier).
		First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to look up user: %w", err)
	}

	now := time.Now().UTC()
	updates := map[string]interface{}{"account_status": "active"}
	switch {
	case user.PhoneNumber != nil && *user.PhoneNumber == req.Identifier:
		updates["phone_verified_at"] = now
	case user.Email != nil && *user.Email == req.Identifier:
		updates["email_verified_at"] = now
	}

	if err := s.db.Model(&user).Updates(updates).Error; err != nil {
		return nil, fmt.Errorf("failed to activate account: %w", err)
	}
	user.AccountStatus = "active"

	return &user, nil
}

// LoginResult is what Login returns — the handler converts this into
// the public LoginResponse DTO. Kept separate from the DTO because it
// carries the full *models.User (handler picks only safe fields to
// expose), not because the shapes need to differ otherwise.
type LoginResult struct {
	AccessToken  string
	RefreshToken string
	ExpiresAt    time.Time
	User         *models.User
}

// Login verifies credentials, rejects accounts that aren't active yet
// (unverified/disabled), registers a device for this session, and
// issues a short-lived JWT access token plus a long-lived opaque
// refresh token.
func (s *Service) Login(ctx context.Context, req LoginRequest) (*LoginResult, error) {
	var user models.User
	if err := s.db.WithContext(ctx).
		Where("phone_number = ? OR email = ?", req.Identifier, req.Identifier).
		First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Deliberately the same error as a wrong password below —
			// never reveal whether an identifier exists at all.
			return nil, ErrInvalidCredentials
		}
		return nil, fmt.Errorf("failed to look up user: %w", err)
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, ErrInvalidCredentials
	}

	switch user.AccountStatus {
	case "pending_verification":
		return nil, ErrAccountNotVerified
	case "banned", "deactivated":
		return nil, ErrAccountDisabled
	}

	platform := req.Platform
	if platform == "" {
		platform = "web"
	}
	deviceName := req.DeviceName
	if deviceName == "" {
		deviceName = "Unknown device"
	}

	// TODO(Week 3): once the client sends a stable device identifier,
	// reuse an existing device row instead of creating a new one on
	// every login. For now (and for Postman testing) each login
	// represents a new session/device, which is schema-correct but not
	// yet how a real multi-device client should behave.
	device := models.Device{
		UserID:     user.ID,
		DeviceName: &deviceName,
		Platform:   platform,
		Status:     "active",
	}
	if err := s.db.WithContext(ctx).Create(&device).Error; err != nil {
		return nil, fmt.Errorf("failed to register device: %w", err)
	}

	accessToken, expiresAt, err := generateAccessToken(s.jwtSecret, user.ID, device.ID)
	if err != nil {
		return nil, err
	}

	rawRefresh, refreshHash, err := generateRefreshToken()
	if err != nil {
		return nil, err
	}

	refreshRecord := models.RefreshToken{
		UserID:    user.ID,
		DeviceID:  device.ID,
		TokenHash: refreshHash,
		ExpiresAt: time.Now().Add(refreshTokenTTL),
	}
	if err := s.db.WithContext(ctx).Create(&refreshRecord).Error; err != nil {
		return nil, fmt.Errorf("failed to store refresh token: %w", err)
	}

	return &LoginResult{
		AccessToken:  accessToken,
		RefreshToken: rawRefresh,
		ExpiresAt:    expiresAt,
		User:         &user,
	}, nil
}

// Logout revokes the refresh token used to log in (and, since each
// login currently creates its own device row — see the TODO in
// Login — also revokes that device). Deliberately idempotent: calling
// logout with an already-invalid or already-revoked token still
// returns success, since the end state the caller wants ("this token
// can't be used anymore") is already true either way.
func (s *Service) Logout(ctx context.Context, rawToken string) error {
	hash := hashRefreshToken(rawToken)

	var record models.RefreshToken
	if err := s.db.WithContext(ctx).Where("token_hash = ?", hash).First(&record).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil // already not usable — logout's goal is already achieved
		}
		return fmt.Errorf("failed to look up refresh token: %w", err)
	}

	if record.RevokedAt != nil {
		return nil // already revoked, nothing to do
	}

	now := time.Now().UTC()
	if err := s.db.WithContext(ctx).Model(&record).Update("revoked_at", now).Error; err != nil {
		return fmt.Errorf("failed to revoke refresh token: %w", err)
	}

	// See the TODO in Login: today each session is its own device row,
	// so revoking the device too keeps them consistent. Once devices
	// are reused across logins (Week 3+), this line needs to change to
	// NOT blanket-revoke a device just because one of its sessions logged out.
	if err := s.db.WithContext(ctx).Model(&models.Device{}).
		Where("id = ?", record.DeviceID).
		Update("status", "revoked").Error; err != nil {
		return fmt.Errorf("failed to revoke device: %w", err)
	}

	return nil
}

// Refresh exchanges a valid, unexpired, unrevoked refresh token for a
// brand new access token AND a brand new refresh token (rotation) —
// the old refresh token is marked revoked in the same operation, so
// it can never be used again. This means if a refresh token is ever
// replayed after rotation, that's a detectable signal of theft (the
// legitimate holder would have received the newer token instead).
func (s *Service) Refresh(ctx context.Context, rawToken string) (*LoginResult, error) {
	hash := hashRefreshToken(rawToken)

	var record models.RefreshToken
	if err := s.db.WithContext(ctx).Where("token_hash = ?", hash).First(&record).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrRefreshTokenInvalid
		}
		return nil, fmt.Errorf("failed to look up refresh token: %w", err)
	}

	if record.RevokedAt != nil {
		// Treated identically to "not found" from the client's
		// perspective — we don't want to confirm a revoked token was
		// ever valid to whoever is holding it now.
		return nil, ErrRefreshTokenInvalid
	}
	if time.Now().After(record.ExpiresAt) {
		return nil, ErrRefreshTokenExpired
	}

	var user models.User
	if err := s.db.WithContext(ctx).Where("id = ?", record.UserID).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to look up user: %w", err)
	}

	accessToken, expiresAt, err := generateAccessToken(s.jwtSecret, user.ID, record.DeviceID)
	if err != nil {
		return nil, err
	}

	rawRefresh, refreshHash, err := generateRefreshToken()
	if err != nil {
		return nil, err
	}

	// Rotate: revoke the old refresh token and insert a new one, in
	// that order, so a crash between the two leaves the old token
	// revoked (fails closed) rather than both being valid (fails open).
	now := time.Now().UTC()
	if err := s.db.WithContext(ctx).Model(&record).Update("revoked_at", now).Error; err != nil {
		return nil, fmt.Errorf("failed to revoke old refresh token: %w", err)
	}

	newRecord := models.RefreshToken{
		UserID:    user.ID,
		DeviceID:  record.DeviceID,
		TokenHash: refreshHash,
		ExpiresAt: now.Add(refreshTokenTTL),
	}
	if err := s.db.WithContext(ctx).Create(&newRecord).Error; err != nil {
		return nil, fmt.Errorf("failed to store new refresh token: %w", err)
	}

	// Best-effort device activity update — not critical enough to fail
	// the whole refresh if it errors.
	s.db.WithContext(ctx).Model(&models.Device{}).
		Where("id = ?", record.DeviceID).
		Update("last_active_at", now)

	return &LoginResult{
		AccessToken:  accessToken,
		RefreshToken: rawRefresh,
		ExpiresAt:    expiresAt,
		User:         &user,
	}, nil
}
