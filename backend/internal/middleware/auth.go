// Package middleware holds Gin middleware shared across protected
// routes. Starting with authentication (Week 3 Day 1); rate limiting
// and request logging are natural future additions to this package.
package middleware

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"whatsapp-clone-backend/internal/auth"
	"whatsapp-clone-backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

// Context keys used to pass the authenticated user/device down to
// handlers. Exported as constants (not magic strings) so every
// handler that needs them reads the exact same key.
const (
	ContextUserIDKey   = "user_id"
	ContextDeviceIDKey = "device_id"
)

// DeviceChecker is the one thing RequireAuth needs beyond the JWT
// itself: whether the session's device is still active. Defined as an
// interface (not a concrete *gorm.DB dependency) so tests can supply
// a fake implementation instead of needing a real database — see
// auth_test.go.
type DeviceChecker interface {
	IsDeviceActive(ctx context.Context, deviceID string) (bool, error)
}

// GormDeviceChecker is the real, production DeviceChecker, backed by
// the devices table.
type GormDeviceChecker struct {
	db *gorm.DB
}

// NewGormDeviceChecker builds a GormDeviceChecker.
func NewGormDeviceChecker(db *gorm.DB) *GormDeviceChecker {
	return &GormDeviceChecker{db: db}
}

// IsDeviceActive reports whether the given device exists and has
// status 'active'. A device that doesn't exist at all is treated the
// same as "not active" rather than as an error — either way, the
// token can't be trusted.
func (c *GormDeviceChecker) IsDeviceActive(ctx context.Context, deviceID string) (bool, error) {
	var device models.Device
	err := c.db.WithContext(ctx).Select("status").Where("id = ?", deviceID).First(&device).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return false, nil
		}
		return false, err
	}
	return device.Status == "active", nil
}

// RequireAuth returns Gin middleware that validates the Authorization
// header on a route. Expects the exact form "Bearer <jwt>". On
// success, stores the token's user_id/device_id in the Gin context
// for downstream handlers (via c.GetString(ContextUserIDKey) etc.);
// on failure, aborts the request with 401 and a machine-readable
// `code` field so the client can distinguish "no token sent" from
// "token expired" from "token invalid" (standardized further on Week
// 3 Day 3).
//
// Refined (Week 3 Day 4 — "session validation logic"): a
// cryptographically valid, unexpired JWT is no longer sufficient on
// its own. Access tokens live for 15 minutes, but logout (Week 2 Day
// 5) revokes the underlying device immediately — without this check,
// a token issued just before logout would keep working for up to 15
// more minutes. Every authenticated request now also confirms the
// token's device is still active, closing that gap.
func RequireAuth(jwtSecret string, checker DeviceChecker) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "missing Authorization header",
				"code":  "AUTH_HEADER_MISSING",
			})
			return
		}

		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header must be in the form: Bearer <token>",
				"code":  "AUTH_HEADER_MALFORMED",
			})
			return
		}

		claims, err := auth.ParseAccessToken(jwtSecret, parts[1])
		if err != nil {
			code := "TOKEN_INVALID"
			if errors.Is(err, jwt.ErrTokenExpired) {
				code = "TOKEN_EXPIRED"
			}
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "invalid or expired access token",
				"code":  code,
			})
			return
		}

		active, err := checker.IsDeviceActive(c.Request.Context(), claims.DeviceID)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
				"error": "internal server error",
				"code":  "INTERNAL_ERROR",
			})
			return
		}
		if !active {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "this session has been revoked — please log in again",
				"code":  "SESSION_REVOKED",
			})
			return
		}

		c.Set(ContextUserIDKey, claims.UserID)
		c.Set(ContextDeviceIDKey, claims.DeviceID)
		c.Next()
	}
}
