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
