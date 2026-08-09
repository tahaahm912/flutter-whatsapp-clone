# API Contract Review — Backend (Week 2) vs. Flutter (Week 1-2)

Reviewed against the actual code in `mobile/lib/features/auth/` from
the shared repo, not just the original plan. This is the "API contract
review" task from the Week 2 schedule.

## Summary

Backend and frontend are compatible as-is for the fields Flutter
currently collects. One real gap was found and fixed (resend OTP).
One integration TODO is flagged for Member 1, not a backend problem.

## Screen-by-screen findings

### Register screen (`register_screen.dart`)
Collects: `name`, `email`, `password`, `confirm_password` (client-side only).

- Backend's `POST /auth/register` accepts `name`, `phone_number`
  (optional), `email` (optional, at least one required), `password`.
  Since Flutter only ever sends `email`, `phone_number` will simply be
  omitted from the request — already handled correctly (it's optional
  on the backend).
- `confirm_password` is validated client-side only and should **never**
  be sent to the API — correct as currently built. Nothing to change.
- Name minimum length: Flutter requires 3+ chars client-side; backend
  requires 2+ chars. No conflict — Flutter's stricter rule just means
  the backend's rule is never the binding one in practice.
- Password minimum length: both require 8+ chars. Matches.

**Action needed on the Flutter side (Week 3, not now):** the Sign Up
button currently just does `context.go('/otp')` with no API call and
no data passed to the OTP screen. When real integration happens, the
`identifier` (the email just entered) needs to be passed to the OTP
screen — currently `otp_screen.dart` hardcodes `email = "abc123@gmail.com"`
with a comment `// Later this will come from Register Screen`. This is
purely a Flutter-side wiring task, not a backend gap — flagging it now
so it isn't a surprise in Week 3.

### OTP screen (`otp_screen.dart`)
Collects: a 6-digit code via `Pinput`. Has a **"Resend Code" link**
already in the UI, with a comment `// Week 3: Call Resend OTP API`.

- **Gap found and fixed today:** there was no resend endpoint. Added
  `POST /auth/resend-otp` (see `internal/auth/service.go` `ResendOTP`,
  and the updated Postman collection / OpenAPI doc). Includes a 60
  second cooldown per identifier to prevent abuse, matching the
  original security plan's rate-limiting principle.
- Code length: Flutter's `Pinput` is configured for `length: 6`;
  backend's `VerifyOTPRequest.Code` requires exactly 6 numeric
  characters. Matches.

### Login screen (`login_screen.dart`)
Collects: `email`, `password`. Also has an unwired "Forgot password?"
link and a "Continue with Google" button (both no-ops currently).

- Backend's `POST /auth/login` accepts `identifier` (works with either
  phone or email), `password`, plus optional `device_name`/`platform`.
  Flutter doesn't send the optional fields — fine, they default to
  `"Unknown device"` / `"web"` server-side.
- **Not yet backed:** "Forgot password?" and "Continue with Google"
  have no corresponding backend endpoints. These aren't in the Week 2
  plan at all — flagging so they're not assumed to exist when Member 1
  wires up Week 3. Password reset in particular touches the same OTP
  infrastructure and would be a reasonable Week 3+ addition if wanted.

### Splash / Home screens
Fully static, no API expectations. Nothing to review.

## Field naming reference (for whoever wires the HTTP client in Week 3)

All request/response field names are `snake_case` JSON, matching Dart's
typical `json_serializable` conventions:

| Backend field | Type | Notes |
|---|---|---|
| `phone_number` | string, E.164 | optional on register |
| `email` | string | optional on register, required in practice (Flutter only collects email) |
| `password` | string | 8-72 chars |
| `identifier` | string | used for login/verify/resend — same value as whichever of phone/email was used to register |
| `code` | string | exactly 6 digits |
| `access_token` / `refresh_token` | string | from login/refresh |
| `device_name` / `platform` | string | optional, login only |

Full request/response shapes with examples: see `docs/openapi.yaml`
(importable into Swagger Editor) and the Postman collection.

## Recommendation

No backend changes are blocking Flutter's current (static) screens.
Before Week 3 wiring begins, Member 1 should know:
1. The register→OTP screen needs to actually pass the identifier along
   (currently hardcoded).
2. `POST /auth/resend-otp` now exists and is documented.
3. Forgot-password and Google sign-in have no backend support yet —
   don't wire buttons to endpoints that don't exist.

---

## Week 4, Day 1 update — reviewed against the real Week 3 networking code

Member 1's networking layer now exists (`core/network/`,
`features/auth/data/`) — reviewed against the actual code, not just
the plan. Two things worth fixing on the Flutter side (not backend
issues, flagging for whoever owns that code next):

1. **`AuthInterceptor.onRequest` hardcodes an empty token:**
   ```dart
   options.headers["Authorization"] = "Bearer ";
   ```
   This never reads the real token from `SecureStorage`. As of today,
   `GET /users/me` and any future protected route requires a real
   token — with this as-is, every protected request will fail with
   `401 AUTH_HEADER_MALFORMED` (an empty string after `Bearer ` fails
   the middleware's format check). Needs to become something like
   `options.headers["Authorization"] = "Bearer \${await SecureStorage().getAccessToken()}"`.

2. **`LoginResponse.fromJson` expects a `message` field that the
   backend never sends**, and doesn't parse the `user` object at all:
   ```dart
   message: json["message"] ?? "",
   ```
   Harmless today (defaults to `""`, no crash), but worth knowing:
   the backend's actual login response shape is `access_token`,
   `refresh_token`, `token_type`, `expires_at`, and a `user` object
   (`id`, `name`, `phone_number`, `email`) — no `message` field exists.
   Since `GET /users/me` (below) now exists as its own call, this
   likely doesn't matter — the intent seems to be "fetch profile
   separately" rather than "get it from login" — just confirming
   that's the intended design, not an oversight.

## New: GET /users/me

Added today specifically because `profile_screen.dart` already has
this exact comment:
```dart
// Temporary profile data.
// We will replace these with GET /users/me data.
```
Response fields map directly to that screen's fields: `name` → `_name`,
`about` → `_about`, `phone_number` → `_phone`, `email` → `_email`.
Requires `Authorization: Bearer <access_token>` — see points 1 above
before wiring this up, or every call will 401.
