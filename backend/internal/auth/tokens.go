package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const (
	// accessTokenTTL is short by design — if one leaks, the exposure
	// window is small. Long-lived sessions are handled by the refresh
	// token instead (Week 2 Day 4).
	accessTokenTTL = 15 * time.Minute

	// refreshTokenTTL is long-lived but revocable (see the
	// `revoked_at` column) and rotated on use, per the security plan.
	refreshTokenTTL = 30 * 24 * time.Hour
)

// Claims is the JWT payload for access tokens. DeviceID is included
// so that, from Week 3 onward, the auth middleware and any endpoint
// can know exactly which device/session made a request — this is
// what "logout this device only" and multi-device (V7) rely on later.
type Claims struct {
	UserID   string `json:"sub"`
	DeviceID string `json:"device_id"`
	jwt.RegisteredClaims
}

// generateAccessToken signs a short-lived JWT for the given user/device.
func generateAccessToken(secret, userID, deviceID string) (token string, expiresAt time.Time, err error) {
	expiresAt = time.Now().Add(accessTokenTTL)
	claims := Claims{
		UserID:   userID,
		DeviceID: deviceID,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
		},
	}

	signed, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(secret))
	if err != nil {
		return "", time.Time{}, fmt.Errorf("failed to sign access token: %w", err)
	}
	return signed, expiresAt, nil
}

// ParseAccessToken validates a token string and returns its claims.
// Exported because the JWT middleware being built in Week 3 Day 1
// needs this exact function.
func ParseAccessToken(secret, tokenString string) (*Claims, error) {
	claims := &Claims{}

	token, err := jwt.ParseWithClaims(tokenString, claims, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return []byte(secret), nil
	})
	if err != nil {
		return nil, err
	}
	if !token.Valid {
		return nil, fmt.Errorf("token is not valid")
	}
	return claims, nil
}

// generateRefreshToken returns a cryptographically random opaque
// token (the "raw" value, given to the client exactly once) and a
// SHA-256 hash of it (what actually gets stored in the database).
// This means a database leak alone can never be used to forge a
// session — matching the "weak session tokens" loophole from the
// original security plan.
func generateRefreshToken() (raw string, hash string, err error) {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "", "", fmt.Errorf("failed to generate refresh token: %w", err)
	}

	raw = base64.RawURLEncoding.EncodeToString(buf)
	return raw, hashRefreshToken(raw), nil
}

// hashRefreshToken hashes a raw refresh token for storage/lookup.
// Extracted as its own function (Week 2 Day 4) since POST
// /auth/refresh needs to hash an incoming token the same way, not
// just generate new ones.
func hashRefreshToken(raw string) string {
	sum := sha256.Sum256([]byte(raw))
	return hex.EncodeToString(sum[:])
}
