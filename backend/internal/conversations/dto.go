package conversations

// CreateConversationRequest is the body for POST /conversations. The
// caller (creator) always comes from the JWT, never the request body
// — you can only ever create a conversation with yourself as one of
// the two participants, never on someone else's behalf.
type CreateConversationRequest struct {
	ParticipantID string `json:"participant_id" binding:"required"`
}

// ConversationResponse is what's returned on success — whether the
// conversation was just created, or an existing direct conversation
// between the same two people was found and returned instead (see
// Service.CreateDirectConversation).
type ConversationResponse struct {
	ID        string `json:"id"`
	Type      string `json:"type"`
	CreatedAt string `json:"created_at"`
}

// ListConversationsResponse is the body for GET /conversations.
type ListConversationsResponse struct {
	Conversations []ConversationListItem `json:"conversations"`
}

// ConversationListItem is one row in the conversation list.
//
// Ordering is currently by creation time (newest first) — this is a
// known, deliberate placeholder: once messages exist (later this
// week), this should sort by most recent message instead, which is
// what every real chat app actually does. Flagged here rather than
// silently shipped as if it were the final design.
//
// OtherParticipant is only populated for type="direct" — a direct
// conversation has no name/photo of its own, so the UI needs the
// other person's info to display anything meaningful in the list.
// Group conversations (not creatable yet) will need their own
// group_details-backed name/photo once that exists.
type ConversationListItem struct {
	ID               string                          `json:"id"`
	Type             string                          `json:"type"`
	CreatedAt        string                          `json:"created_at"`
	OtherParticipant *ConversationParticipantSummary `json:"other_participant,omitempty"`
}

// ConversationParticipantSummary is the same safe, minimal subset of
// a user's profile as SearchUserResponse — never phone_number/email
// for someone other than yourself.
type ConversationParticipantSummary struct {
	ID              string  `json:"id"`
	Name            string  `json:"name"`
	About           *string `json:"about,omitempty"`
	ProfilePhotoURL *string `json:"profile_photo_url,omitempty"`
}
