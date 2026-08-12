package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// SignalSignedPrekey mirrors the `signal_signed_prekeys` table from
// /migrations/000004_create_signal_keys.up.sql. Unlike
// SignalIdentityKey, this has its own generated `id` (many rows exist
// per device over time, as the signed prekey rotates) — so it DOES
// need the same BeforeCreate pattern as User/Device/RefreshToken.
type SignalSignedPrekey struct {
	ID        uuid.UUID `gorm:"column:id;primaryKey;type:uuid"`
	DeviceID  uuid.UUID `gorm:"column:device_id;type:uuid"`
	KeyID     int       `gorm:"column:key_id"`
	PublicKey string    `gorm:"column:public_key"`
	Signature string    `gorm:"column:signature"`
	IsActive  bool      `gorm:"column:is_active"`
	CreatedAt time.Time `gorm:"column:created_at"`
}

func (SignalSignedPrekey) TableName() string {
	return "signal_signed_prekeys"
}

// BeforeCreate — see the identical hook on User for why this is done
// explicitly rather than relying on GORM's default-detection.
func (k *SignalSignedPrekey) BeforeCreate(tx *gorm.DB) error {
	if k.ID == uuid.Nil {
		k.ID = uuid.New()
	}
	return nil
}
