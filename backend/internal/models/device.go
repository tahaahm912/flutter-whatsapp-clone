package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Device mirrors the `devices` table from
// /migrations/000003_create_devices_and_refresh_tokens.up.sql.
type Device struct {
	ID                 uuid.UUID  `gorm:"column:id;primaryKey;type:uuid"`
	UserID             uuid.UUID  `gorm:"column:user_id;type:uuid"`
	DeviceName         *string    `gorm:"column:device_name"`
	Platform           string     `gorm:"column:platform"`
	PushToken          *string    `gorm:"column:push_token"`
	PushTokenUpdatedAt *time.Time `gorm:"column:push_token_updated_at"`
	Status             string     `gorm:"column:status"`
	LastActiveAt       *time.Time `gorm:"column:last_active_at"`
	CreatedAt          time.Time  `gorm:"column:created_at"`
}

func (Device) TableName() string {
	return "devices"
}

// BeforeCreate — see the identical hook on User for why this is done
// explicitly rather than relying on GORM's default-detection.
func (d *Device) BeforeCreate(tx *gorm.DB) error {
	if d.ID == uuid.Nil {
		d.ID = uuid.New()
	}
	return nil
}
