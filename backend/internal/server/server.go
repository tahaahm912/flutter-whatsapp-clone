// Package server wires up the Gin engine and route registration.
// Keeping this separate from main.go means later days (WebSocket
// upgrade, new feature routes) all plug in here without touching the
// entrypoint.
package server

import (
	"net/http"

	"whatsapp-clone-backend/internal/auth"
	"whatsapp-clone-backend/internal/conversations"
	"whatsapp-clone-backend/internal/health"
	"whatsapp-clone-backend/internal/keys"
	"whatsapp-clone-backend/internal/middleware"
	"whatsapp-clone-backend/internal/otp"
	"whatsapp-clone-backend/internal/users"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

// Server wraps the Gin engine and every shared dependency (DB, Redis,
// and the feature handlers built on top of them) so there's a single
// place new dependencies get threaded through as the project grows.
type Server struct {
	engine              *gin.Engine
	db                  *gorm.DB
	redis               *redis.Client
	authHandler         *auth.Handler
	usersHandler        *users.Handler
	keysHandler         *keys.Handler
	conversationsHandler *conversations.Handler
	jwtSecret           string
	deviceChecker       middleware.DeviceChecker
}

// New builds a Server with all routes registered.
func New(database *gorm.DB, redisClient *redis.Client, jwtSecret string) *Server {
	engine := gin.Default()

	otpService := otp.NewService(redisClient)
	authService := auth.NewService(database, otpService, jwtSecret)
	authHandler := auth.NewHandler(authService)
	deviceChecker := middleware.NewGormDeviceChecker(database)
	usersService := users.NewService(database)
	usersHandler := users.NewHandler(usersService)
	keysService := keys.NewService(database)
	keysHandler := keys.NewHandler(keysService)
	conversationsService := conversations.NewService(database)
	conversationsHandler := conversations.NewHandler(conversationsService)

	s := &Server{
		engine:               engine,
		db:                   database,
		redis:                redisClient,
		authHandler:          authHandler,
		usersHandler:         usersHandler,
		keysHandler:          keysHandler,
		conversationsHandler: conversationsHandler,
		jwtSecret:            jwtSecret,
		deviceChecker:        deviceChecker,
	}
	s.registerRoutes()
	return s
}

// Run starts the HTTP server on the given address, e.g. ":8080".
func (s *Server) Run(addr string) error {
	return s.engine.Run(addr)
}

// registerRoutes is the single place new endpoints get added as the
// project grows.
func (s *Server) registerRoutes() {
	s.engine.GET("/health", health.Handler(s.db, s.redis))

	// Kept from Week 3 Day 1 as a lightweight auth+session smoke test;
	// GET /users/me below is the first real protected resource.
	s.engine.GET("/health/protected", middleware.RequireAuth(s.jwtSecret, s.deviceChecker), func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
			"authenticated_as": gin.H{
				"user_id":   c.GetString(middleware.ContextUserIDKey),
				"device_id": c.GetString(middleware.ContextDeviceIDKey),
			},
		})
	})

	authGroup := s.engine.Group("/auth")
	authGroup.POST("/register", s.authHandler.Register)
	authGroup.POST("/verify-otp", s.authHandler.VerifyOTP)
	authGroup.POST("/resend-otp", s.authHandler.ResendOTP)
	authGroup.POST("/login", s.authHandler.Login)
	authGroup.POST("/refresh", s.authHandler.Refresh)
	authGroup.POST("/logout", s.authHandler.Logout)

	// First real protected resource group (Week 4 Day 1). Every route
	// added here is automatically behind RequireAuth — no need to
	// repeat it per-route the way /health/protected does above.
	usersGroup := s.engine.Group("/users")
	usersGroup.Use(middleware.RequireAuth(s.jwtSecret, s.deviceChecker))
	usersGroup.GET("/me", s.usersHandler.Me)
	usersGroup.GET("/search", s.usersHandler.Search)
	usersGroup.POST("/keys", s.keysHandler.UploadKeys)
	usersGroup.GET("/:userId/keys", s.keysHandler.GetUserKeys)

	// Week 5: conversations/messages. Registered as a direct route
	// (not a group) for now, matching /health/protected's style —
	// more conversation routes will likely justify a group once there
	// are enough of them to warrant one.
	s.engine.POST("/conversations", middleware.RequireAuth(s.jwtSecret, s.deviceChecker), s.conversationsHandler.Create)
	s.engine.GET("/conversations", middleware.RequireAuth(s.jwtSecret, s.deviceChecker), s.conversationsHandler.List)
}
