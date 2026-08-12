package users

// MeResponse is what GET /users/me returns. Field selection matches
// exactly what mobile/lib/features/profile/profile_screen.dart
// already expects to display (its comment literally says "We will
// replace these with GET /users/me data" for name/about/phone/email).
//
// "about" is used as the JSON key rather than "about_text" (the DB
// column name) — shorter, and matches the Flutter screen's own local
// variable name (_about). Everywhere else in this API mirrors DB
// column names directly; this is the one deliberate exception.
type MeResponse struct {
	ID              string  `json:"id"`
	Name            string  `json:"name"`
	PhoneNumber     *string `json:"phone_number,omitempty"`
	Email           *string `json:"email,omitempty"`
	About           *string `json:"about,omitempty"`
	ProfilePhotoURL *string `json:"profile_photo_url,omitempty"`
	CreatedAt       string  `json:"created_at"`
}

// SearchUserRequest binds GET /users/search's query parameters.
// Exactly one of Phone/Email is required — enforced in the service
// layer (Gin's binding tags can validate each field's own format, but
// not a "exactly one of these two" cross-field rule).
type SearchUserRequest struct {
	Phone string `form:"phone" binding:"omitempty,e164"`
	Email string `form:"email" binding:"omitempty,email"`
}

// SearchUserResponse is deliberately minimal — this is someone else's
// profile, found by a stranger's search, not the account owner
// looking at their own data (that's MeResponse). It excludes both
// phone_number and email: the searcher already knows whichever
// identifier they searched with, and has no legitimate need to see
// the other one just because a match was found. Only what WhatsApp
// itself would show in a contact result: name, about, photo.
type SearchUserResponse struct {
	ID              string  `json:"id"`
	Name            string  `json:"name"`
	About           *string `json:"about,omitempty"`
	ProfilePhotoURL *string `json:"profile_photo_url,omitempty"`
}
