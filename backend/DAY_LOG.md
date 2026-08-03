# Backend (Member 2) — Day-by-Day Log

This file is updated every day with what was done, what was verified,
and what's next. Keep it in the repo so both team members can track
progress at a glance.

---

## Week 1, Day 1 — Environment Setup

**Goal (from schedule):** Install Go, PostgreSQL, Redis. Verify each with
`--version` / service status. No errors.

**What's included in today's package:**
- `verify_environment.sh` — run this after installing the tools below.
  It checks Go, PostgreSQL (client + running server), Redis (client +
  running server), and Git, and tells you exactly what's missing.

**Your steps to complete Day 1:**

1. Install Go 1.22 or newer: https://go.dev/dl/
   Verify: `go version`

2. Install PostgreSQL 15 or newer:
   - macOS: `brew install postgresql@15`
   - Ubuntu/Debian: `sudo apt install postgresql postgresql-contrib`
   - Windows: use the official installer from postgresql.org
   Verify: `psql --version` and `pg_isready`

3. Install Redis:
   - macOS: `brew install redis`
   - Ubuntu/Debian: `sudo apt install redis-server`
   - Windows: use Redis via WSL2 or Memurai (Windows-native Redis alternative)
   Verify: `redis-cli --version` and `redis-cli ping` (should return `PONG`)

4. Install Git if you don't already have it: https://git-scm.com/downloads
   Verify: `git --version`

5. Run the verification script:
   ```bash
   chmod +x verify_environment.sh
   ./verify_environment.sh
   ```
   It should report `0 failed` at the end.

**Checkpoint status:** ⬜ Pending your local verification (I can't run
these on your machine — please run the script above and let me know
the result before we move to Day 2).

**Next up (Day 2):** Initialize the Go module, set up a basic Gin
server with a `GET /health` route.

---

## Week 1, Day 2 — Go Module + Basic Gin Server

**Goal (from schedule):** Initialize the Go module. Set up a basic Gin
server with a GET /health route. Checkpoint: Go server responds to
/health with 200 OK.

**What's included in today's package:**
- `go.mod` — module `whatsapp-clone-backend`, Go 1.22, depends on
  `github.com/gin-gonic/gin`.
- `cmd/api/main.go` — the entrypoint; starts the server on `:8080`.
- `internal/server/server.go` — builds the Gin engine and is the one
  place all future routes get registered (auth, users, conversations,
  messages, websocket — all plug in here in later weeks).
- `internal/health/handler.go` — the `GET /health` handler, returns
  `{"status": "ok", "time": "..."}` with HTTP 200.
- `.gitignore` — excludes `.env`, build binaries, IDE folders.
- `Makefile` — `make tidy`, `make run`, `make build`, `make test`
  shortcuts.

**Why this structure:** `cmd/` vs `internal/` is the standard Go
project layout. `internal/` can't be imported by other modules, which
keeps our application code from leaking as a public API by accident.
Splitting `server` (routing/wiring) from `health` (a single
feature/handler) establishes the pattern every future feature will
follow: one small package per concern, wired together in `server.go`.

**Your steps to complete Day 2** (I can't run Go in my sandbox, so
please verify this on your machine):

```bash
cd backend
make tidy      # downloads gin and generates go.sum
make run       # starts the server on :8080
```

In a second terminal:
```bash
curl -i http://localhost:8080/health
```
Expected: `HTTP/1.1 200 OK` with a JSON body like
`{"status":"ok","time":"2026-07-29T12:00:00Z"}`.

**Note on go.sum:** I didn't include a `go.sum` file, since it's a
checksum lock file that only `go mod tidy` (run with real network
access) can correctly generate. Running `make tidy` on your machine
will create it — that's expected and normal, not something wrong with
the package.

**Checkpoint status:** ⬜ Pending your local verification — run the
steps above and let me know if `/health` returns 200.

**Next up (Day 3):** Add GoRouter (Member 1, Flutter side). Connect Gin
to PostgreSQL using GORM and write the first migration for the `users`
table (Member 2, this package).

