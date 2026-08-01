# Backend — WhatsApp Clone (Go)

Go + Gin + GORM + PostgreSQL + Redis backend for the WhatsApp clone
project. See [`DAY_LOG.md`](DAY_LOG.md) for a detailed, day-by-day
account of what's been built and why.

## Prerequisites

- Go 1.22+
- PostgreSQL 15+
- Redis
- [golang-migrate CLI](https://github.com/golang-migrate/migrate)

Run `./verify_environment.sh` to confirm all of the above are
installed and running.

## Setup

1. Copy the environment template and adjust if your local setup differs:
   ```bash
   cp .env.example .env
   ```

2. Create the database:
   ```bash
   createdb whatsapp_clone
   ```

3. Run migrations:
   ```bash
   export DATABASE_URL="postgres://postgres:postgres@localhost:5432/whatsapp_clone?sslmode=disable"
   make migrate-up
   ```

4. Fetch Go dependencies:
   ```bash
   make tidy
   ```

5. Run the server:
   ```bash
   make run
   ```

6. Confirm everything is healthy:
   ```bash
   curl -s http://localhost:8080/health | jq
   ```
   Expected: `{"status":"ok","database":"ok","redis":"ok",...}`

## Project structure

```
backend/
├── cmd/api/main.go          # entrypoint: loads config, connects DB+Redis, starts server
├── internal/
│   ├── config/              # .env / environment variable loading
│   ├── db/                  # PostgreSQL connection (GORM)
│   ├── cache/               # Redis connection
│   ├── models/               # GORM structs mapped to the finalized schema
│   ├── server/               # Gin engine setup + route registration
│   └── health/               # GET /health handler
├── migrations/               # versioned SQL schema (golang-migrate), source of truth
├── go.mod
├── Makefile                  # tidy / run / build / test / migrate-up / migrate-down
├── .env.example
└── DAY_LOG.md                # day-by-day build log
```

## Design decisions worth knowing

- **Schema ownership:** the database schema lives entirely in
  `/migrations/*.sql`. GORM is used only to read/write rows —
  `AutoMigrate` is never called, so the schema can't silently drift
  from the finalized design.
- **Config centralization:** `internal/config` is the only package
  that reads raw environment variables. Everything else receives
  already-resolved values as parameters.
- **Dependency wiring:** `main.go` builds each dependency (config → DB
  → Redis → server) and passes it down explicitly, rather than using
  globals — this keeps testing straightforward later (Week 8).

## Available commands

| Command | Purpose |
|---|---|
| `make tidy` | Download dependencies, generate/update go.sum |
| `make run` | Run the server locally |
| `make build` | Build a binary into `./bin` |
| `make test` | Run all tests (used from Week 8 onward) |
| `make migrate-up` | Apply all pending migrations |
| `make migrate-down` | Roll back the most recent migration |
