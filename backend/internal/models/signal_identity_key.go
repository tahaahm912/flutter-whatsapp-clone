package models

import (
	"time"

	"github.com/google/uuid"
)

// SignalIdentityKey mirrors the `signal_identity_keys` table from
// /migrations/000004_create_signal_keys.up.sql.
//
// Unlike every other model so far, DeviceID here IS the primary key —
// there's no separate generated `id` column, by schema design (one
// identity key per device, period). This means it deliberately has NO
// BeforeCreate hook: DeviceID must be explicitly assigned by the
// caller (the authenticated device's ID from the JWT), never
// auto-generated. Adding a "generate if zero" hook here would be a
// real bug — it would silently assign a random UUID instead of the
// actual device's ID.
type SignalIdentityKey struct {
	DeviceID          uuid.UUID `gorm:"column:device_id;primaryKey;type:uuid"`
	IdentityPublicKey string    `gorm:"column:identity_public_key"`
	RegistrationID    int       `gorm:"column:registration_id"`
	CreatedAt         time.Time `gorm:"column:created_at"`
}

func (SignalIdentityKey) TableName() string {
	return "signal_identity_keys"
}
