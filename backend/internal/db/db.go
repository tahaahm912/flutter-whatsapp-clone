// Package db owns the single PostgreSQL connection used by the whole
// application. Note: this package only ever *reads/writes* through
// GORM — it never calls AutoMigrate. The schema is owned exclusively
// by the SQL files in /migrations, applied with golang-migrate. This
// keeps the database schema as a single source of truth instead of
// having GORM silently guess/alter table structure.
package db

import (
	"fmt"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Connect opens a PostgreSQL connection using the given DSN. As of
// Day 4, the DSN itself comes from internal/config (which reads
// DATABASE_URL from .env/the real environment) rather than being read
// directly here — this package no longer knows or cares where the
// DSN came from.
func Connect(dsn string) (*gorm.DB, error) {
	gormDB, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	sqlDB, err := gormDB.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to get underlying sql.DB: %w", err)
	}

	if err := sqlDB.Ping(); err != nil {
		return nil, fmt.Errorf("database did not respond to ping: %w", err)
	}

	// Reasonable defaults for a small-to-medium deployment; revisit
	// under real load testing in Week 8.
	sqlDB.SetMaxOpenConns(25)
	sqlDB.SetMaxIdleConns(10)

	return gormDB, nil
}
