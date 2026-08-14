package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Message mirrors the `messages` table from
// /migrations/000006_create_messages.up.sql. Note: no content/body
// column here — the actual message content lives in
// MessageRecipient.Ciphertext, one row per recipient device. This
// table only ever holds metadata about the send itself.
type Message struct {
	ID              uuid.UUID  `gorm:"column:id;primaryKey;type:uuid"`
	ConversationID  uuid.UUID  `gorm:"column:conversation_id;type:uuid"`
	SenderID        uuid.UUID  `gorm:"column:sender_id;type:uuid"`
	SenderDeviceID  uuid.UUID  `gorm:"column:sender_device_id;type:uuid"`
	ClientMessageID uuid.UUID  `gorm:"column:client_message_id;type:uuid"`
	MessageType     string     `gorm:"column:message_type"`
	CreatedAt       time.Time  `gorm:"column:created_at"`
	DeletedAt       *time.Time `gorm:"column:deleted_at"`
}

func (Message) TableName() string {
	return "messages"
}

// BeforeCreate — see the identical hook on User for why this is done
// explicitly rather than relying on GORM's default-detection.
func (m *Message) BeforeCreate(tx *gorm.DB) error {
	if m.ID == uuid.Nil {
		m.ID = uuid.New()
	}
	return nil
}
