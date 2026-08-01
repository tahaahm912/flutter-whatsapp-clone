.PHONY: tidy run build test migrate-up migrate-down

# Requires the golang-migrate CLI: https://github.com/golang-migrate/migrate
# and DATABASE_URL to be set in your shell environment.
migrate-up:
	migrate -path migrations -database "$(DATABASE_URL)" up

migrate-down:
	migrate -path migrations -database "$(DATABASE_URL)" down 1

# Fetch dependencies and generate/update go.sum
tidy:
	go mod tidy

# Run the API server locally
run:
	go run ./cmd/api

# Build a binary into ./bin
build:
	go build -o bin/api ./cmd/api

# Run all tests (used from Week 8 onward)
test:
	go test ./...
