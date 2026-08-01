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
