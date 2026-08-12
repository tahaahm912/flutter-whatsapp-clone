package keys

import (
	"errors"
	"net/http"

	"whatsapp-clone-backend/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Handler translates HTTP requests into Service calls, same pattern
// as internal/auth and internal/users.
type Handler struct {
	service *Service
}

// NewHandler builds a keys Handler.
func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// UploadKeys handles POST /users/keys. The device these keys belong
// to is always the one making the request (from the JWT's device_id
// claim) — never a device ID supplied in the request body, which
// would let one device upload keys on behalf of another.
func (h *Handler) UploadKeys(c *gin.Context) {
	var req UploadKeysRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request",
			"code":    "VALIDATION_ERROR",
			"details": err.Error(),
		})
		return
	}

	// Beyond Gin's binding tags (non-empty, non-negative): confirms the
	// actual key material decodes to a plausible Curve25519 key/
	// signature length. See validation.go.
	if err := req.Validate(); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid key material",
			"code":    "INVALID_KEY_FORMAT",
			"details": err.Error(),
		})
		return
	}

	deviceIDStr := c.GetString(middleware.ContextDeviceIDKey)
	deviceID, err := uuid.Parse(deviceIDStr)
	if err != nil {
		// Should never happen for a token this API itself issued — the
		// device_id claim always comes from a real device.ID.String().
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		return
	}

	result, err := h.service.UploadKeys(c.Request.Context(), deviceID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		return
	}

	c.JSON(http.StatusOK, UploadKeysResponse{
		IdentityKeyStored:    result.IdentityKeyStored,
		SignedPrekeyStored:   result.SignedPrekeyStored,
		OneTimePrekeysStored: result.OneTimePrekeysStored,
	})
}

// GetUserKeys handles GET /users/:userId/keys. Note this is
// reachable for ANY user ID, not just the caller's own — that's the
// entire point (Alice needs Bob's public keys to start an encrypted
// chat with him). Being authenticated (logged in) is required;
// knowing Bob's user ID is not treated as a secret.
func (h *Handler) GetUserKeys(c *gin.Context) {
	userID := c.Param("userId")

	bundle, err := h.service.GetUserKeyBundle(c.Request.Context(), userID)
	if err != nil {
		switch {
		case errors.Is(err, ErrUserNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "USER_NOT_FOUND"})
		case errors.Is(err, ErrNoKeysAvailable):
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "NO_KEYS_AVAILABLE"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	c.JSON(http.StatusOK, bundle)
}
