package messages

import (
	"errors"
	"net/http"
	"time"

	"whatsapp-clone-backend/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Handler translates HTTP requests into Service calls, same pattern
// as auth/users/keys/conversations.
type Handler struct {
	service *Service
}

// NewHandler builds a messages Handler.
func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// Send handles POST /messages.
func (h *Handler) Send(c *gin.Context) {
	var req SendMessageRequest
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
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		return
	}

	callerDeviceIDStr := c.GetString(middleware.ContextDeviceIDKey)
	callerDeviceID, err := uuid.Parse(callerDeviceIDStr)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		return
	}

	result, err := h.service.SendMessage(c.Request.Context(), callerID, callerDeviceID, req)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidConversationID):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "INVALID_CONVERSATION_ID"})
		case errors.Is(err, ErrInvalidClientMessageID):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "INVALID_CLIENT_MESSAGE_ID"})
		case errors.Is(err, ErrNotAParticipant):
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error(), "code": "NOT_A_PARTICIPANT"})
		case errors.Is(err, ErrClientMessageIDReused):
			c.JSON(http.StatusConflict, gin.H{"error": err.Error(), "code": "CLIENT_MESSAGE_ID_REUSED"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	status := http.StatusCreated
	if !result.WasCreated {
		status = http.StatusOK
	}

	c.JSON(status, MessageResponse{
		ID:              result.Message.ID.String(),
		ConversationID:  result.Message.ConversationID.String(),
		SenderID:        result.Message.SenderID.String(),
		ClientMessageID: result.Message.ClientMessageID.String(),
		MessageType:     result.Message.MessageType,
		Body:            result.Body,
		CreatedAt:       result.Message.CreatedAt.Format(time.RFC3339),
	})
}

// List handles GET /messages/:conversationId.
func (h *Handler) List(c *gin.Context) {
	conversationID := c.Param("conversationId")

	var query ListMessagesQuery
	if err := c.ShouldBindQuery(&query); err != nil {
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
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		return
	}

	callerDeviceIDStr := c.GetString(middleware.ContextDeviceIDKey)
	callerDeviceID, err := uuid.Parse(callerDeviceIDStr)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		return
	}

	items, err := h.service.ListMessages(c.Request.Context(), callerID, callerDeviceID, conversationID, query.Limit, query.BeforeMessageID)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidConversationID):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "INVALID_CONVERSATION_ID"})
		case errors.Is(err, ErrNotAParticipant):
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error(), "code": "NOT_A_PARTICIPANT"})
		case errors.Is(err, ErrInvalidBeforeMessageID):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "INVALID_BEFORE_MESSAGE_ID"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	c.JSON(http.StatusOK, ListMessagesResponse{Messages: items})
}
