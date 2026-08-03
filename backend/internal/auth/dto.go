package auth

// RegisterRequest is the expected JSON body for POST /auth/register.
// Field-level validation (required, format) is handled by Gin's
// binding tags; the business rule "at least one of phone_number/email
// must be present" is enforced in the service layer, since it spans
// two fields and isn't expressible as a single field tag.
type RegisterRequest struct {
	Name        string `json:"name" binding:"required,min=2,max=100"`
	PhoneNumber string `json:"phone_number" binding:"omitempty,e164"`
	Email       string `json:"email" binding:"omitempty,email"`
	Password    string `json:"password" binding:"required,min=8,max=72"`
}

// RegisterResponse is what we send back on success. Deliberately does
// NOT embed models.User directly — that would risk ever accidentally
// serializing password_hash to a client. Only safe-to-expose fields
// are listed explicitly here.
type RegisterResponse struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	PhoneNumber *string `json:"phone_number,omitempty"`
	Email       *string `json:"email,omitempty"`
	CreatedAt   string  `json:"created_at"`
}

// VerifyOTPRequest is the expected JSON body for POST /auth/verify-otp.
// `identifier` must be the exact phone_number or email the account
// was registered with.
type VerifyOTPRequest struct {
	Identifier string `json:"identifier" binding:"required"`
	Code       string `json:"code" binding:"required,len=6,numeric"`
}

// VerifyOTPResponse confirms the account is now active. It
// deliberately does NOT issue any auth tokens — that's Day 3
// (POST /auth/login), kept as a separate step on purpose.
type VerifyOTPResponse struct {
	Verified      bool   `json:"verified"`
	AccountStatus string `json:"account_status"`
}

// LoginRequest is the expected JSON body for POST /auth/login.
// device_name/platform are optional and describe the session being
// created; Postman testers can omit them and get sensible defaults.
type LoginRequest struct {
	Identifier string `json:"identifier" binding:"required"`
	Password   string `json:"password" binding:"required"`
	DeviceName string `json:"device_name" binding:"omitempty,max=100"`
	Platform   string `json:"platform" binding:"omitempty,oneof=android ios web desktop"`
}

// LoginResponse carries both tokens plus a minimal user summary.
// access_token is a short-lived JWT; refresh_token is a long-lived
// opaque token used with POST /auth/refresh (Day 4) to get a new
// access token without re-entering a password.
type LoginResponse struct {
	AccessToken  string          `json:"access_token"`
	RefreshToken string          `json:"refresh_token"`
	TokenType    string          `json:"token_type"`
	ExpiresAt    string          `json:"expires_at"`
	User         LoginUserSummary `json:"user"`
}

// LoginUserSummary is an explicit allowlist of user fields safe to
// return on login — same reasoning as RegisterResponse.
type LoginUserSummary struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	PhoneNumber *string `json:"phone_number,omitempty"`
	Email       *string `json:"email,omitempty"`
}

// RefreshRequest is the expected JSON body for POST /auth/refresh.
// The response reuses LoginResponse deliberately — the client should
// handle "got new tokens" identically whether they came from /login
// or /refresh, so there's no reason for the JSON shape to differ.
type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// LogoutRequest is the expected JSON body for POST /auth/logout.
type LogoutRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// LogoutResponse confirms the session was ended. Always returned as
// 200 with success:true — logout is idempotent (see Service.Logout),
// so there's no meaningful failure case to report to the client here.
type LogoutResponse struct {
	Success bool `json:"success"`
}
