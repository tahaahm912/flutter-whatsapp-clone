// Package server wires up the Gin engine and route registration.
// Keeping this separate from main.go means later days (auth
// middleware, WebSocket upgrade, new feature routes) all plug in here
// without touching the entrypoint.
package server

import (
	"whatsapp-clone-backend/internal/health"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

// Server wraps the Gin engine and every shared dependency (DB, Redis,
// and later config/JWT secrets etc.) so there's a single place new
// dependencies get threaded through as the project grows.
type Server struct {
	engine *gin.Engine
	db     *gorm.DB
	redis  *redis.Client
}

// New builds a Server with all routes registered.
func New(database *gorm.DB, redisClient *redis.Client) *Server {
	engine := gin.Default()
	s := &Server{engine: engine, db: database, redis: redisClient}
	s.registerRoutes()
	return s
}

// Run starts the HTTP server on the given address, e.g. ":8080".
func (s *Server) Run(addr string) error {
	return s.engine.Run(addr)
}

// registerRoutes is the single place new endpoints get added as the
// project grows (auth routes in Week 2-3, user/key routes in Week 4,
// conversation/message routes in Week 5, etc.).
func (s *Server) registerRoutes() {
	s.engine.GET("/health", health.Handler(s.db, s.redis))
}
