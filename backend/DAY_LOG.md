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

---

## Merge Day — Reconciling with the actual shared repo + resend-OTP + API contract review

**Context:** the zips delivered for Week 2 Days 1-5 (above) were never
pushed to this repo — the repo was still at Week 1 Day 4 when this
was checked. All of Week 2's code (above) has now been merged directly
on top of this actual repo's backend, verified structurally (package
alignment, brace/paren balance, no duplicate declarations, no
cross-file signature mismatches — the same checks described in each
day's entry above), and confirmed the module name (`whatsapp-clone-backend`)
and Go version (`go 1.25`) already in this repo's `go.mod` needed no
changes — only additions.

**`go.mod` changes:** added `github.com/golang-jwt/jwt/v5` as a new
direct dependency, and promoted `golang.org/x/crypto` from indirect to
direct (it was already resolved in `go.sum` as a transitive dependency
at v0.23.0 — same version, now just used directly for `bcrypt`). One
action needed on your end: run `go mod tidy` once after pulling this,
since `golang-jwt/jwt/v5` is a new module not yet in `go.sum` — this is
a normal one-time step, not an error.

**New: `POST /auth/resend-otp`.** Found while reviewing the actual
Flutter code (see API contract review below) — the OTP screen already
has a "Resend Code" button wired for a future API call that didn't
exist yet. Added `internal/auth/service.go`'s `ResendOTP`, with a
60-second per-identifier cooldown (via Redis `SETNX`) to prevent abuse,
consistent with the rate-limiting principle from the original security
plan. Documented in both the Postman collection and `docs/openapi.yaml`.

**New: `docs/API_CONTRACT_REVIEW.md`.** A real review of all 5 (now 6)
backend endpoints against Member 1's actual Flutter screens — not just
the original plan. Findings: field names and validation rules are
compatible as-is; one integration TODO flagged for Member 1 (the
register→OTP screen needs to pass the real identifier instead of a
hardcoded placeholder); two UI elements (forgot password, Google
sign-in) have no backend support and shouldn't be wired to anything
yet.

**Files changed/added in this merge, on top of the actual repo:**
- `internal/auth/` (entire package — register, verify-otp, resend-otp,
  login, refresh, logout)
- `internal/otp/` (entire package, now with resend cooldown)
- `internal/models/device.go`, `internal/models/refresh_token.go`, and
  an updated `internal/models/user.go`
- `internal/config/config.go` — added `JWTSecret`
- `internal/server/server.go`, `cmd/api/main.go` — wire everything up
- `migrations/000002_*`, `migrations/000003_*`
- `.env.example` — added `JWT_SECRET`
- `postman/WhatsApp_Clone_Auth.postman_collection.json`
- `docs/openapi.yaml`, `docs/API_CONTRACT_REVIEW.md`

**Your steps:**
```bash
go mod tidy       # picks up golang-jwt/jwt/v5
make migrate-up   # applies 000002 and 000003
cp .env.example .env   # if not already done — picks up JWT_SECRET
make run
```
Then run the Postman collection (updated with the new resend-otp
request) end to end.

**Checkpoint status:** ⬜ Pending your local verification.

**Next up (Week 3, Day 1):** Build the JWT authentication middleware
that protects routes going forward.


---

## Week 3, Day 1 — JWT Authentication Middleware

**Goal (from schedule):** Add JWT middleware to Gin that validates the
Authorization header on protected routes. Checkpoint (shared with
Member 1): ApiClient successfully calls /health with an auth header
attached.

**Note on scope:** today's Flutter-side task (add Dio, build an
ApiClient with interceptors) isn't mine to build — this entry covers
Member 2's half only: the middleware itself, plus a protected route
for Member 1 to actually test their new ApiClient against once it
exists.

