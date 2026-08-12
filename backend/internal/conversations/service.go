// Package conversations handles creating and (later, this week)
// listing/reading conversations. Week 5 is deliberately plaintext-
// first per the original build plan — encryption is layered in
// cleanly during Week 6, not mixed into this week's plumbing.
package conversations

import (
	"context"
	"errors"
	"fmt"
	"time"

	"whatsapp-clone-backend/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Sentinel errors the handler maps to specific HTTP status codes.
var (
	ErrInvalidParticipant  = errors.New("participant_id is not a valid user ID")
	ErrCannotMessageSelf   = errors.New("cannot create a conversation with yourself")
	ErrParticipantNotFound = errors.New("no active user found for that participant_id")
)

// Service handles conversation creation/lookup.
type Service struct {
	db *gorm.DB
}

// NewService builds a conversations Service.
func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

// CreateResult reports whether a new conversation was actually
// created, or an existing one was found and returned instead — the
// handler uses this to pick 201 vs 200.
type CreateResult struct {
	Conversation *models.Conversation
	WasCreated   bool
}

// CreateDirectConversation creates a 1:1 conversation between
// callerID and the user identified by participantIDStr — or, if the
// two already have one, returns that existing conversation instead of
// creating a duplicate. Without this check, every time either person
// taps "message" on the other's profile would spawn a brand new,
// empty conversation, which would make direct messaging unusable in
// practice.
func (s *Service) CreateDirectConversation(ctx context.Context, callerID uuid.UUID, participantIDStr string) (*CreateResult, error) {
	participantID, err := uuid.Parse(participantIDStr)
	if err != nil {
		return nil, ErrInvalidParticipant
	}
	if participantID == callerID {
		return nil, ErrCannotMessageSelf
	}

	// Same discoverability rule as GET /users/search: only active
	// accounts can be messaged, for the same reasoning (a pending-
	// verification or disabled account shouldn't be a valid message
	// target any more than it should show up in search).
	var participant models.User
	if err := s.db.WithContext(ctx).
		Where("id = ? AND account_status = ?", participantID, "active").
		First(&participant).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrParticipantNotFound
		}
		return nil, fmt.Errorf("failed to look up participant: %w", err)
	}

	existingID, err := s.findExistingDirectConversation(ctx, callerID, participantID)
	if err != nil {
		return nil, fmt.Errorf("failed to check for an existing conversation: %w", err)
	}
	if existingID != uuid.Nil {
		var existing models.Conversation
		if err := s.db.WithContext(ctx).Where("id = ?", existingID).First(&existing).Error; err != nil {
			return nil, fmt.Errorf("failed to load existing conversation: %w", err)
		}
		return &CreateResult{Conversation: &existing, WasCreated: false}, nil
	}

	var conversation models.Conversation
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		conversation = models.Conversation{
			Type:      "direct",
			CreatedBy: callerID,
		}
		if err := tx.Create(&conversation).Error; err != nil {
			return fmt.Errorf("failed to create conversation: %w", err)
		}

		participants := []models.ConversationParticipant{
			{ConversationID: conversation.ID, UserID: callerID, Role: "member", IsActive: true},
			{ConversationID: conversation.ID, UserID: participantID, Role: "member", IsActive: true},
		}
		if err := tx.Create(&participants).Error; err != nil {
			return fmt.Errorf("failed to add participants: %w", err)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return &CreateResult{Conversation: &conversation, WasCreated: true}, nil
}

// findExistingDirectConversation looks for a 'direct' conversation
// where both userA and userB are currently active participants.
// Returns uuid.Nil (not an error) if none exists.
func (s *Service) findExistingDirectConversation(ctx context.Context, userA, userB uuid.UUID) (uuid.UUID, error) {
	var result struct {
		ID uuid.UUID
	}
	err := s.db.WithContext(ctx).Raw(`
		SELECT c.id FROM conversations c
		JOIN conversation_participants cp1
			ON cp1.conversation_id = c.id AND cp1.user_id = ? AND cp1.is_active = true
		JOIN conversation_participants cp2
			ON cp2.conversation_id = c.id AND cp2.user_id = ? AND cp2.is_active = true
		WHERE c.type = 'direct'
		LIMIT 1
	`, userA, userB).Scan(&result).Error
	if err != nil {
		return uuid.Nil, err
	}
	return result.ID, nil
}

