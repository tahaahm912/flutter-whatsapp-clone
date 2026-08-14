// Package messages handles sending (and, from Day 4, retrieving)
// messages. Week 5 is deliberately plaintext-first per the build plan
// — see migration 000006's comment for exactly what that means and
// why it requires no schema change later.
package messages

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"
	"time"

	"whatsapp-clone-backend/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Sentinel errors the handler maps to specific HTTP status codes.
var (
	ErrInvalidConversationID  = errors.New("conversation_id is not a valid ID")
	ErrInvalidClientMessageID = errors.New("client_message_id is not a valid ID")
	ErrNotAParticipant        = errors.New("you are not a participant of this conversation")
	ErrClientMessageIDReused  = errors.New("this client_message_id was already used for a different conversation")
	ErrInvalidBeforeMessageID = errors.New("before_message_id does not refer to an existing message in this conversation")
)

// errDuplicateClientMessage is internal-only (never returned to the
// handler directly) — it signals "the unique index caught a retry,"
// which SendMessage resolves into either returning the existing
// message (legitimate retry) or ErrClientMessageIDReused (client bug).
var errDuplicateClientMessage = errors.New("duplicate client_message_id for this device")

// Service handles message creation.
type Service struct {
	db *gorm.DB
}

// NewService builds a messages Service.
func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

// SendResult reports whether a new message was actually created, or
// an existing one (from a legitimate retried send) was returned
// instead — same WasCreated pattern as conversations.CreateResult,
// for the same reason: the handler uses it to pick 201 vs 200.
type SendResult struct {
	Message    *models.Message
	Body       string
	WasCreated bool
}

// SendMessage validates the request, confirms the caller is an active
// participant of the conversation, then stores the message and fans
// it out to every OTHER active participant's active devices — never
// to the sender's own devices. The sender's client is expected to
// store its own sent message locally (see Member 1's Drift database,
// built this same day) rather than fetch it back from the server;
// this matches how real Signal-protocol clients behave, not just a
// shortcut.
func (s *Service) SendMessage(ctx context.Context, callerID, callerDeviceID uuid.UUID, req SendMessageRequest) (*SendResult, error) {
	conversationID, err := uuid.Parse(req.ConversationID)
	if err != nil {
		return nil, ErrInvalidConversationID
	}
	clientMessageID, err := uuid.Parse(req.ClientMessageID)
	if err != nil {
		return nil, ErrInvalidClientMessageID
	}

	isParticipant, err := s.isActiveParticipant(ctx, conversationID, callerID)
	if err != nil {
		return nil, fmt.Errorf("failed to verify participant: %w", err)
	}
	if !isParticipant {
		return nil, ErrNotAParticipant
	}

	var message models.Message
	txErr := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		message = models.Message{
			ConversationID:  conversationID,
			SenderID:        callerID,
			SenderDeviceID:  callerDeviceID,
			ClientMessageID: clientMessageID,
			MessageType:     "text",
		}
		if err := tx.Create(&message).Error; err != nil {
			if strings.Contains(err.Error(), "duplicate key value violates unique constraint") {
				// The unique index on (sender_device_id, client_message_id)
				// caught this. Stop immediately — do NOT attempt any
				// further statements in this transaction; Postgres has
				// already marked it aborted, and GORM's Transaction()
				// will roll it back once this closure returns an error.
				return errDuplicateClientMessage
			}
			return fmt.Errorf("failed to create message: %w", err)
		}

		recipientRows, err := buildRecipientRows(tx, conversationID, callerID, message.ID, req.Body)
		if err != nil {
			return err
		}
		if len(recipientRows) > 0 {
			if err := tx.Create(&recipientRows).Error; err != nil {
				return fmt.Errorf("failed to fan out message to recipients: %w", err)
			}
		}
		return nil
	})

	if txErr != nil {
		if errors.Is(txErr, errDuplicateClientMessage) {
			// The transaction was rolled back — use a fresh, non-
			// transactional handle (s.db, not tx) for this lookup.
			var existing models.Message
			if err := s.db.WithContext(ctx).
				Where("sender_device_id = ? AND client_message_id = ?", callerDeviceID, clientMessageID).
				First(&existing).Error; err != nil {
				return nil, fmt.Errorf("failed to load existing message after a dedup conflict: %w", err)
			}

			// Guard against a real edge case: the dedup index is scoped
			// to (sender_device_id, client_message_id) only, NOT to
			// conversation_id. A client that (incorrectly) reused the
			// same client_message_id across two different conversations
			// would otherwise silently get back a message from the
			// WRONG conversation here. Catch that explicitly rather than
			// returning a misleading result.
			if existing.ConversationID != conversationID {
				return nil, ErrClientMessageIDReused
			}

			return &SendResult{Message: &existing, Body: req.Body, WasCreated: false}, nil
		}
		return nil, txErr
	}

	return &SendResult{Message: &message, Body: req.Body, WasCreated: true}, nil
}

