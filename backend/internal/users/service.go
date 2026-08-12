// Package users handles user profile data — starting with GET
// /users/me (Week 4 Day 1). Kept separate from internal/auth: auth
// owns identity/sessions, users owns profile data. They'll diverge
// further once profile editing, avatars, and contacts arrive later
// this week.
package users

import (
	"context"
	"errors"
	"fmt"

	"whatsapp-clone-backend/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ErrUserNotFound covers both "no such row" and "the ID in the JWT
// isn't even a valid UUID" — the latter should never happen for a
// token this API itself issued, but failing closed rather than
// panicking on a malformed ID is the correct default either way.
var ErrUserNotFound = errors.New("user not found")

// ErrSearchParamRequired covers both "neither phone nor email was
// given" and "both were given" — search is one-identifier-at-a-time
// by design, matching how the search box will actually be used.
var ErrSearchParamRequired = errors.New("provide exactly one of phone or email")

// Service handles user profile lookups.
type Service struct {
	db *gorm.DB
}

// NewService builds a users Service.
func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

// GetByID fetches a user by their ID (as a string — the middleware
// stores it that way in the Gin context, since it comes straight out
// of the JWT's "sub" claim, which is JSON/string by nature).
func (s *Service) GetByID(ctx context.Context, userID string) (*models.User, error) {
	id, err := uuid.Parse(userID)
	if err != nil {
		return nil, ErrUserNotFound
	}

	var user models.User
	if err := s.db.WithContext(ctx).Where("id = ?", id).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to look up user: %w", err)
	}
	return &user, nil
}

// Search finds one user by an exact phone number or email match — not
// both, not a substring/partial match. Only accounts with
// account_status = 'active' are discoverable: a pending-verification
// or disabled account being found by a stranger's search would leak
// information about accounts that aren't really "on" the platform yet
// (or shouldn't be), similar in spirit to why login never reveals
// whether an identifier exists.
func (s *Service) Search(ctx context.Context, phone, email string) (*models.User, error) {
	hasPhone := phone != ""
	hasEmail := email != ""
	if hasPhone == hasEmail { // both empty, or both provided
		return nil, ErrSearchParamRequired
	}

	query := s.db.WithContext(ctx).Where("account_status = ?", "active")
	if hasPhone {
		query = query.Where("phone_number = ?", phone)
	} else {
		query = query.Where("email = ?", email)
	}

	var user models.User
	if err := query.First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to search for user: %w", err)
	}
	return &user, nil
}