---

## Week 1, Day 3 — PostgreSQL Connection + Users Table Migration

**Goal (from schedule):** Connect Gin to PostgreSQL using GORM. Write
the first migration for the `users` table. Checkpoint: `users` table
exists in PostgreSQL.

**What's included in today's package:**
- `internal/db/db.go` — opens a PostgreSQL connection via GORM. Reads
  `DATABASE_URL` if set, otherwise falls back to a local default DSN.
- `internal/models/user.go` — the `User` struct mapped to the `users`
  table, matching the finalized schema exactly (column-by-column).
- `migrations/000001_create_users_table.up.sql` /
  `.down.sql` — a real SQL migration (not GORM AutoMigrate) that
  creates the `users` table exactly as defined in the project's final
  database schema.
- `internal/health/handler.go` — updated: `/health` now also reports
  `"database": "ok"` or `"unreachable"`, so you get an instant signal
  if the DB connection breaks.
- `Makefile` — added `make migrate-up` / `make migrate-down`.

**Why SQL migrations instead of GORM AutoMigrate:** You already
approved a final, bulletproof 3NF schema. AutoMigrate can silently
alter tables in ways that drift from that schema over time. Using
versioned `.sql` migration files means the schema is controlled
explicitly, in one place, and every change is reviewable — this
matters a lot once V4 (groups), V6 (encryption), etc. add many more
interdependent tables from that same schema.

**Your steps to complete Day 3:**

1. Install the `golang-migrate` CLI:
   - macOS: `brew install golang-migrate`
   - Linux/other: see https://github.com/golang-migrate/migrate#installation

2. Create the database (adjust user/password to your local Postgres setup):
   ```bash
   createdb whatsapp_clone
   ```

3. Set your connection string for this terminal session:
   ```bash
   export DATABASE_URL="postgres://postgres:postgres@localhost:5432/whatsapp_clone?sslmode=disable"
   ```

4. Run the migration:
   ```bash
   cd backend
   make migrate-up
   ```

5. Confirm the table exists:
   ```bash
   psql whatsapp_clone -c "\d users"
   ```
   You should see all the columns listed (id, phone_number, email, etc.)

6. Fetch the new dependencies and run the server:
   ```bash
   make tidy
   make run
   ```

7. In another terminal:
   ```bash
   curl -s http://localhost:8080/health | jq
   ```
   Expected: `"status": "ok"` and `"database": "ok"`.

**Checkpoint status:** ⬜ Pending your local verification.

**Next up (Day 4):** Set up the Redis connection. Add `.env`-based
configuration for secrets and connection strings (replacing today's
hardcoded fallback DSN with a proper config loader).

---

## Week 1, Day 4 — Redis Connection + .env Configuration

**Goal (from schedule):** Set up the Redis connection. Add
`.env`-based configuration for secrets and connection strings.
Checkpoint: Redis responds to a PING.

**What's included in today's package:**
- `internal/config/config.go` — loads a `.env` file if present (via
  `godotenv`), then reads every setting from real environment
  variables with sensible local-dev fallbacks. This is now the *only*
  place that reads raw env vars — `db.go` and the new `cache`
  package just receive already-resolved values as parameters.