// buildRecipientRows fans a message out to every OTHER active
// participant's active devices — never the sender's own. Takes tx
// (not s.db) since it must run inside the same transaction as the
// message insert: either both succeed together, or neither does.
func buildRecipientRows(tx *gorm.DB, conversationID, callerID, messageID uuid.UUID, plaintextBody string) ([]models.MessageRecipient, error) {
	var otherParticipants []models.ConversationParticipant
	if err := tx.Where("conversation_id = ? AND user_id != ? AND is_active = ?", conversationID, callerID, true).
		Find(&otherParticipants).Error; err != nil {
		return nil, fmt.Errorf("failed to load other participants: %w", err)
	}
	if len(otherParticipants) == 0 {
		return nil, nil
	}

	otherUserIDs := make([]uuid.UUID, len(otherParticipants))
	for i, p := range otherParticipants {
		otherUserIDs[i] = p.UserID
	}

	var recipientDevices []models.Device
	if err := tx.Where("user_id IN ? AND status = ?", otherUserIDs, "active").
		Find(&recipientDevices).Error; err != nil {
		return nil, fmt.Errorf("failed to load recipient devices: %w", err)
	}

	rows := make([]models.MessageRecipient, 0, len(recipientDevices))
	for _, device := range recipientDevices {
		rows = append(rows, models.MessageRecipient{
			MessageID:         messageID,
			RecipientUserID:   device.UserID,
			RecipientDeviceID: device.ID,
			// TEMPORARY (Week 5 only): plaintext, identical for every
			// recipient device. Week 6 replaces this with real
			// per-device Signal Protocol ciphertext — see migration
			// 000006's comment. The column and this struct don't change;
			// only what's written here does.
			Ciphertext: plaintextBody,
			Status:     "sent",
		})
	}
	return rows, nil
}

// isActiveParticipant is shared by SendMessage and ListMessages —
// extracted rather than duplicated, so the two callers can never
// silently drift into checking slightly different things.
func (s *Service) isActiveParticipant(ctx context.Context, conversationID, userID uuid.UUID) (bool, error) {
	var count int64
	if err := s.db.WithContext(ctx).Model(&models.ConversationParticipant{}).
		Where("conversation_id = ? AND user_id = ? AND is_active = ?", conversationID, userID, true).
		Count(&count).Error; err != nil {
		return false, err
	}
	return count > 0, nil
}

const (
	defaultMessageListLimit = 50
	maxMessageListLimit     = 100
)

// messageListRow is the raw shape of ListMessages' join query. Every
// selected column is given an explicit alias — both `messages` and
// `message_recipients` have their own `id` column, and this project
// already had one real bug from trusting an ORM's default column
// scoping instead of being explicit (see the "ambiguous column" note
// on GET /conversations, Week 5 Day 2). No repeats of that here.
type messageListRow struct {
	RecipientRowID uuid.UUID `gorm:"column:recipient_row_id"`
	MessageID      uuid.UUID `gorm:"column:message_id"`
	SenderID       uuid.UUID `gorm:"column:sender_id"`
	MessageType    string    `gorm:"column:message_type"`
	Body           string    `gorm:"column:body"`
	Status         string    `gorm:"column:status"`
	CreatedAt      time.Time `gorm:"column:created_at"`
}