// ListConversations returns every conversation callerID is an active
// participant in, newest-created first. Deliberately built as 3 fixed
// queries total regardless of how many conversations exist (one for
// the conversations themselves, one batch-load of "the other
// participant" per direct conversation, one batch-load of those
// participants' profiles) rather than looping and querying per
// conversation — a conversation list is exactly the kind of endpoint
// that gets called often, so an N+1 query pattern here would actually
// matter in practice, not just in theory.
func (s *Service) ListConversations(ctx context.Context, callerID uuid.UUID) ([]ConversationListItem, error) {
	var conversationRows []models.Conversation
	if err := s.db.WithContext(ctx).
		Select("conversations.*").
		Joins("JOIN conversation_participants cp ON cp.conversation_id = conversations.id").
		Where("cp.user_id = ? AND cp.is_active = ?", callerID, true).
		Order("conversations.created_at DESC").
		Find(&conversationRows).Error; err != nil {
		return nil, fmt.Errorf("failed to list conversations: %w", err)
	}

	if len(conversationRows) == 0 {
		return []ConversationListItem{}, nil
	}

	conversationIDs := make([]uuid.UUID, len(conversationRows))
	for i, conv := range conversationRows {
		conversationIDs[i] = conv.ID
	}

	// Batch 2: for each conversation, who's the OTHER active
	// participant (only meaningful for type="direct" — a group
	// conversation has more than one "other" participant, but nothing
	// creates group conversations yet, so this only really matters for
	// direct ones in practice today).
	var otherParticipantRows []models.ConversationParticipant
	if err := s.db.WithContext(ctx).
		Where("conversation_id IN ? AND user_id != ? AND is_active = ?", conversationIDs, callerID, true).
		Find(&otherParticipantRows).Error; err != nil {
		return nil, fmt.Errorf("failed to load other participants: %w", err)
	}

	otherUserIDByConversation := make(map[uuid.UUID]uuid.UUID, len(otherParticipantRows))
	otherUserIDSet := make(map[uuid.UUID]struct{})
	for _, p := range otherParticipantRows {
		otherUserIDByConversation[p.ConversationID] = p.UserID
		otherUserIDSet[p.UserID] = struct{}{}
	}

	otherUserIDs := make([]uuid.UUID, 0, len(otherUserIDSet))
	for id := range otherUserIDSet {
		otherUserIDs = append(otherUserIDs, id)
	}

	// Batch 3: load the actual profile info for those other users.
	usersByID := make(map[uuid.UUID]models.User, len(otherUserIDs))
	if len(otherUserIDs) > 0 {
		var userRows []models.User
		if err := s.db.WithContext(ctx).Where("id IN ?", otherUserIDs).Find(&userRows).Error; err != nil {
			return nil, fmt.Errorf("failed to load participant profiles: %w", err)
		}
		for _, u := range userRows {
			usersByID[u.ID] = u
		}
	}

	items := make([]ConversationListItem, 0, len(conversationRows))
	for _, conv := range conversationRows {
		item := ConversationListItem{
			ID:        conv.ID.String(),
			Type:      conv.Type,
			CreatedAt: conv.CreatedAt.Format(time.RFC3339),
		}
		if conv.Type == "direct" {
			if otherUserID, ok := otherUserIDByConversation[conv.ID]; ok {
				if u, ok := usersByID[otherUserID]; ok {
					item.OtherParticipant = &ConversationParticipantSummary{
						ID:              u.ID.String(),
						Name:            u.Name,
						About:           u.AboutText,
						ProfilePhotoURL: u.ProfilePhotoURL,
					}
				}
			}
		}
		items = append(items, item)
	}

	return items, nil
}
