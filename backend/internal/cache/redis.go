// Package cache owns the single Redis connection used by the whole
// application. Redis will back presence/online status, rate limiting,
// and WebSocket connection routing in later weeks — none of that
// belongs in PostgreSQL, since it's all transient by nature.
package cache

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// Connect opens a Redis connection and confirms it's reachable with a
// PING before returning — this is the exact Day 4 checkpoint ("Redis
// responds to a PING").
func Connect(addr, password string, dbIndex int) (*redis.Client, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
		DB:       dbIndex,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to ping redis at %s: %w", addr, err)
	}

	return client, nil
}