// ListMessages returns up to `limit` messages for conversationIDStr
// that were delivered to the CALLER'S CURRENT DEVICE specifically
// (not just the caller's account) — message_recipients is per-device
// by design, and this device may not be the only one the caller is
// logged in on. Ordered newest-first internally (matching the
// idx_messages_conversation_time index, built exactly for this
// access pattern), then reversed to oldest-first in the response, the
// natural order for rendering a chat thread top-to-bottom.
//
// Side effect: any returned message still marked "sent" for this
// device is updated to "delivered" — fetching a message IS the
// delivery event from the server's point of view. This update is
// best-effort: if it fails, the request still succeeds and returns
// the messages (with their pre-update status) rather than failing the
// whole read over a secondary bookkeeping concern, matching how
// devices.last_active_at is handled elsewhere in this codebase.
func (s *Service) ListMessages(ctx context.Context, callerID, callerDeviceID uuid.UUID, conversationIDStr string, limit int, beforeMessageIDStr string) ([]MessageListItem, error) {
	conversationID, err := uuid.Parse(conversationIDStr)
	if err != nil {
		return nil, ErrInvalidConversationID
	}

	isParticipant, err := s.isActiveParticipant(ctx, conversationID, callerID)
	if err != nil {
		return nil, fmt.Errorf("failed to verify participant: %w", err)
	}
	if !isParticipant {
		return nil, ErrNotAParticipant
	}

	if limit <= 0 {
		limit = defaultMessageListLimit
	}
	if limit > maxMessageListLimit {
		limit = maxMessageListLimit
	}

	query := s.db.WithContext(ctx).
		Table("message_recipients mr").
		Select(`mr.id AS recipient_row_id, m.id AS message_id, m.sender_id AS sender_id,
		        m.message_type AS message_type, mr.ciphertext AS body, mr.status AS status,
		        m.created_at AS created_at`).
		Joins("JOIN messages m ON m.id = mr.message_id").
		Where("mr.recipient_user_id = ? AND mr.recipient_device_id = ? AND m.conversation_id = ? AND m.deleted_at IS NULL",
			callerID, callerDeviceID, conversationID)

	if beforeMessageIDStr != "" {
		beforeID, err := uuid.Parse(beforeMessageIDStr)
		if err != nil {
			return nil, ErrInvalidBeforeMessageID
		}
		var cursor models.Message
		if err := s.db.WithContext(ctx).
			Where("id = ? AND conversation_id = ?", beforeID, conversationID).
			First(&cursor).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return nil, ErrInvalidBeforeMessageID
			}
			return nil, fmt.Errorf("failed to resolve pagination cursor: %w", err)
		}
		query = query.Where("m.created_at < ?", cursor.CreatedAt)
	}

	var rows []messageListRow
	if err := query.Order("m.created_at DESC").Limit(limit).Scan(&rows).Error; err != nil {
		return nil, fmt.Errorf("failed to list messages: %w", err)
	}

	var toMarkDelivered []uuid.UUID
	for _, r := range rows {
		if r.Status == "sent" {
			toMarkDelivered = append(toMarkDelivered, r.RecipientRowID)
		}
	}
	if len(toMarkDelivered) > 0 {
		now := time.Now().UTC()
		if err := s.db.WithContext(ctx).Model(&models.MessageRecipient{}).
			Where("id IN ?", toMarkDelivered).
			Updates(map[string]any{"status": "delivered", "delivered_at": now}).Error; err != nil {
			log.Printf("WARNING: failed to mark %d message(s) delivered for device %s: %v", len(toMarkDelivered), callerDeviceID, err)
		} else {
			for i := range rows {
				if rows[i].Status == "sent" {
					rows[i].Status = "delivered"
				}
			}
		}
	}

	// Reverse DESC -> ASC (oldest first) for the response.
	items := make([]MessageListItem, len(rows))
	for i, r := range rows {
		items[len(rows)-1-i] = MessageListItem{
			ID:          r.MessageID.String(),
			SenderID:    r.SenderID.String(),
			MessageType: r.MessageType,
			Body:        r.Body,
			Status:      r.Status,
			CreatedAt:   r.CreatedAt.Format(time.RFC3339),
		}
	}

	return items, nil
}
