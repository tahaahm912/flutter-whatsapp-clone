package middleware

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"whatsapp-clone-backend/internal/auth"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const testSecret = "test-secret-for-middleware-tests-only"

// fakeDeviceChecker is a test-only DeviceChecker — no database needed
// at all, which is the entire point of DeviceChecker being an
// interface (added Week 3 Day 4).
type fakeDeviceChecker struct {
	active bool
	err    error
}

func (f *fakeDeviceChecker) IsDeviceActive(ctx context.Context, deviceID string) (bool, error) {
	return f.active, f.err
}

// signToken builds and signs a JWT from the given claims — a direct
// stand-in for auth.generateAccessToken (unexported, so tests build
// tokens this way instead), giving full control over edge cases like
// an already-expired token or a token signed with the wrong secret.
func signToken(t *testing.T, claims auth.Claims, secret string) string {
	t.Helper()
	signed, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(secret))
	if err != nil {
		t.Fatalf("failed to sign test token: %v", err)
	}
	return signed
}

func validClaims() auth.Claims {
	now := time.Now()
	return auth.Claims{
		UserID:   "11111111-1111-1111-1111-111111111111",
		DeviceID: "22222222-2222-2222-2222-222222222222",
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
		},
	}
}

// testRouter mirrors exactly how server.go wires RequireAuth in front
// of a real handler, so these tests exercise the same integration
// point production traffic goes through. Takes a DeviceChecker so
// each test can control whether the "session" is active.
func testRouter(checker DeviceChecker) *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.GET("/protected", RequireAuth(testSecret, checker), func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"user_id":   c.GetString(ContextUserIDKey),
			"device_id": c.GetString(ContextDeviceIDKey),
		})
	})
	return r
}

func TestRequireAuth(t *testing.T) {
	activeChecker := &fakeDeviceChecker{active: true}

	validToken := signToken(t, validClaims(), testSecret)

	expiredClaims := validClaims()
	expiredClaims.IssuedAt = jwt.NewNumericDate(time.Now().Add(-2 * time.Hour))
	expiredClaims.ExpiresAt = jwt.NewNumericDate(time.Now().Add(-1 * time.Hour))
	expiredToken := signToken(t, expiredClaims, testSecret)

	wrongSecretToken := signToken(t, validClaims(), "a-completely-different-secret")

	tests := []struct {
		name       string
		omitHeader bool
		header     string
		checker    DeviceChecker
		wantStatus int
		wantCode   string // empty = don't check (used for the success case)
	}{
		{
			name:       "missing Authorization header is rejected",
			omitHeader: true,
			checker:    activeChecker,
			wantStatus: http.StatusUnauthorized,
			wantCode:   "AUTH_HEADER_MISSING",
		},
		{
			name:       "header without Bearer prefix is rejected",
			header:     "Token abc123",
			checker:    activeChecker,
			wantStatus: http.StatusUnauthorized,
			wantCode:   "AUTH_HEADER_MALFORMED",
		},
		{
			name:       "Bearer with no token is rejected",
			header:     "Bearer ",
			checker:    activeChecker,
			wantStatus: http.StatusUnauthorized,
			wantCode:   "AUTH_HEADER_MALFORMED",
		},
		{
			name:       "garbage token is rejected",
			header:     "Bearer not.a.valid.jwt",
			checker:    activeChecker,
			wantStatus: http.StatusUnauthorized,
			wantCode:   "TOKEN_INVALID",
		},
		{
			name:       "token signed with the wrong secret is rejected",
			header:     "Bearer " + wrongSecretToken,
			checker:    activeChecker,
			wantStatus: http.StatusUnauthorized,
			wantCode:   "TOKEN_INVALID",
		},
		{
			name:       "expired token is rejected with a distinct code",
			header:     "Bearer " + expiredToken,
			checker:    activeChecker,
			wantStatus: http.StatusUnauthorized,
			wantCode:   "TOKEN_EXPIRED",
		},
		{
			name:       "valid token with an active device is accepted",
			header:     "Bearer " + validToken,
			checker:    activeChecker,
			wantStatus: http.StatusOK,
		},
		{
			// Week 3 Day 4: a cryptographically valid, unexpired token
			// must still be rejected if the underlying session/device
			// was revoked (e.g. the user logged out on another request).
			name:       "valid token with a revoked device is rejected",
			header:     "Bearer " + validToken,
			checker:    &fakeDeviceChecker{active: false},
			wantStatus: http.StatusUnauthorized,
			wantCode:   "SESSION_REVOKED",
		},
		{
			name:       "device check failure surfaces as an internal error, not a false accept",
			header:     "Bearer " + validToken,
			checker:    &fakeDeviceChecker{err: errors.New("database is down")},
			wantStatus: http.StatusInternalServerError,
			wantCode:   "INTERNAL_ERROR",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := testRouter(tt.checker)

			req := httptest.NewRequest(http.MethodGet, "/protected", nil)
			if !tt.omitHeader {
				req.Header.Set("Authorization", tt.header)
			}

			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			if w.Code != tt.wantStatus {
				t.Fatalf("status = %d, want %d (body: %s)", w.Code, tt.wantStatus, w.Body.String())
			}

			if tt.wantCode != "" {
				var body map[string]any
				if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
					t.Fatalf("failed to parse response body: %v", err)
				}
				if body["code"] != tt.wantCode {
					t.Fatalf("code = %v, want %v (body: %s)", body["code"], tt.wantCode, w.Body.String())
				}
			}
		})
	}
}

// TestRequireAuth_SetsContextValues confirms downstream handlers
// actually receive the right user_id/device_id — the middleware being
// merely "not rejecting" a valid token isn't enough; the whole point
// of Week 4's GET /users/me depends on these values being correct.
func TestRequireAuth_SetsContextValues(t *testing.T) {
	r := testRouter(&fakeDeviceChecker{active: true})
	claims := validClaims()
	token := signToken(t, claims, testSecret)

	req := httptest.NewRequest(http.MethodGet, "/protected", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200 (body: %s)", w.Code, w.Body.String())
	}

	var body map[string]string
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("failed to parse response body: %v", err)
	}
	if body["user_id"] != claims.UserID {
		t.Errorf("user_id = %q, want %q", body["user_id"], claims.UserID)
	}
	if body["device_id"] != claims.DeviceID {
		t.Errorf("device_id = %q, want %q", body["device_id"], claims.DeviceID)
	}
}
