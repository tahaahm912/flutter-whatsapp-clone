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
