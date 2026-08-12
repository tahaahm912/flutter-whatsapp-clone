package conversations

import (
	"errors"
	"net/http"
	"time"

	"whatsapp-clone-backend/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Handler translates HTTP requests into Service calls, same pattern
// as auth/users/keys.
type Handler struct {
	service *Service
}

// NewHandler builds a conversations Handler.
func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// Create handles POST /conversations.
func (h *Handler) Create(c *gin.Context) {
	var req CreateConversationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request",
			"code":    "VALIDATION_ERROR",
			"details": err.Error(),
		})
		return
	}

	callerIDStr := c.GetString(middleware.ContextUserIDKey)
	callerID, err := uuid.Parse(callerIDStr)
	if err != nil {
		// Should never happen for a token this API itself issued.
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		return
	}

	result, err := h.service.CreateDirectConversation(c.Request.Context(), callerID, req.ParticipantID)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidParticipant):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "INVALID_PARTICIPANT"})
		case errors.Is(err, ErrCannotMessageSelf):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "CANNOT_MESSAGE_SELF"})
		case errors.Is(err, ErrParticipantNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "PARTICIPANT_NOT_FOUND"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	// 201 for a genuinely new conversation, 200 if an existing one
	// between these same two people was found and returned instead —
	// lets the client distinguish "just started this chat" from
	// "already had this chat" without parsing anything else.
	status := http.StatusCreated
	if !result.WasCreated {
		status = http.StatusOK
	}

	c.JSON(status, ConversationResponse{
		ID:        result.Conversation.ID.String(),
		Type:      result.Conversation.Type,
		CreatedAt: result.Conversation.CreatedAt.Format(time.RFC3339),
	})
}

// List handles GET /conversations.
func (h *Handler) List(c *gin.Context) {
	callerIDStr := c.GetString(middleware.ContextUserIDKey)
	callerID, err := uuid.Parse(callerIDStr)
	if err != nil {
		// Should never happen for a token this API itself issued.
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		return
	}

	items, err := h.service.ListConversations(c.Request.Context(), callerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		return
	}

	c.JSON(http.StatusOK, ListConversationsResponse{Conversations: items})
}
