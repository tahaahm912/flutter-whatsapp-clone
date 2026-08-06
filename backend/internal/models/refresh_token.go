package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// RefreshToken mirrors the `refresh_tokens` table from
// /migrations/000003_create_devices_and_refresh_tokens.up.sql.
// Note: TokenHash stores a SHA-256 hash of the refresh token, never
// the raw token itself — see internal/auth/tokens.go.
type RefreshToken struct {
	ID        uuid.UUID  `gorm:"column:id;primaryKey;type:uuid"`
	UserID    uuid.UUID  `gorm:"column:user_id;type:uuid"`
	DeviceID  uuid.UUID  `gorm:"column:device_id;type:uuid"`
	TokenHash string     `gorm:"column:token_hash"`
	IssuedAt  time.Time  `gorm:"column:issued_at"`
	ExpiresAt time.Time  `gorm:"column:expires_at"`
	RevokedAt *time.Time `gorm:"column:revoked_at"`
}

func (RefreshToken) TableName() string {
	return "refresh_tokens"
}

// BeforeCreate — see the identical hook on User for why this is done
// explicitly rather than relying on GORM's default-detection.
func (r *RefreshToken) BeforeCreate(tx *gorm.DB) error {
	if r.ID == uuid.Nil {
		r.ID = uuid.New()
	}
	return nil
}
