package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Conversation mirrors the `conversations` table from
// /migrations/000005_create_conversations.up.sql. Covers both direct
// (1:1) and group conversations via the Type column — group-only
// metadata lives in a separate group_details table (not migrated yet;
// added whenever group chat is actually built).
type Conversation struct {
	ID        uuid.UUID `gorm:"column:id;primaryKey;type:uuid"`
	Type      string    `gorm:"column:type"`
	CreatedBy uuid.UUID `gorm:"column:created_by;type:uuid"`
	CreatedAt time.Time `gorm:"column:created_at"`
}

func (Conversation) TableName() string {
	return "conversations"
}

// BeforeCreate — see the identical hook on User for why this is done
// explicitly rather than relying on GORM's default-detection.
func (c *Conversation) BeforeCreate(tx *gorm.DB) error {
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	return nil
}
