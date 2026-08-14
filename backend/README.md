# Backend — WhatsApp Clone (Go)

Go + Gin + GORM + PostgreSQL + Redis backend for the WhatsApp clone
project. See [`DAY_LOG.md`](DAY_LOG.md) for a detailed, day-by-day
account of what's been built and why.

## ⚠️ For the Frontend (Member 1) — read this first

### Bugs to fix (block protected endpoints entirely until fixed)

1. **`core/network/auth_interceptor.dart` sends an empty token on
   every request:**
   ```dart
   options.headers["Authorization"] = "Bearer ";
   ```
   This never reads the real token from `SecureStorage`. Every
   protected route will fail with `401 AUTH_HEADER_MALFORMED` until
   this reads the actual stored access token, e.g.:
   ```dart
   final token = await SecureStorage().getAccessToken();
   options.headers["Authorization"] = "Bearer $token";
   ```

2. **`features/auth/data/models/login_response.dart` expects a
   `message` field the backend never sends, and doesn't parse the
   `user` object the backend does send:**
   ```dart
   message: json["message"] ?? "",
   ```
   Not a crash (defaults to `""`), but the actual response shape from
   `POST /auth/login` is:
   ```json
   {
     "access_token": "...",
     "refresh_token": "...",
     "token_type": "Bearer",
     "expires_at": "2026-...",
     "user": { "id": "...", "name": "...", "phone_number": "...", "email": "..." }
   }
   ```
   `GET /users/me` exists specifically so profile data can be fetched
   separately — if that's the intended design, this is fine as-is;
   just confirm it's intentional, not a gap.

Full details, plus anything found in future days, are kept in
[`docs/API_CONTRACT_REVIEW.md`](docs/API_CONTRACT_REVIEW.md).

### Important behavior to know (not bugs — how these endpoints actually work)

- **`GET /users/{userId}/keys` is a stateful GET.** Each call consumes
  (permanently marks used) one one-time pre-key per device, if one is
  available. Don't call it speculatively or repeatedly — only call it
  when actually about to start a session with that user. This is
  intentional Signal Protocol behavior, not a caching bug.
