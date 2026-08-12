package users

import (
	"errors"
	"net/http"
	"time"

	"whatsapp-clone-backend/internal/middleware"

	"github.com/gin-gonic/gin"
)

// Handler translates HTTP requests into Service calls, same pattern
// as internal/auth's Handler.
type Handler struct {
	service *Service
}

// NewHandler builds a users Handler.
func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// Me handles GET /users/me. Sits behind middleware.RequireAuth (see
// server.go), which is what populates ContextUserIDKey — this handler
// never trusts a user ID from anywhere else (a query param, a request
// body, etc.), only from the verified JWT.
func (h *Handler) Me(c *gin.Context) {
	userID := c.GetString(middleware.ContextUserIDKey)

	user, err := h.service.GetByID(c.Request.Context(), userID)
	if err != nil {
		switch {
		case errors.Is(err, ErrUserNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "USER_NOT_FOUND"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	c.JSON(http.StatusOK, MeResponse{
		ID:              user.ID.String(),
		Name:            user.Name,
		PhoneNumber:     user.PhoneNumber,
		Email:           user.Email,
		About:           user.AboutText,
		ProfilePhotoURL: user.ProfilePhotoURL,
		CreatedAt:       user.CreatedAt.Format(time.RFC3339),
	})
}

// Search handles GET /users/search?phone=... or ?email=....
func (h *Handler) Search(c *gin.Context) {
	var req SearchUserRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request",
			"code":    "VALIDATION_ERROR",
			"details": err.Error(),
		})
		return
	}

	user, err := h.service.Search(c.Request.Context(), req.Phone, req.Email)
	if err != nil {
		switch {
		case errors.Is(err, ErrSearchParamRequired):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "SEARCH_PARAM_REQUIRED"})
		case errors.Is(err, ErrUserNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": "no matching user found", "code": "USER_NOT_FOUND"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	c.JSON(http.StatusOK, SearchUserResponse{
		ID:              user.ID.String(),
		Name:            user.Name,
		About:           user.AboutText,
		ProfilePhotoURL: user.ProfilePhotoURL,
	})
}
