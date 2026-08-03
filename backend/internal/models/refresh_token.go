package models

import "time"

// RefreshToken mirrors the `refresh_tokens` table from
// /migrations/000003_create_devices_and_refresh_tokens.up.sql.
// Note: TokenHash stores a SHA-256 hash of the refresh token, never
// the raw token itself — see internal/auth/tokens.go.
type RefreshToken struct {
	ID        string     `gorm:"column:id;primaryKey"`
	UserID    string     `gorm:"column:user_id"`
	DeviceID  string     `gorm:"column:device_id"`
	TokenHash string     `gorm:"column:token_hash"`
	IssuedAt  time.Time  `gorm:"column:issued_at"`
	ExpiresAt time.Time  `gorm:"column:expires_at"`
	RevokedAt *time.Time `gorm:"column:revoked_at"`
}

func (RefreshToken) TableName() string {
	return "refresh_tokens"
}
