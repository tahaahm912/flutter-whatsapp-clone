package models

import "time"

// User mirrors the `users` table exactly as defined in
// /migrations/000001_create_users_table.up.sql (which itself matches
// the project's finalized database schema). This struct is for
// reading/writing rows only — the table structure itself is owned by
// the migration files, never by this struct or by AutoMigrate.
type User struct {
	ID                string     `gorm:"column:id;primaryKey"`
	PhoneNumber       *string    `gorm:"column:phone_number"`
	Email             *string    `gorm:"column:email"`
	PasswordHash      string     `gorm:"column:password_hash"`
	Name              string     `gorm:"column:name"`
	ProfilePhotoURL   *string    `gorm:"column:profile_photo_url"`
	AboutText         *string    `gorm:"column:about_text"`
	AccountStatus     string     `gorm:"column:account_status"`
	LastSeenAt        *time.Time `gorm:"column:last_seen_at"`
	CreatedAt         time.Time  `gorm:"column:created_at"`
	UpdatedAt         time.Time  `gorm:"column:updated_at"`
}

// TableName pins the GORM model to the exact table name, so GORM never
// guesses a pluralized/snake_cased name that might drift from the
// migration.
func (User) TableName() string {
	return "users"
}
