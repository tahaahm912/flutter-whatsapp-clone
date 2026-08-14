package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// MessageRecipient mirrors the `message_recipients` table from
// /migrations/000006_create_messages.up.sql — one row per (message,
// recipient device). Ciphertext holds real Signal Protocol ciphertext
// from Week 6 onward; during Week 5's plaintext-first phase, plain
// text is written here instead. The column and this struct don't
// change either way — only what the application writes into it does.
type MessageRecipient struct {
	ID                uuid.UUID  `gorm:"column:id;primaryKey;type:uuid"`
	MessageID         uuid.UUID  `gorm:"column:message_id;type:uuid"`
	RecipientUserID   uuid.UUID  `gorm:"column:recipient_user_id;type:uuid"`
	RecipientDeviceID uuid.UUID  `gorm:"column:recipient_device_id;type:uuid"`
	Ciphertext        string     `gorm:"column:ciphertext"`
	Status            string     `gorm:"column:status"`
	DeliveredAt       *time.Time `gorm:"column:delivered_at"`
	ReadAt            *time.Time `gorm:"column:read_at"`
}

func (MessageRecipient) TableName() string {
	return "message_recipients"
}

// BeforeCreate — see the identical hook on User for why this is done
// explicitly rather than relying on GORM's default-detection.
func (r *MessageRecipient) BeforeCreate(tx *gorm.DB) error {
	if r.ID == uuid.Nil {
		r.ID = uuid.New()
	}
	return nil
}
