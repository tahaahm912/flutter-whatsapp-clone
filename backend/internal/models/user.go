package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User mirrors the `users` table as defined across
// /migrations/000001_create_users_table.up.sql and
// /migrations/000002_add_otp_verification_fields.up.sql. This struct
// is for reading/writing rows only — the table structure itself is
// owned by the migration files, never by this struct or by
// AutoMigrate.
//
// ID is uuid.UUID, not string (fixed after a real registration bug —
// see BeforeCreate below for why).
type User struct {
	ID              uuid.UUID  `gorm:"column:id;primaryKey;type:uuid"`
	PhoneNumber     *string    `gorm:"column:phone_number"`
	Email           *string    `gorm:"column:email"`
	PasswordHash    string     `gorm:"column:password_hash"`
	Name            string     `gorm:"column:name"`
	ProfilePhotoURL *string    `gorm:"column:profile_photo_url"`
	AboutText       *string    `gorm:"column:about_text"`
	AccountStatus   string     `gorm:"column:account_status"`
	PhoneVerifiedAt *time.Time `gorm:"column:phone_verified_at"`
	EmailVerifiedAt *time.Time `gorm:"column:email_verified_at"`
	LastSeenAt      *time.Time `gorm:"column:last_seen_at"`
	CreatedAt       time.Time  `gorm:"column:created_at"`
	UpdatedAt       time.Time  `gorm:"column:updated_at"`
}

// TableName pins the GORM model to the exact table name, so GORM never
// guesses a pluralized/snake_cased name that might drift from the
// migration.
func (User) TableName() string {
	return "users"
}

// BeforeCreate explicitly generates a UUID before every insert,
// rather than leaving the field blank and relying on GORM knowing
// about the database's DEFAULT gen_random_uuid() (it doesn't — that
// default lives in the raw SQL migration, which GORM has no
// visibility into, since AutoMigrate is never used in this project).
// This was the root cause of a real bug: a blank string ID was
// literally sent as `id = ''`, which Postgres correctly rejected as
// invalid UUID syntax. Generating it here removes any dependency on
// GORM's default-detection behavior entirely.
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}
