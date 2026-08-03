package models

import "time"

// Device mirrors the `devices` table from
// /migrations/000003_create_devices_and_refresh_tokens.up.sql.
type Device struct {
	ID                  string     `gorm:"column:id;primaryKey"`
	UserID              string     `gorm:"column:user_id"`
	DeviceName          *string    `gorm:"column:device_name"`
	Platform            string     `gorm:"column:platform"`
	PushToken           *string    `gorm:"column:push_token"`
	PushTokenUpdatedAt  *time.Time `gorm:"column:push_token_updated_at"`
	Status              string     `gorm:"column:status"`
	LastActiveAt        *time.Time `gorm:"column:last_active_at"`
	CreatedAt           time.Time  `gorm:"column:created_at"`
}

func (Device) TableName() string {
	return "devices"
}
