package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// SignalOneTimePrekey mirrors the `signal_one_time_prekeys` table from
// /migrations/000004_create_signal_keys.up.sql. Dozens of rows exist
// per device (consumed one at a time as other users start
// conversations with it), each with its own generated `id`.
type SignalOneTimePrekey struct {
	ID        uuid.UUID  `gorm:"column:id;primaryKey;type:uuid"`
	DeviceID  uuid.UUID  `gorm:"column:device_id;type:uuid"`
	KeyID     int        `gorm:"column:key_id"`
	PublicKey string     `gorm:"column:public_key"`
	IsUsed    bool       `gorm:"column:is_used"`
	CreatedAt time.Time  `gorm:"column:created_at"`
	UsedAt    *time.Time `gorm:"column:used_at"`
}

func (SignalOneTimePrekey) TableName() string {
	return "signal_one_time_prekeys"
}

// BeforeCreate — see the identical hook on User for why this is done
// explicitly rather than relying on GORM's default-detection.
func (k *SignalOneTimePrekey) BeforeCreate(tx *gorm.DB) error {
	if k.ID == uuid.Nil {
		k.ID = uuid.New()
	}
	return nil
}