**What's included in today's package:**
- `internal/middleware/auth.go` — new package. `RequireAuth(jwtSecret)`
  returns Gin middleware that:
  1. Rejects requests with no `Authorization` header (`401`,
     `AUTH_HEADER_MISSING`).
  2. Rejects malformed headers not in the exact `Bearer <token>` form
     (`401`, `AUTH_HEADER_MALFORMED`).
  3. Validates the JWT using the same `auth.ParseAccessToken` built on
     Week 2 Day 3 — distinguishes an **expired** token
     (`TOKEN_EXPIRED`) from any other invalid token (`TOKEN_INVALID`),
     so the client can tell "refresh your token" apart from "something
     is actually wrong."
  4. On success, stores `user_id`/`device_id` in the Gin context so
     any handler behind this middleware can read who's making the
     request — this is what Week 4's `GET /users/me` will rely on.
- `internal/server/server.go` — registers `GET /health/protected`
  behind `RequireAuth`, purely as a test route for today's checkpoint.
  It intentionally does **not** protect the real `/health` — that
  needs to stay open for uptime monitors/load balancers, which don't
  carry user JWTs.
- `postman/WhatsApp_Clone_Auth.postman_collection.json` — two new
  requests: one hitting `/health/protected` with `{{access_token}}`
  attached (expect `200`), one without any token (expect `401`,
  `AUTH_HEADER_MISSING`).
- `docs/openapi.yaml` — documents `/health/protected` and introduces
  the `bearerAuth` security scheme actually being used now.

**Your steps to test this:**

```bash
make run
```
1. Run the Postman collection through Login (captures `access_token`).
2. Run "Health Check (Protected - needs auth header)" → expect `200`
   with `authenticated_as.user_id` matching the user you logged in as.
3. Run "Health Check (Protected - no token, expect 401)" → expect
   `401`, `AUTH_HEADER_MISSING`.
4. Optional manual check — edit one character of a valid
   `access_token` and resend → expect `401`, `TOKEN_INVALID`.

**For Member 1 (once your ApiClient exists):** point it at
`GET {{base_url}}/health/protected` with your interceptor attaching
`Authorization: Bearer <token>` — that's today's actual shared
checkpoint.

**Checkpoint status:** ⬜ Pending your local verification.

**Next up (Week 3, Day 2):** Test the middleware against a protected
test route; confirm it rejects missing/invalid tokens (Member 1
connects the Register screen to the real API this same day).

---

## Week 3, Day 2 — Testing the Middleware

**Goal (from schedule):** Test the middleware against a protected test
route; confirm it rejects missing/invalid tokens. Checkpoint (shared):
Register screen creates a real account through the live API (Member 1's
half — connecting the Register screen to `/auth/register`).

**What's included in today's package:**
- `internal/middleware/auth_test.go` — real, automated Go tests
  (`go test ./...` picks these up automatically via the `make test`
  target from Week 1). Beyond what Postman covered on Day 1, this adds
  cases Postman can't easily produce without hand-crafting a JWT:
  - Header present but missing the `Bearer` prefix
  - `Bearer` with an empty token
  - A structurally invalid token
  - **A token signed with the wrong secret** (simulates a forged/
    tampered token)
  - **A genuinely expired token** (built with a past `exp` claim, not
    just "wait 15 minutes and see") — confirms it gets the distinct
    `TOKEN_EXPIRED` code, not just `TOKEN_INVALID`
  - A valid token, confirming both a `200` and that `user_id`/
    `device_id` land correctly in the request context — not just "the
    middleware didn't reject it," but "the right identity came through,"
    since Week 4's `GET /users/me` depends on that being correct.

**Why real Go tests instead of only more Postman requests:** Postman
is the right tool for "does the end-to-end HTTP flow work" (Day 1's
job). It's the wrong tool for adversarial edge cases like a wrong-secret
or already-expired token — those need to be constructed directly, and
a test suite that runs in CI going forward (see Week 8) catches
regressions here automatically instead of relying on someone
remembering to re-test manually.