- `internal/cache/redis.go` — opens a Redis connection and confirms it
  with a `PING` before returning (today's exact checkpoint).
- `.env.example` — a template of every configurable value (`PORT`,
  `DATABASE_URL`, `REDIS_ADDR`, `REDIS_PASSWORD`, `REDIS_DB`). Copy
  this to `.env` locally; `.env` itself stays git-ignored.
- `internal/db/db.go` — refactored: now takes the DSN as a parameter
  instead of reading `DATABASE_URL` itself, so all config-reading is
  centralized in one package.
- `internal/health/handler.go` — `/health` now also reports
  `"redis": "ok"` or `"unreachable"`.
- `internal/server/server.go`, `cmd/api/main.go` — updated to load
  config first, then connect DB and Redis, then start the server on
  `cfg.Port` instead of a hardcoded `:8080`.
- `go.mod` — added `github.com/joho/godotenv` and
  `github.com/redis/go-redis/v9`.

**Why centralize config now:** From here on, every new feature (JWT
secrets in Week 2, FCM credentials in Week 7) adds one field to
`Config` instead of scattering `os.Getenv` calls across the codebase —
this is the kind of thing that's cheap to do now and annoying to
retrofit later.

**Your steps to complete Day 4:**

1. Install Redis if you haven't already (see Day 1), and make sure
   it's running:
   ```bash
   redis-cli ping
   ```
   should return `PONG`.

2. Copy the env template and adjust if your local Postgres/Redis
   setup differs from the defaults:
   ```bash
   cd backend
   cp .env.example .env
   ```

3. Fetch the new dependencies:
   ```bash
   make tidy
   ```

4. Run the server:
   ```bash
   make run
   ```
   You should see both "connected to database successfully" and
   "connected to redis successfully" in the logs before "starting
   server on :8080".

5. In another terminal:
   ```bash
   curl -s http://localhost:8080/health | jq
   ```
   Expected: `"status":"ok"`, `"database":"ok"`, `"redis":"ok"`.

**Checkpoint status:** ⬜ Pending your local verification.

**Next up (Day 5, together with Member 1):** Initialize a Git
repository, add a root-level `.gitignore`, push both `mobile/` and
`backend/` folders to GitHub, write a short top-level README.

---

## Week 1, Day 5 (together) — Git & GitHub

**Goal (from schedule):** Initialize a Git repository, add a
`.gitignore`, push both `mobile/` and `backend/` folders to GitHub,
write a short README. Checkpoint: both projects committed to GitHub
with a clear folder structure and README.

**What's included in today's package:** the whole delivery is now
restructured as a repo root, not just a `backend/` folder:

```
project-root/
├── .gitignore          # NEW — shared root ignores (OS, IDE, .env)
├── README.md           # NEW — top-level project overview for both members
├── GIT_SETUP.md        # NEW — exact commands to init git and push to GitHub
├── backend/
│   ├── README.md        # NEW — backend-specific setup, consolidating Days 1-4
│   └── ... (everything from Days 1-4, unchanged)
└── mobile/
    └── PLACEHOLDER.md    # NEW — notes where Member 1's Flutter project goes
```

**Why this shape:** this is a "together" day in the schedule — there's
no new backend logic today. The useful thing I can actually do from
here is get the *repository* itself production-shaped: a clear root
README, a git-safety-net `.gitignore` that catches `.env` files
anywhere in the repo, and exact step-by-step commands for the actual
`git init` / GitHub push, since that has to happen on your machine
with your GitHub account — I can't run `git push` from this sandbox.

**Your steps to complete Day 5:**

1. Unzip today's package as your actual project root (or copy its
   contents into wherever your combined repo should live).
2. Put Member 1's real Flutter project at `mobile/`, replacing
   `mobile/PLACEHOLDER.md`.
3. Follow [`GIT_SETUP.md`](GIT_SETUP.md) exactly — it covers `git
   init`, the first commit, creating the GitHub repo, pushing, and a
   safety check to make sure no `.env` file got committed.
4. Both of you should be able to `git clone` the repo fresh and see
   the structure above.

**Checkpoint status:** ⬜ Pending — confirm once both of you can see
the repo on GitHub with the right structure.

**Next up (Day 6, buffer/together):** Review each other's setup, fix
any environment issues, and confirm you both understand the Week 2
plan (building the 5 authentication endpoints).

---

## Week 1, Day 6 (buffer) — Review & Week 2 Preview

**Goal (from schedule):** Review each other's setup, fix any
environment issues, confirm you both understand tomorrow's plan
(Week 2). Checkpoint: both dev environments fully working; Week 2
tasks are clear to both of you.

**What to actually do today:**
1. Both of you run `./verify_environment.sh` on your own machines —
   confirm 0 failures each.
