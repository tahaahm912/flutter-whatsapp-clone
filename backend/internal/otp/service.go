// Package otp implements one-time-code generation and verification,
// backed entirely by Redis. Codes are short-lived by nature (a few
// minutes), so Redis's native TTL support is a better fit than a
// PostgreSQL table — no cleanup job needed, expiry is automatic.
package otp

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"math/big"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	codeLength      = 6
	ttl             = 5 * time.Minute
	maxAttempts     = 5
	resendCooldown  = 60 * time.Second
)

// Sentinel errors the auth handler maps to specific HTTP status codes.
var (
	ErrTooManyAttempts = errors.New("too many incorrect attempts — request a new code")
	ErrInvalidCode     = errors.New("incorrect code")
	ErrExpired         = errors.New("code has expired or was never requested")
	ErrTooSoon         = errors.New("please wait before requesting another code")
)

// Service generates and verifies OTP codes.
type Service struct {
	redis *redis.Client
}

// NewService builds an OTP Service.
func NewService(redisClient *redis.Client) *Service {
	return &Service{redis: redisClient}
}

func codeKey(identifier string) string {
	return fmt.Sprintf("otp:code:%s", identifier)
}

func attemptsKey(identifier string) string {
	return fmt.Sprintf("otp:attempts:%s", identifier)
}

func cooldownKey(identifier string) string {
	return fmt.Sprintf("otp:cooldown:%s", identifier)
}

// Generate creates a fresh 6-digit numeric code, stores a hash of it
// in Redis with a TTL, resets the attempt counter for this
// identifier, and returns the raw code to the caller so it can be
// "sent". There's no SMS/email provider wired up yet (that's outside
// V1's free-to-build scope) — callers should log the code for manual
// testing until a provider is added.
//
// A short cooldown (60s) is enforced per identifier via Redis SETNX,
// so this same method safely powers both the initial send (at
// registration) and "resend code" (added for the OTP screen's resend
// button) — the very first call always succeeds since no cooldown key
// exists yet; only rapid repeats are rejected with ErrTooSoon.
func (s *Service) Generate(ctx context.Context, identifier string) (string, error) {
	acquired, err := s.redis.SetNX(ctx, cooldownKey(identifier), "1", resendCooldown).Result()
	if err != nil {
		return "", fmt.Errorf("failed to check resend cooldown: %w", err)
	}
	if !acquired {
		return "", ErrTooSoon
	}

	code, err := generateNumericCode(codeLength)
	if err != nil {
		return "", fmt.Errorf("failed to generate code: %w", err)
	}

	if err := s.redis.Set(ctx, codeKey(identifier), hashCode(code), ttl).Err(); err != nil {
		return "", fmt.Errorf("failed to store otp: %w", err)
	}
	// A fresh code means a fresh attempt budget.
	s.redis.Del(ctx, attemptsKey(identifier))

	return code, nil
}

// Verify checks a submitted code against the stored hash for the
// given identifier. It enforces a max-attempts limit (slows down
// brute force against the 6-digit space) and deletes the stored code
// immediately on success, so each code can only be used once.
//
// Refined (Week 3 Day 3) to distinguish two previously-merged cases:
// the Redis key being gone entirely (the 5-minute TTL genuinely
// passed, or no code was ever requested for this identifier) now
// returns ErrExpired, while the key existing but the hash not
// matching what was submitted returns ErrInvalidCode. Splitting these
// doesn't weaken brute-force protection — the max-attempts limit above
// applies identically either way — it just gives the client (and the
// person typing the code) a more accurate message.
func (s *Service) Verify(ctx context.Context, identifier, submittedCode string) error {
	attempts, err := s.redis.Incr(ctx, attemptsKey(identifier)).Result()
	if err != nil {
		return fmt.Errorf("failed to check attempt count: %w", err)
	}
	if attempts == 1 {
		// First attempt against this code — make the attempt counter
		// expire alongside the code itself instead of lingering forever.
		s.redis.Expire(ctx, attemptsKey(identifier), ttl)
	}
	if attempts > maxAttempts {
		return ErrTooManyAttempts
	}

	storedHash, err := s.redis.Get(ctx, codeKey(identifier)).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return ErrExpired
		}
		return fmt.Errorf("failed to fetch stored otp: %w", err)
	}

	if hashCode(submittedCode) != storedHash {
		return ErrInvalidCode
	}

	s.redis.Del(ctx, codeKey(identifier), attemptsKey(identifier))
	return nil
}

func generateNumericCode(length int) (string, error) {
	const digits = "0123456789"
	code := make([]byte, length)
	for i := range code {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(digits))))
		if err != nil {
			return "", err
		}
		code[i] = digits[n.Int64()]
	}
	return string(code), nil
}

// hashCode uses SHA-256 rather than bcrypt deliberately: bcrypt's cost
// factor defends against brute-forcing a *large* secret space, but a
// 6-digit code only has 1,000,000 possibilities regardless of hash
// function. The real protection here is the TTL and the max-attempts
// limit above, not the hash's computational cost — SHA-256 is enough
// to avoid storing the raw code in Redis.
func hashCode(code string) string {
	sum := sha256.Sum256([]byte(code))
	return hex.EncodeToString(sum[:])
}
