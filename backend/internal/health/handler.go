// Package health provides a liveness/readiness endpoint used to
// confirm the backend process is up AND can reach both its database
// and its cache.
package health

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

// Handler returns a gin.HandlerFunc closed over both dependencies, so
// GET /health reports whether the process, the database, and Redis
// are all reachable in one call — useful both for you during
// development and for a real uptime monitor later.
func Handler(database *gorm.DB, redisClient *redis.Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		dbStatus := "ok"
		sqlDB, err := database.DB()
		if err != nil || sqlDB.Ping() != nil {
			dbStatus = "unreachable"
		}

		redisStatus := "ok"
		ctx, cancel := context.WithTimeout(c.Request.Context(), 2*time.Second)
		defer cancel()
		if err := redisClient.Ping(ctx).Err(); err != nil {
			redisStatus = "unreachable"
		}

		c.JSON(http.StatusOK, gin.H{
			"status":   "ok",
			"database": dbStatus,
			"redis":    redisStatus,
			"time":     time.Now().UTC().Format(time.RFC3339),
		})
	}
}