- **`POST /users/keys` validates real key material**, not just "is it
  present." Each public key/signature must be valid base64 (standard,
  raw, or URL-safe — all accepted) decoding to **32 or 33 bytes** for
  public keys (raw vs. Signal's type-byte-prefixed format — both
  accepted) or **64 bytes** for the signed pre-key's signature. A
  malformed key returns `400 INVALID_KEY_FORMAT` with a specific
  reason rather than being silently stored. `registration_id` must be
  1–16380 (Signal's 14-bit range).
- **`POST /conversations` is idempotent for direct conversations.**
  Calling it again with the same participant returns the *existing*
  conversation (`200`), not a new duplicate (`201`) — check the status
  code, not just the response body, to know which happened.
- **`GET /conversations` currently sorts by creation time, not
  recent activity.** This is a known placeholder — there are no
  messages yet to sort by "most recent message," which is what a real
  chat app's list should actually do. Don't build UI that assumes this
  ordering is final.
- **`POST /messages` stores plaintext, deliberately, for now.** Week 5
  is plaintext-first per the build plan — `body` is sent and stored as
  plain text; Week 6 replaces this with real per-device Signal
  Protocol ciphertext, but the API shape shouldn't need to change.
  `client_message_id` is required and must be freshly generated per
  message — retrying the same one is safe (returns the original
  message), but reusing one across two different conversations is a
  client bug and returns `409`.
- **A sent message is NOT echoed back to the sender via any GET
  endpoint.** The sender's own client is expected to store its own
  sent message locally (this is what the Drift local database, built
  the same day as this endpoint, is for) rather than fetch it back
  from the server — this matches how real Signal-protocol clients
  work, not a missing feature.
- **`GET /messages/{conversationId}` is per-device, not per-user, and
  has a side effect.** It returns messages delivered to the calling
  device specifically (a user with two devices would get different
  results from each). Fetching a message that's still marked "sent"
  updates it to "delivered" as part of serving the response — this is
  the delivery-receipt mechanism, not a caching quirk.

## Prerequisites

- Go 1.22+
- PostgreSQL 15+
- Redis
- [golang-migrate CLI](https://github.com/golang-migrate/migrate)

Run `./verify_environment.sh` to confirm all of the above are
installed and running.

## Setup

1. Copy the environment template and fill in a real `JWT_SECRET`
   (generate one with `openssl rand -base64 48`):
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

## API reference

Full request/response shapes: [`docs/openapi.yaml`](docs/openapi.yaml)
(paste into https://editor.swagger.io) or import
[`postman/WhatsApp_Clone_Auth.postman_collection.json`](postman/WhatsApp_Clone_Auth.postman_collection.json)
into Postman — 15 requests covering the full flow in run order.

| Method | Path | Auth required? | Purpose |
|---|---|---|---|
| GET | `/health` | No | Liveness + DB/Redis check |
| GET | `/health/protected` | Yes | Auth+session smoke test |
| POST | `/auth/register` | No | Create account (pending verification) |
| POST | `/auth/verify-otp` | No | Activate account with the OTP code |
| POST | `/auth/resend-otp` | No | Get a new OTP code (60s cooldown) |
| POST | `/auth/login` | No | Get access + refresh tokens |
| POST | `/auth/refresh` | No (needs refresh token) | Rotate to a new token pair |
| POST | `/auth/logout` | No (needs refresh token) | Revoke a session |
| GET | `/users/me` | Yes | Your own profile |
| GET | `/users/search` | Yes | Find someone by exact phone or email |
| POST | `/users/keys` | Yes | Upload Signal Protocol public keys for this device |
| GET | `/users/{userId}/keys` | Yes | Fetch a user's key bundle(s) to start an encrypted session |
| POST | `/conversations` | Yes | Create (or find existing) a direct conversation |
| GET | `/conversations` | Yes | List your conversations |
| POST | `/messages` | Yes | Send a message (plaintext during Week 5) |
| GET | `/messages/{conversationId}` | Yes | Retrieve this device's messages for a conversation |

**"Auth required" = `Authorization: Bearer <access_token>` header.**
Get one from `/auth/login`.

## Project structure

```
backend/
├── cmd/api/main.go          # entrypoint: loads config, connects DB+Redis, starts server
├── internal/
│   ├── config/               # .env / environment variable loading
│   ├── db/                   # PostgreSQL connection (GORM)
│   ├── cache/                # Redis connection
│   ├── models/                # GORM structs mapped to the finalized schema
│   ├── otp/                   # OTP generation/verification (Redis-backed)
│   ├── auth/                  # Registration, login, sessions, JWT issuance
│   ├── middleware/             # JWT auth middleware + session validation
│   ├── users/                  # Profile data (GET /users/me, /users/search)
│   ├── keys/                    # Signal Protocol public key storage (POST /users/keys)
│   ├── conversations/            # Conversation creation (POST /conversations)
│   ├── messages/                 # Message sending (POST /messages)
│   ├── server/                 # Gin engine setup + route registration
│   └── health/                 # GET /health handler
├── migrations/                 # versioned SQL schema (golang-migrate), source of truth
├── postman/                    # importable Postman collection, full flow
├── docs/                       # OpenAPI spec, contract review, gate check script
├── go.mod
├── Makefile                    # tidy / run / build / test / migrate-up / migrate-down
├── .env.example
└── DAY_LOG.md                  # day-by-day build log
```

## Design decisions worth knowing

- **Schema ownership:** the database schema lives entirely in
  `/migrations/*.sql`. GORM is used only to read/write rows —
  `AutoMigrate` is never called, so the schema can't silently drift
  from the finalized design.
- **UUIDs generated in Go, not relied on from Postgres:** every model
  with a UUID primary key (`User`, `Device`, `RefreshToken`) has an
  explicit `BeforeCreate` hook that generates the ID before insert.
  This was a real bug once (see `DAY_LOG.md`, "Bug Fix — UUID Type
  Mismatch") — GORM has no visibility into the database's own
  `DEFAULT gen_random_uuid()` since the schema is managed outside
  GORM. Generating explicitly in Go removes that whole class of bug.
- **Config centralization:** `internal/config` is the only package
  that reads raw environment variables. Everything else receives
  already-resolved values as parameters.
- **Standardized error responses:** every error from every endpoint
  is `{"error": "...", "code": "MACHINE_READABLE_CODE"}` — always
  branch on `code`, not on the human-readable `error` message. Full
  list of codes in `docs/openapi.yaml`'s description block.
- **Dependency wiring:** `main.go` builds each dependency (config → DB
  → Redis → server) and passes it down explicitly, rather than using
  globals — this keeps testing straightforward later (Week 8).

## Available commands

| Command | Purpose |
|---|---|
| `make tidy` | Download dependencies, generate/update go.sum |
| `make run` | Run the server locally |
| `make build` | Build a binary into `./bin` |
| `make test` | Run all Go tests (JWT middleware, key format validation) |
| `make migrate-up` | Apply all pending migrations |
| `make migrate-down` | Roll back the most recent migration |
