// Command api is the entrypoint for the WhatsApp Clone backend server.
package main

import (
	"fmt"
	"log"

	"whatsapp-clone-backend/internal/cache"
	"whatsapp-clone-backend/internal/config"
	"whatsapp-clone-backend/internal/db"
	"whatsapp-clone-backend/internal/server"
)

func main() {
	cfg := config.Load()

	database, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("could not connect to database: %v", err)
	}
	log.Println("connected to database successfully")

	redisClient, err := cache.Connect(cfg.RedisAddr, cfg.RedisPassword, cfg.RedisDB)
	if err != nil {
		log.Fatalf("could not connect to redis: %v", err)
	}
	log.Println("connected to redis successfully")

	srv := server.New(database, redisClient, cfg.JWTSecret)

	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("starting server on %s", addr)
	if err := srv.Run(addr); err != nil {
		log.Fatalf("server failed to start: %v", err)
	}
}
