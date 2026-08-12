package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ConversationParticipant mirrors the `conversation_participants`
// table from /migrations/000005_create_conversations.up.sql — the
// many-to-many join between users and conversations.
type ConversationParticipant struct {
	ID             uuid.UUID  `gorm:"column:id;primaryKey;type:uuid"`
	ConversationID uuid.UUID  `gorm:"column:conversation_id;type:uuid"`
	UserID         uuid.UUID  `gorm:"column:user_id;type:uuid"`
	Role           string     `gorm:"column:role"`
	JoinedAt       time.Time  `gorm:"column:joined_at"`
	LeftAt         *time.Time `gorm:"column:left_at"`
	IsActive       bool       `gorm:"column:is_active"`
}

func (ConversationParticipant) TableName() string {
	return "conversation_participants"
}

// BeforeCreate — see the identical hook on User for why this is done
// explicitly rather than relying on GORM's default-detection.
func (p *ConversationParticipant) BeforeCreate(tx *gorm.DB) error {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return nil
}