2. Both of you run `make tidy && make migrate-up && make run`, then
   `curl http://localhost:8080/health` — confirm `database: ok` and
   `redis: ok` on both machines independently (not just one person's).
3. Read the Week 2 preview below together.

**Week 2 preview — Authentication (backend-led):**

Member 1 builds static UI screens this week (no real API calls yet).
Member 2 (this package) builds the real authentication engine,
one endpoint per day:

| Day | Endpoint | What it does |
|---|---|---|
| 1 | `POST /auth/register` | Validate name/phone-or-email/password, create the user row |
| 2 | OTP generation + `POST /auth/verify-otp` | Generate a one-time code, verify it |
| 3 | `POST /auth/login` | Compare password against bcrypt hash, issue tokens |
| 4 | `POST /auth/refresh` | Rotate access tokens using a refresh token |
| 5 | `POST /auth/logout` + Swagger docs | Invalidate a session; document all 5 endpoints |

By the end of Week 2, every endpoint should be independently testable
in Postman — Flutter doesn't wire up to any of this until Week 3.

**Checkpoint status:** ⬜ Pending — confirm both environments are
green before Day 1 of Week 2.

**Next up (Week 2, Day 1):** Build `POST /auth/register` with request
validation (name, phone/email, password). Checkpoint: register
endpoint returns 201 in Postman.

---

## Week 2, Day 1 — POST /auth/register

**Goal (from schedule):** Build POST /auth/register with request
validation (name, phone/email, password). Checkpoint: register
endpoint returns 201 in Postman.

**What's included in today's package:**
- `internal/auth/dto.go` — `RegisterRequest` (with Gin binding-tag
  validation: name required 2-100 chars, phone must be valid E.164
  if present, email must be valid format if present, password
  required 8-72 chars) and `RegisterResponse` (explicitly whitelisted
  fields — never risks leaking `password_hash`).
- `internal/auth/service.go` — the actual business logic: enforces
  "at least one of phone/email required", checks for an existing
  account, hashes the password with bcrypt, inserts the row. Handles
  the race condition where two requests hit the same phone/email
  simultaneously by catching the database's own unique-constraint
  violation, not just relying on the pre-check.
- `internal/auth/handler.go` — HTTP-only concerns: binds the request,
  calls the service, maps each error type to the right status code
  (400 for validation/missing-identifier, 409 for already-exists, 500
  for anything unexpected — with no internal error details ever sent
  to the client).
- `internal/server/server.go` — updated: wires up `auth.Service` +
  `auth.Handler` and registers `POST /auth/register` under an `/auth`
  route group (so Days 2-5 this week just add siblings to this group).
- `go.mod` — added `golang.org/x/crypto` for bcrypt.

**Security notes baked in (matching the loophole checklist from the
original plan):**
- Passwords are never stored or logged in plaintext — bcrypt only.
- The response never includes `password_hash`, even by accident,
  because `RegisterResponse` is a separate, explicit struct rather
  than returning `models.User` directly.
- Duplicate-account race conditions are closed at the database level
  (unique constraint + duplicate-key error handling), not just at the
  application level, which is what actually prevents two simultaneous
  requests from both succeeding.

**Your steps to test this (Postman or curl):**

Start the server as usual (`make run`), then:

```bash
curl -i -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "phone_number": "+14155552671",
    "password": "correcthorsebattery"
  }'
```
Expected: `HTTP/1.1 201 Created` with a JSON body containing `id`,
`name`, `phone_number`, `created_at` — and no `password_hash`.

**Test the error cases too** (all of these should behave correctly):
1. Same request again → expect `409 Conflict`, "already exists".
2. Missing both `phone_number` and `email` → expect `400 Bad Request`.
3. `password` under 8 characters → expect `400 Bad Request`.
4. Malformed `phone_number` (not E.164, e.g. `"12345"`) → expect `400`.

In Postman: create a collection called "WhatsApp Clone Auth", add this
as your first request. You'll add the other 4 auth endpoints to this
same collection over the next 4 days — by Day 5 this becomes the
full Postman collection the schedule asks for.

**Checkpoint status:** ⬜ Pending your local verification (again: I
can't run this against a live Postgres instance from this sandbox — I
did a full manual line-by-line review instead; see my note in chat).

**Next up (Week 2, Day 2):** Build OTP generation logic and
`POST /auth/verify-otp`.

---

## Week 2, Day 2 — OTP Generation + POST /auth/verify-otp

**Goal (from schedule):** Build OTP generation logic and
POST /auth/verify-otp. Checkpoint: OTP verification works when tested
in Postman.

**Important — a schema change was needed, done the right way:**
The finalized `users` schema had no "not yet verified" state, but a
real register→OTP→active flow needs one. Rather than editing the
original `000001` migration (which you approved as final), I added a
new, additive migration:
- `migrations/000002_add_otp_verification_fields.up.sql` / `.down.sql`
  — adds `'pending_verification'` as a new `account_status` value
  (now the default for new registrations), plus `phone_verified_at`
  and `email_verified_at` timestamp columns.

This is exactly what versioned migrations are for — the schema can
evolve without ever silently drifting or requiring you to hand-edit
an already-reviewed file.

**What's included in today's package:**
- `internal/otp/service.go` — new package. Generates a 6-digit numeric
  code (via `crypto/rand`, not `math/rand` — cryptographically secure),
  stores a SHA-256 hash of it in Redis with a 5-minute TTL, and
  verifies submitted codes with a max-5-attempts limit per code. Codes
  are single-use — deleted immediately on successful verification.
- `internal/auth/service.go` — updated: `Register` now creates users
  as `pending_verification` (not `active`), then generates an OTP and
  logs it to the server console (no SMS/email provider is wired up —
  that's outside V1's free-to-build scope, see the original plan).
  New `VerifyOTP` method checks the code, then activates the account
  and stamps the right verified-at column.
- `internal/auth/handler.go` — new `VerifyOTP` HTTP handler, mapping
  `otp.ErrTooManyAttempts` → `429`, `otp.ErrInvalidOrExpired` → `400`
  (with machine-readable `code` fields, `OTP_TOO_MANY_ATTEMPTS` /
  `OTP_INVALID_OR_EXPIRED`, matching what Week 3 Day 3 asks for —
  "standardize error codes").
- `internal/auth/dto.go` — `VerifyOTPRequest` / `VerifyOTPResponse`.
- `internal/models/user.go` — added `PhoneVerifiedAt`, `EmailVerifiedAt`.
- `internal/server/server.go` — wires up `otp.Service`, registers
  `POST /auth/verify-otp`.

**Why the code is logged instead of "sent":** an SMS/email provider
costs money and isn't part of the free-to-build plan from Week 0. The
server console log (`[DEV ONLY] OTP for ... is: ...`) is your stand-in
for that provider until one gets added post-V1 — this keeps the whole
flow fully testable for free right now.

**Your steps to test this (run migrations first!):**

```bash
cd backend
make migrate-up     # applies 000002 — do this before make run
make run
```

1. Register a new user (same as Day 1's curl command).
2. Watch the server console — you'll see a line like:
   `[DEV ONLY] OTP for +14155552671 is: 483920 (expires in 5 minutes)`
3. Verify it:
   ```bash
   curl -i -X POST http://localhost:8080/auth/verify-otp \
     -H "Content-Type: application/json" \
     -d '{"identifier": "+14155552671", "code": "483920"}'
   ```
   Expected: `200 OK`, `{"verified":true,"account_status":"active"}`.
4. Confirm in Postgres:
   ```bash
   psql whatsapp_clone -c "SELECT phone_number, account_status, phone_verified_at FROM users;"
   ```
   `account_status` should now show `active`.

**Test the error cases:**
1. Submit the same code again → expect `400`, `OTP_INVALID_OR_EXPIRED`
   (codes are single-use).
2. Submit a wrong code 6 times in a row → the 6th attempt should
   return `429`, `OTP_TOO_MANY_ATTEMPTS`.
3. Wait 5+ minutes, then try a previously-valid code → expect `400`,
   `OTP_INVALID_OR_EXPIRED` (Redis TTL expired it).

Add this as your second request in the Postman collection from Day 1.

**Checkpoint status:** ⬜ Pending your local verification.

**Next up (Week 2, Day 3):** Build `POST /auth/login` with bcrypt
password comparison, issuing a JWT on success.

---

## Week 2, Day 3 — POST /auth/login (bcrypt + JWT)

**Goal (from schedule):** Build POST /auth/login with bcrypt password
comparison, issuing a JWT. Checkpoint: login returns a JWT when tested
in Postman.

**Schema note:** login needs to track sessions/devices, and your
approved final schema already defined `devices` and `refresh_tokens`
tables for this (Section 1) — they just hadn't been migrated yet since
nothing needed them until today. Added as-is, no redesign:
- `migrations/000003_create_devices_and_refresh_tokens.up.sql` / `.down.sql`

**What's included in today's package:**
- `internal/auth/tokens.go` — new file. `generateAccessToken` signs a
  15-minute JWT (HS256) containing `sub` (user id) and `device_id`.
  `generateRefreshToken` produces a 32-byte random opaque token —
  **only the SHA-256 hash of it is ever stored**, so a database leak
  alone can't be used to forge a session. `ParseAccessToken` is
  exported now because Week 3 Day 1's JWT middleware needs it exactly
  as-is.
- `internal/auth/service.go` — new `Login` method: looks up the user,
  compares the password with bcrypt, rejects unverified/disabled
  accounts with specific errors, creates a `Device` row for this
  session, then issues both tokens and stores the refresh token's hash.
- `internal/auth/handler.go` — new `Login` handler: `401` for bad
  credentials, `403` + `ACCOUNT_NOT_VERIFIED` / `ACCOUNT_DISABLED` for
  blocked accounts.
- `internal/auth/dto.go` — `LoginRequest` / `LoginResponse`.
- `internal/models/device.go`, `internal/models/refresh_token.go` —
  new GORM models matching migration 000003.
- `internal/config/config.go` — new `JWTSecret` field, read from
  `JWT_SECRET`. Falls back to an insecure dev default **with a loud
  startup warning** if unset — never deploy with that default.
- `.env.example` — added `JWT_SECRET`.
- `internal/server/server.go`, `cmd/api/main.go` — thread the JWT
  secret through; register `POST /auth/login`.
- `go.mod` — added `github.com/golang-jwt/jwt/v5`.

**Security notes baked in:**
- Wrong password and "account doesn't exist" return the exact same
  error (`INVALID_CREDENTIALS`) — this prevents an attacker from using
  login attempts to discover which phone numbers/emails have accounts
  (a real WhatsApp-clone loophole from the original security plan).
- Access tokens are short-lived (15 min) on purpose — Day 4 adds the
  refresh flow so this doesn't mean re-logging-in constantly.
- Refresh tokens are hashed at rest, never stored raw.

**Known simplification (flagged, not hidden):** every login currently
creates a *new* device row, rather than reusing one for the same
physical device — there's no stable device identifier from the client
yet to key off of. This is schema-correct and fine for Postman
testing, but should be revisited once Flutter sends a real device ID
(Week 3+). Left as a `TODO` comment in the code.

**Your steps to test this:**

```bash
cd backend
make migrate-up     # applies 000003
cp .env.example .env  # if you haven't already — pick up JWT_SECRET
make run
```

1. Register + verify a user (Days 1-2), so their account is `active`.
2. Log in:
   ```bash
   curl -i -X POST http://localhost:8080/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "identifier": "+14155552671",
       "password": "correcthorsebattery",
       "device_name": "Postman Test",
       "platform": "web"
     }'
   ```
   Expected: `200 OK` with `access_token`, `refresh_token`,
   `token_type: "Bearer"`, `expires_at`, and a `user` object.
3. Paste the `access_token` into https://jwt.io to confirm it decodes
   to `{"sub": "<user id>", "device_id": "<device id>", ...}`.

**Test the error cases:**
1. Wrong password → `401`, `INVALID_CREDENTIALS`.
2. Unknown identifier → `401`, `INVALID_CREDENTIALS` (same error, by design).
3. Login before OTP verification → `403`, `ACCOUNT_NOT_VERIFIED`.

Add this as your third Postman request.

**Checkpoint status:** ⬜ Pending your local verification.

**Next up (Week 2, Day 4):** Build `POST /auth/refresh` to rotate
access tokens using a refresh token.

---

## Full re-verification (before Day 4, requested check)

Before writing new code today, I re-checked everything built so far
(Days 1-6 + Week 2 Days 1-3), since I still have no internet access in
this sandbox to actually compile it. This time, beyond reading each
file, I ran automated structural checks across the whole repo:
- Every `package` declaration matches its folder name (14 files).
- Every import is actually used; no missing imports found.
- Brace `{}` and paren `()` counts balance in every file (a reliable
  signal for copy-paste/edit errors — a mismatch here would mean a
  guaranteed syntax error).
- No duplicate function, type, or sentinel-error declarations anywhere
  in the repo (checked by grepping every `func`/`type`/`Err...=` across
  all files and diffing for repeats).
- Every cross-package function call's argument types/order verified
  against the actual function signature (e.g. `server.New(db, redis,
  jwtSecret)` vs its real signature).
- Postgres CHECK constraint names referenced in migration 000002
  (`users_account_status_check`) verified against Postgres's actual
  auto-naming convention for unnamed inline CHECK constraints.

No issues found. This is the most thorough verification possible
without a working Go toolchain — it is still not a substitute for
actually running `go build`, which I'd ask you to do the moment you
get a chance, just to have a real compiler's word on it too.

---

## Week 2, Day 4 — POST /auth/refresh (token rotation)

**Goal (from schedule):** Build POST /auth/refresh to rotate access
tokens using a refresh token. Checkpoint: refresh flow works in Postman.

**What's included in today's package:**
- `internal/auth/tokens.go` — refactored: extracted `hashRefreshToken`
  as its own function (was inlined in `generateRefreshToken`), since
  `Refresh` now needs to hash an *incoming* token the same way.
- `internal/auth/service.go` — new `Refresh` method:
  1. Hashes the incoming raw token, looks up the matching
     `refresh_tokens` row by hash.
  2. Rejects if not found, already revoked, or expired — expired gets
     its own error (`REFRESH_TOKEN_EXPIRED`) so the client knows to
     send the user back to a normal login, not treat it as a bug.
  3. **Rotates**: revokes the old refresh token and issues a brand new
     one, in that order (revoke-then-create), so a crash mid-operation
     fails closed (old token dead) rather than fails open (both valid).
  4. Issues a new access token for the same user/device, and
     best-effort bumps the device's `last_active_at`.
- `internal/auth/handler.go` — new `Refresh` handler, reuses the exact
  same `LoginResponse` shape as `/login` (Day 6's buffer day is
  specifically about agreeing on response shapes — reusing one here
  removes an entire case Member 1 would otherwise need to handle).
- `internal/auth/dto.go` — `RefreshRequest`.
- `internal/server/server.go` — registers `POST /auth/refresh`.

**Why rotation, not just "extend the same token":** if a refresh token
ever leaks, rotation means it can only be used once before the
legitimate client's next refresh invalidates it — and a second, later
attempt to use the stolen token becomes a detectable signal (someone
tried to use an already-revoked token), rather than silent indefinite
access. This directly matches "no forward secrecy" from the original
security checklist, applied to sessions instead of message encryption.

**Your steps to test this:**

```bash
make run
```

1. Log in (Day 3) and note the `refresh_token` from the response.
2. Refresh:
   ```bash
   curl -i -X POST http://localhost:8080/auth/refresh \
     -H "Content-Type: application/json" \
     -d '{"refresh_token": "<paste the refresh_token here>"}'
   ```
   Expected: `200 OK` with a **new** `access_token` and a **new**
   `refresh_token`.
3. Immediately try the *same* (now-old) refresh token again → expect
   `401`, `REFRESH_TOKEN_INVALID` (rotation makes it dead on reuse).
4. Confirm in Postgres:
   ```bash
   psql whatsapp_clone -c "SELECT id, revoked_at, expires_at FROM refresh_tokens ORDER BY issued_at;"
   ```
   You should see the original row with `revoked_at` now set, and a
   new row with `revoked_at` still null.

Add this as your fourth Postman request.

**Checkpoint status:** ⬜ Pending your local verification.

**Next up (Week 2, Day 5):** Build `POST /auth/logout`. Document all 5
auth endpoints in Swagger.

---

## Week 2, Day 5 — POST /auth/logout + API Documentation

**Goal (from schedule):** Build POST /auth/logout. Document all 5 auth
endpoints in Swagger. Checkpoint: a full Postman collection exists
covering all 5 auth endpoints and passes.

**A real bug caught during review — worth telling you about:** while
editing `service.go` and `handler.go` to insert the new `Logout`
method between existing methods, two doc comments got accidentally
clipped mid-edit (a leftover fragment like `// brand new access
token...` with its first line missing). This wouldn't have broken
compilation — Go doesn't care about comment content — but it's exactly
the kind of small correctness slip that matters when you said "no
changes after this." I built a repo-wide check specifically for this
pattern (`func` immediately following `}` with no blank line/comment,
which is what these looked like after the clip) and confirmed zero
remaining instances before packaging today's zip. Full transparency
over silently fixing it and not mentioning it.

**What's included in today's package:**
- `internal/auth/service.go` — new `Logout` method: revokes the
  refresh token (idempotent — an already-invalid token still "succeeds",
  since the end state is already what the caller wants) and, since
  each login is currently its own device row, also marks that device
  `revoked`.
- `internal/auth/handler.go`, `dto.go` — `Logout` handler,
  `LogoutRequest`/`LogoutResponse`.
- `internal/server/server.go` — registers `POST /auth/logout`. All 5
  auth routes are now live.
- `postman/WhatsApp_Clone_Auth.postman_collection.json` — a real,
  importable Postman v2.1 collection covering all 5 endpoints plus
  `/health`, in run order. Login and Refresh have test scripts that
  **automatically capture tokens into collection variables**, so
  Refresh and Logout need zero manual copy-pasting once Login has run.
  Only Verify OTP needs a manual step (pasting the code from your
  server console into the `otp_code` variable) since there's no email/
  SMS provider to read it from automatically.
- `docs/openapi.yaml` — a complete OpenAPI 3.0.3 spec for all 6
  endpoints (health + 5 auth). Paste into https://editor.swagger.io
  for an interactive view, or `File > Import` it into Postman as an
  alternative to the hand-built collection above.

**Why a static OpenAPI file instead of a live `/swagger` UI:** a live
Swagger UI in Gin needs `swaggo/swag` + `swaggo/gin-swagger`, which
means running `swag init` to generate code — a step that needs network
access I don't have here. The static YAML file gives you the same
documentation value right now, with zero extra tooling required on
your end either. If you want the live `/swagger` route later, it's a
quick addition once you have a moment — happy to do that as a
follow-up whenever you'd like.

**Your steps to test this (once your machine is back up):**

```bash
make run
```
In Postman: `File > Import` →
`backend/postman/WhatsApp_Clone_Auth.postman_collection.json`. Run the
requests **in order** (1 → 5). Between request 1 and 2, check your
server console for the OTP line and paste the code into the
`otp_code` collection variable. Requests 3-5 need no manual steps.

Every request has an automated test assertion attached (visible in
Postman's "Test Results" tab per request) — if all pass, that's your
checkpoint for today.

**Checkpoint status:** ⬜ Pending your local verification (your PC was
down for this one — nothing to confirm until it's back).

**Next up (Week 3, Day 1):** Build the JWT authentication middleware
that protects routes going forward.
