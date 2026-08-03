package auth

import (
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Handler translates HTTP requests into Service calls and Service
// errors into HTTP status codes. It holds no business logic itself.
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
			"details": err.Error(),
		})
		return
	}

	user, err := h.service.Register(c.Request.Context(), req)
	if err != nil {
		switch {
		case errors.Is(err, ErrIdentifierRequired):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		case errors.Is(err, ErrIdentifierTaken):
			c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		default:
			// Never leak raw internal error details (DB DSNs, driver
			// errors, etc.) to the client.
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusCreated, RegisterResponse{
		ID:          user.ID,
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
			"details": err.Error(),
		})
		return
	}

	user, err := h.service.VerifyOTP(c.Request.Context(), req)
	if err != nil {
		switch {
		case errors.Is(err, ErrTooManyAttempts):
			c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error(), "code": "OTP_TOO_MANY_ATTEMPTS"})
		case errors.Is(err, ErrInvalidOrExpired):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "OTP_INVALID_OR_EXPIRED"})
		case errors.Is(err, ErrUserNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusOK, VerifyOTPResponse{
		Verified:      true,
		AccountStatus: user.AccountStatus,
	})
}

// Login handles POST /auth/login.
func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request",
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
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusOK, LoginResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    "Bearer",
		ExpiresAt:    result.ExpiresAt.Format(time.RFC3339),
		User: LoginUserSummary{
			ID:          result.User.ID,
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
			"details": err.Error(),
		})
		return
	}

	if err := h.service.Logout(c.Request.Context(), req.RefreshToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
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
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusOK, LoginResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    "Bearer",
		ExpiresAt:    result.ExpiresAt.Format(time.RFC3339),
		User: LoginUserSummary{
			ID:          result.User.ID,
			Name:        result.User.Name,
			PhoneNumber: result.User.PhoneNumber,
			Email:       result.User.Email,
		},
	})
}
