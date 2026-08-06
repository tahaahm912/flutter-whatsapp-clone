package auth

import (
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Handler translates HTTP requests into Service calls and Service
// errors into HTTP status codes. It holds no business logic itself.
//
// Error response shape is standardized (Week 3 Day 3) across every
// endpoint in this file: always {"error": "<human message>", "code":
// "<MACHINE_READABLE_CODE>"}, with "details" added only for request
// validation failures (where the raw binding error is genuinely
// useful for debugging a malformed request body). This lets Member 1
// branch on `code` instead of parsing/matching `error` message text,
// which is free to change wording without breaking the client.
type Handler struct {
	service *Service
}

// NewHandler builds an auth Handler.
func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// Register handles POST /auth/register.
func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request",
			"code":    "VALIDATION_ERROR",
			"details": err.Error(),
		})
		return
	}

	user, err := h.service.Register(c.Request.Context(), req)
	if err != nil {
		switch {
		case errors.Is(err, ErrIdentifierRequired):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "IDENTIFIER_REQUIRED"})
		case errors.Is(err, ErrIdentifierTaken):
			c.JSON(http.StatusConflict, gin.H{"error": err.Error(), "code": "IDENTIFIER_TAKEN"})
		default:
			// Never leak raw internal error details (DB DSNs, driver
			// errors, etc.) to the client.
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	c.JSON(http.StatusCreated, RegisterResponse{
		ID:          user.ID.String(),
		Name:        user.Name,
		PhoneNumber: user.PhoneNumber,
		Email:       user.Email,
		CreatedAt:   user.CreatedAt.Format(time.RFC3339),
	})
}

// VerifyOTP handles POST /auth/verify-otp.
func (h *Handler) VerifyOTP(c *gin.Context) {
	var req VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request",
			"code":    "VALIDATION_ERROR",
			"details": err.Error(),
		})
		return
	}

	user, err := h.service.VerifyOTP(c.Request.Context(), req)
	if err != nil {
		switch {
		case errors.Is(err, ErrTooManyAttempts):
			c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error(), "code": "OTP_TOO_MANY_ATTEMPTS"})
		case errors.Is(err, ErrInvalidOTP):
			// Refined (Week 3 Day 3): was merged with expired into one
			// code; now distinct so the client can show "wrong code,
			// try again" vs. "request a new code" appropriately.
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "INVALID_OTP"})
		case errors.Is(err, ErrOTPExpired):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "OTP_EXPIRED"})
		case errors.Is(err, ErrUserNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "USER_NOT_FOUND"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	c.JSON(http.StatusOK, VerifyOTPResponse{
		Verified:      true,
		AccountStatus: user.AccountStatus,
	})
}

// ResendOTP handles POST /auth/resend-otp.
func (h *Handler) ResendOTP(c *gin.Context) {
	var req ResendOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request",
			"code":    "VALIDATION_ERROR",
			"details": err.Error(),
		})
		return
	}

	if err := h.service.ResendOTP(c.Request.Context(), req.Identifier); err != nil {
		switch {
		case errors.Is(err, ErrUserNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "USER_NOT_FOUND"})
		case errors.Is(err, ErrAlreadyVerified):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "ALREADY_VERIFIED"})
		case errors.Is(err, ErrTooSoon):
			c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error(), "code": "OTP_RESEND_TOO_SOON"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	c.JSON(http.StatusOK, ResendOTPResponse{Sent: true})
}

// Login handles POST /auth/login.
func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request",
			"code":    "VALIDATION_ERROR",
			"details": err.Error(),
		})
		return
	}

	result, err := h.service.Login(c.Request.Context(), req)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidCredentials):
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error(), "code": "INVALID_CREDENTIALS"})
		case errors.Is(err, ErrAccountNotVerified):
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error(), "code": "ACCOUNT_NOT_VERIFIED"})
		case errors.Is(err, ErrAccountDisabled):
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error(), "code": "ACCOUNT_DISABLED"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	c.JSON(http.StatusOK, LoginResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    "Bearer",
		ExpiresAt:    result.ExpiresAt.Format(time.RFC3339),
		User: LoginUserSummary{
			ID:          result.User.ID.String(),
			Name:        result.User.Name,
			PhoneNumber: result.User.PhoneNumber,
			Email:       result.User.Email,
		},
	})
}

// Logout handles POST /auth/logout.
func (h *Handler) Logout(c *gin.Context) {
	var req LogoutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request",
			"code":    "VALIDATION_ERROR",
			"details": err.Error(),
		})
		return
	}

	if err := h.service.Logout(c.Request.Context(), req.RefreshToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		return
	}

	c.JSON(http.StatusOK, LogoutResponse{Success: true})
}

// Refresh handles POST /auth/refresh.
func (h *Handler) Refresh(c *gin.Context) {
	var req RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request",
			"code":    "VALIDATION_ERROR",
			"details": err.Error(),
		})
		return
	}

	result, err := h.service.Refresh(c.Request.Context(), req.RefreshToken)
	if err != nil {
		switch {
		case errors.Is(err, ErrRefreshTokenInvalid):
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error(), "code": "REFRESH_TOKEN_INVALID"})
		case errors.Is(err, ErrRefreshTokenExpired):
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error(), "code": "REFRESH_TOKEN_EXPIRED"})
		case errors.Is(err, ErrUserNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "USER_NOT_FOUND"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error", "code": "INTERNAL_ERROR"})
		}
		return
	}

	c.JSON(http.StatusOK, LoginResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    "Bearer",
		ExpiresAt:    result.ExpiresAt.Format(time.RFC3339),
		User: LoginUserSummary{
			ID:          result.User.ID.String(),
			Name:        result.User.Name,
			PhoneNumber: result.User.PhoneNumber,
			Email:       result.User.Email,
		},
	})
}
