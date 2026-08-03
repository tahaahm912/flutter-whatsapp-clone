// Package config centralizes every secret and connection string the
// app needs, loaded from a .env file (for local dev) or from real
// environment variables (for staging/production, where you'd never
// want a .env file sitting on disk). This replaces the hardcoded
// fallback DSN that lived directly inside internal/db from Day 3.
package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

// Config holds every externally-configurable value the app needs.
// Add new fields here as new services are introduced (e.g. FCM
// credentials in Week 7).
type Config struct {
	Port          string
	DatabaseURL   string
	RedisAddr     string
	RedisPassword string
	RedisDB       int
	JWTSecret     string
}

// Load reads a .env file if present (local dev convenience), then
// builds a Config from real environment variables, falling back to
// sensible local-development defaults for anything unset.
func Load() *Config {
	if err := godotenv.Load(); err != nil {
		log.Println("no .env file found — relying on real environment variables (expected in production)")
	}

	if os.Getenv("JWT_SECRET") == "" {
		log.Println("WARNING: JWT_SECRET not set — using an insecure development-only default. NEVER deploy with this default; generate a long random value for production.")
	}

	return &Config{
		Port:          getEnv("PORT", "8080"),
		DatabaseURL:   getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/whatsapp_clone?sslmode=disable"),
		RedisAddr:     getEnv("REDIS_ADDR", "localhost:6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisDB:       getEnvInt("REDIS_DB", 0),
		JWTSecret:     getEnv("JWT_SECRET", "insecure-dev-secret-change-me-in-production"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(v)
	if err != nil {
		log.Printf("invalid int for %s (%q), using fallback %d", key, v, fallback)
		return fallback
	}
	return parsed
}
