// Package server wires up the Gin engine and route registration.
// Keeping this separate from main.go means later days (auth
// middleware, WebSocket upgrade, new feature routes) all plug in here
// without touching the entrypoint.
package server

import (
	"whatsapp-clone-backend/internal/auth"
	"whatsapp-clone-backend/internal/health"
	"whatsapp-clone-backend/internal/otp"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

// Server wraps the Gin engine and every shared dependency (DB, Redis,
// and the feature handlers built on top of them) so there's a single
// place new dependencies get threaded through as the project grows.
type Server struct {
	engine      *gin.Engine
	db          *gorm.DB
	redis       *redis.Client
	authHandler *auth.Handler
}

// New builds a Server with all routes registered.
func New(database *gorm.DB, redisClient *redis.Client, jwtSecret string) *Server {
	engine := gin.Default()

	otpService := otp.NewService(redisClient)
	authService := auth.NewService(database, otpService, jwtSecret)
	authHandler := auth.NewHandler(authService)

	s := &Server{
		engine:      engine,
		db:          database,
		redis:       redisClient,
		authHandler: authHandler,
	}
	s.registerRoutes()
	return s
}

// Run starts the HTTP server on the given address, e.g. ":8080".
func (s *Server) Run(addr string) error {
	return s.engine.Run(addr)
}

// registerRoutes is the single place new endpoints get added as the
// project grows (remaining auth routes this week, user/key routes in
// Week 4, conversation/message routes in Week 5, etc.).
func (s *Server) registerRoutes() {
	s.engine.GET("/health", health.Handler(s.db, s.redis))

	authGroup := s.engine.Group("/auth")
	authGroup.POST("/register", s.authHandler.Register)
	authGroup.POST("/verify-otp", s.authHandler.VerifyOTP)
	authGroup.POST("/login", s.authHandler.Login)
	authGroup.POST("/refresh", s.authHandler.Refresh)
	authGroup.POST("/logout", s.authHandler.Logout)
}