**Your steps to test this:**

```bash
go mod tidy   # if you haven't since Day 1's middleware was added
make test
```
Expected: all tests pass, e.g.
```
--- PASS: TestRequireAuth (0.00s)
    --- PASS: TestRequireAuth/missing_Authorization_header_is_rejected
    --- PASS: TestRequireAuth/header_without_Bearer_prefix_is_rejected
    ... (7 subtests total)
--- PASS: TestRequireAuth_SetsContextValues (0.00s)
PASS
```

**Checkpoint status:** ⬜ Pending your local verification.

**Next up (Week 3, Day 3):** Refine token expiry handling and
standardize error codes (`INVALID_OTP`, `OTP_EXPIRED`, etc.) — Member 1
connects the OTP Verification screen to `/auth/verify-otp` this same
day.

---

## Week 3, Day 3 — Refined Expiry Handling + Standardized Error Codes

**Goal (from schedule):** Refine token expiry handling and standardize
error codes (INVALID_OTP, OTP_EXPIRED, etc.). Checkpoint (shared): OTP
verification screen works end-to-end against the real backend
(Member 1's half — connecting the OTP screen to `/auth/verify-otp`).

**What "refine token expiry handling" actually meant here:**
`otp.Service.Verify` previously returned one combined error
(`ErrInvalidOrExpired`) for two different situations: a wrong code,
and a code that genuinely expired (or was never requested). These are
now split:
- Redis key gone entirely → `otp.ErrExpired` → `OTP_EXPIRED`
- Redis key present but hash doesn't match → `otp.ErrInvalidCode` →
  `INVALID_OTP`

This doesn't weaken brute-force protection — the 5-attempt cap applies
identically either way — it just gives an accurate message ("your code
expired, request a new one" vs. "that's the wrong code, try again").

**What "standardize error codes" meant, done as a full pass, not just
OTP:** every error response across all 6 endpoints now has the same
shape: `{"error": "...", "code": "MACHINE_READABLE_CODE"}`, including
several that previously had no `code` at all (register's
`IDENTIFIER_REQUIRED`/`IDENTIFIER_TAKEN`, every endpoint's validation
failures now say `VALIDATION_ERROR`, every internal failure now says
`INTERNAL_ERROR`, every "user not found" edge case now says
`USER_NOT_FOUND`). Full reference table added to the top of
`docs/openapi.yaml`.

**Files changed:**
- `internal/otp/service.go` — `ErrInvalidOrExpired` split into
  `ErrInvalidCode` / `ErrExpired`.
- `internal/auth/service.go` — updated error aliases
  (`ErrInvalidOTP`/`ErrOTPExpired`) to match.
- `internal/auth/handler.go` — full rewrite of every error branch
  across all 6 handlers for consistent `code` fields (see file header
  comment for the exact contract now in place).
- `postman/WhatsApp_Clone_Auth.postman_collection.json` — added
  request "1b. Verify OTP with wrong code" **positioned correctly
  before the real verify consumes the code** (a wrong-code test placed
  after a successful verify would hit `OTP_EXPIRED` instead of
  `INVALID_OTP`, since the code would already be deleted — caught this
  ordering issue myself while building it, fixed before packaging).
- `docs/openapi.yaml` — full error code reference table added to the
  spec description; updated verify-otp response docs; version bumped
  to 0.3.0.

**Your steps to test this:**

```bash
make run
```
Run the Postman collection in order — the new "1b" request should
return `400` with `code: "INVALID_OTP"`, then request "2" (the real
code) should still succeed normally (the wrong attempt just counts
toward the 5-attempt budget, doesn't block it).

To see `OTP_EXPIRED` specifically: register a new user, wait 5+
minutes without verifying, then attempt verify-otp — expect `400`,
`code: "OTP_EXPIRED"`.

**Checkpoint status:** ⬜ Pending your local verification.

**Next up (Week 3, Day 4):** Implement session validation logic used
by the middleware — Member 1 connects the Login screen to
`/auth/login` and stores tokens via `flutter_secure_storage` this same
day.

---

## Week 3, Day 4 — Session Validation Logic

**Goal (from schedule):** Implement session validation logic used by
the middleware. Checkpoint (shared): logging in stores the JWT
securely on the device (Member 1's half — Login screen +
flutter_secure_storage).

**The gap this closes:** the middleware (Day 1) only ever checked that
a JWT was cryptographically valid and unexpired. It never checked
whether the *session* behind that token was still supposed to be
valid. Since access tokens live 15 minutes, logging out (Week 2 Day 5,
which revokes the device row) didn't actually stop a still-unexpired
token from working for up to 15 more minutes. That's the real "session
validation logic" this day is about.

**What's included in today's package:**
- `internal/middleware/auth.go` — added a `DeviceChecker` interface
  (`IsDeviceActive(ctx, deviceID) (bool, error)`) and its real
  implementation, `GormDeviceChecker`, backed by the `devices` table.
  `RequireAuth` now takes a `DeviceChecker` as a second argument and,
  after validating the JWT itself, confirms the token's device is
  still `active` — rejecting with `401 SESSION_REVOKED` if not.
  Defined as an interface specifically so tests don't need a real
  database (see below).
- `internal/server/server.go` — wires up `middleware.NewGormDeviceChecker(database)`
  once in `Server`, reused by every protected route going forward.
- `internal/middleware/auth_test.go` — added `fakeDeviceChecker` (no
  DB needed at all) and two new cases: a valid token whose device is
  revoked (`SESSION_REVOKED`), and a device-check failure surfacing as
  `500 INTERNAL_ERROR` rather than silently letting the request through.
- `postman/WhatsApp_Clone_Auth.postman_collection.json` — added
  request "6. Health Check (Protected) after Logout", demonstrating
  the actual feature: the same access token that worked right after
  login gets `401 SESSION_REVOKED` right after logout, despite still
  being unexpired.

**A real ordering bug caught before packaging:** the two existing
protected-route Postman requests were positioned *after* Refresh and
Logout in the collection. Since Logout now revokes the device, running
the full collection top-to-bottom would have made the "should succeed"
protected-route request unexpectedly fail. Reordered them to run right
after Login instead (renamed "3b"/"3c" to reflect the new position),
before Refresh/Logout touch the session at all. Verified the new
"after logout" request still works correctly even though Refresh (which
runs before Logout) rotates the access token in between — Refresh
issues a new token for the *same* device, so Logout still revokes it.
- `docs/openapi.yaml` — documented `SESSION_REVOKED` in both the error
  code table and the `/health/protected` endpoint description.

**Your steps to test this:**

```bash
make test    # confirms the new middleware unit tests pass
make run
```
Run the Postman collection in full order. Request "3b" should succeed
(`200`) right after login; request "6" (after Logout) should fail with
`401 SESSION_REVOKED` using what's still a structurally valid,
unexpired token.

**Checkpoint status:** ⬜ Pending your local verification.

**Next up (Week 3, Day 5):** Code review the backend auth module
together with Member 1 (Member 1 adds a GoRouter auth guard so
logged-in users skip Login and land on Home). Checkpoint: the app
remembers login state after a restart.

---

## Week 3, Day 6 (milestone, together) — Gate Check 1

**Goal (from schedule):** Full manual test together: Register → OTP →
Create Password → Login → Home screen, on a real device/emulator.
Checkpoint: GATE CHECK 1 PASSED — authentication works fully
end-to-end.

**Backend readiness confirmed today:** re-ran the full structural
verification suite (brace/paren balance, no duplicate declarations, no
clipped comments) across all 16 Go files, 6 migrations, and the one
test file — all clean. Every route from the original 5+1 endpoint plan
is registered and wired to the middleware correctly (see the route
list in `internal/server/server.go`).

**What's added today:** `docs/GATE_CHECK_1_TEST_SCRIPT.md` — a
step-by-step walkthrough for the actual joint manual test, covering
Register → OTP (including a deliberate wrong-code attempt) → Login →
the real Day 4 checkpoint (token persists across an app restart) →
Logout, with a Postgres query at each step so you can verify backend
state matches what the app shows on screen, not just trust the UI.

**Open question flagged in the script:** the schedule lists "Create
Password" as its own step in the flow. The backend has one
`POST /auth/register` call (name + phone/email + password together) —
there's no separate "create account" then "set password" pair of
endpoints. If Flutter's UI has a distinct Create Password *screen*
that's fine (multi-step form, one final submit), but if it was
expected to be a second API call, that's a design conversation to have
before running the rest of the script.

**This is a joint milestone day, not a solo backend day** — today's
real work is doing the walkthrough together and marking off the
checklist honestly, not writing more code. If any step breaks, note
exactly where and that becomes the next concrete fix, not a failure of
the process.

**Checkpoint status:** ⬜ GATE CHECK 1 — pending the actual joint
walkthrough.

**Next up (Week 4, Day 1):** Build `GET /users/me` to return the
logged-in user's real data (Member 1 builds the Profile screen UI this
same day).

---

## Bug Fix — UUID Type Mismatch in Registration

**Reported by Taha AK:** `POST /auth/register` failed with
`ERROR: invalid input syntax for type uuid: ""`.

**Root cause (mine to own, not a misunderstanding on the report's
part):** the `users.id` column is `UUID PRIMARY KEY DEFAULT
gen_random_uuid()`, but every model (`User.ID`, `Device.ID`,
`RefreshToken.ID`, plus the `UserID`/`DeviceID` foreign key fields)
was typed as plain Go `string`. GORM only knows to omit a blank
primary key and let a database-side `DEFAULT` apply if GORM itself is
told about that default — either via an explicit `gorm:"default:..."`
tag, or by having created the table itself via `AutoMigrate`. This
project deliberately never uses `AutoMigrate` (schema is owned
entirely by the SQL migration files, so it can't silently drift), and
no `default:` tag was ever added. So GORM had no way to know the
column had a default — it just saw a Go string at its zero value
(`""`) and dutifully sent exactly that as the literal value to insert,
which Postgres correctly rejected as invalid UUID syntax. This was a
real gap in earlier verification: I checked that everything compiled
and that queries/types lined up structurally, but never actually
traced GORM's specific behavior for a blank primary key against a
DB-side default it doesn't know about — an assumption I stated
earlier as fact without having verified it.

**The fix:** rather than the minimal patch (add a `default:` tag and
hope GORM's default-detection kicks in correctly), every ID field
across `User`, `Device`, and `RefreshToken` is now `uuid.UUID`
(`github.com/google/uuid`), and each model has an explicit
`BeforeCreate` hook that generates a real UUID in Go code before every
insert:
```go
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}
```
This removes any dependency on GORM's default-detection heuristics
entirely — there's no "hope it works," the value is always explicitly
set before GORM ever builds the INSERT statement.

**Why this didn't cascade into "many files fail to compile"** (the
problem hit when this was first attempted manually): `uuid.UUID` is
kept scoped to the database/model layer only. At the two places IDs
cross a serialization boundary — JWT claims and JSON API responses —
they're converted explicitly with `.String()`. Internally (model → DB
query, model → model field assignment), the types already match
directly with zero conversion needed, since e.g. `Device.UserID` and
`User.ID` are now both `uuid.UUID`. Total footprint: 3 model files
rewritten, 5 `.String()` conversions added (2 in `service.go`'s
`generateAccessToken` calls, 3 in `handler.go`'s response construction),
zero changes to `internal/middleware/`, zero changes to
`auth_test.go`, zero changes to the JSON API contract (every response
field is still a plain string `"id"` — Flutter needs no changes at
all), zero changes to the SQL migrations (the schema was already
correct; this was purely a Go-side bug).

**Files changed:**
- `internal/models/user.go`, `device.go`, `refresh_token.go` — `uuid.UUID` + `BeforeCreate`
- `internal/auth/handler.go` — 3 `.String()` conversions on response construction
- `internal/auth/service.go` — 2 `.String()` conversions on `generateAccessToken` calls
- `go.mod` — added `github.com/google/uuid`

**Your steps:**
```bash
go mod tidy   # fetches github.com/google/uuid, one-time step
make run
```
Then re-run the Postman collection's Register request — should now
return `201` with a real UUID in `id`, and:
```bash
psql whatsapp_clone -c "SELECT id, phone_number, account_status FROM users ORDER BY created_at DESC LIMIT 1;"
```
should show a properly generated UUID, not an error.

---

## Week 4, Day 1 — GET /users/me

**Goal (from schedule):** Build GET /users/me to return the logged-in
user's real data. Checkpoint (shared): Profile screen shows the
logged-in user's real data.

**Reviewed the actual current Flutter code first** (not just the plan)
since real networking code now exists. Findings, and what they mean
for today's work, are in `docs/API_CONTRACT_REVIEW.md` under "Week 4,
Day 1 update" — short version: `profile_screen.dart` already has a
comment saying exactly what to build (`// We will replace these with
GET /users/me data`), confirming the field names needed (`name`,
`about`, `phone_number`, `email`). Also found two Flutter-side issues
worth fixing before this can actually work end-to-end (not backend
problems, just flagging): the auth interceptor sends an always-empty
bearer token, and `LoginResponse` expects a `message` field the
backend never sends.

**What's included in today's package:**
- `internal/users/` — new package, following the same
  service/handler split as `internal/auth`:
  - `service.go` — `GetByID` looks up a user by UUID (parses the
    string ID from the JWT claim; a parse failure is treated as "not
    found" rather than a crash, since a malformed ID can never
    correspond to a real row).
  - `handler.go` — `Me` reads the user ID from
    `middleware.ContextUserIDKey` (never from a query param or
    request body — only from the verified JWT) and returns the
    profile.
  - `dto.go` — `MeResponse`, field-matched exactly to what
    `profile_screen.dart` expects. One deliberate naming choice: JSON
    key is `about`, not `about_text` (the DB column name) — shorter,
    and matches the Flutter screen's own `_about` variable.
- `internal/server/server.go` — new `/users` route group, with
  `RequireAuth` applied once at the group level (`usersGroup.Use(...)`)
  rather than repeated per-route — the first time this project uses
  that pattern; every future route added to this group is
  automatically protected.
- `postman/WhatsApp_Clone_Auth.postman_collection.json` — added
  request "3d. GET /users/me", positioned (per the Day 4 lesson) right
  after Login while the session is still active, before
  Refresh/Logout touch it.
- `docs/openapi.yaml` — documented `/users/me`, bumped to 0.4.0.

**No new dependencies, no new migrations** — `users` package only
needed `gorm.io/gorm` and `github.com/google/uuid`, both already in
`go.mod` from earlier days.

**Your steps to test this:**

```bash
make run
```
Run the Postman collection through Login, then run "3d. GET
/users/me" → expect `200` with your real `id`, `name`,
`phone_number`/`email`, `about` (likely `null` — nothing sets it yet,
that's expected until a profile-edit endpoint exists), `created_at`.

**Checkpoint status:** ⬜ Pending your local verification — and
depends on the two Flutter-side items in the contract review being
fixed first, or every request will 401.

**Next up (Week 4, Day 2):** Build `GET /users/search?phone=` or
`?email=` — Member 1 builds the User Search screen UI this same day.
Checkpoint: searching for a phone number/email returns a matching user
in Postman.
