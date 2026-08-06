# Gate Check 1 — Manual Test Script (Week 3, Day 6)

**Goal:** confirm authentication works fully end-to-end: Register → OTP
→ Create Password → Login → Home screen, on a real device/emulator,
with the real backend, no mocking on either side.

Run this together, out loud, one step at a time — that's the point of
a milestone day.

## Prerequisites

- [ ] Backend running (`make run`), `/health` returns `200`
- [ ] Postgres and Redis both reachable (check `/health`'s
      `database`/`redis` fields)
- [ ] Flutter app running on a real device or emulator, pointed at the
      backend's actual address (not `localhost` if testing on a
      physical device on the same network — use your machine's LAN IP)
- [ ] Both of you can see the backend's console log (needed to read
      the OTP code — there's no SMS/email provider yet, by design,
      see the original build plan)

## Note on "Create Password" as a separate screen

The schedule lists this as its own step in the flow. The backend has
one `POST /auth/register` call that takes name + phone/email +
password together — there's no separate "create the account" then
"set the password later" pair of endpoints. If your Flutter flow has
a distinct "Create Password" *screen*, it should still be collecting
that password locally and sending everything in one `/auth/register`
call at the end, not making two separate API calls. Worth confirming
this matches what's actually built before testing — if it doesn't,
that's a design conversation to have before running the rest of this
script, not a bug to route around.

## The walkthrough

### 1. Register
- [ ] Open the app fresh (uninstall/reinstall if you want a truly
      clean state), go through Register with a real, new phone number
      or email
- [ ] Confirm: no crash, no stuck loading spinner, a clear transition
      to the OTP screen
- [ ] Check the backend console: a line like `[DEV ONLY] OTP for
      ... is: 123456` should appear
- [ ] In Postgres, confirm the row exists and is `pending_verification`:
      ```sql
      SELECT phone_number, email, account_status FROM users ORDER BY created_at DESC LIMIT 1;
      ```

### 2. OTP Verification
- [ ] Enter the code from the console into the app
- [ ] Confirm: success state shown, transition to Login (or straight
      to Home, if your flow auto-logs-in after verification — confirm
      which one is actually intended)
- [ ] Try entering a wrong code first (before the real one) — confirm
      the app shows a real error, not a generic crash/blank state
- [ ] Confirm in Postgres: `account_status` is now `active`

### 3. Login
- [ ] Log in with the same credentials just created
- [ ] Confirm: app transitions to Home
- [ ] On the backend: confirm a new row exists in `devices` and
      `refresh_tokens` for this login

### 4. Token storage (the actual Day 4 checkpoint)
- [ ] Fully close/kill the app (not just background it)
- [ ] Reopen it
- [ ] Confirm: it goes straight to Home, **no re-login required** —
      this is the real proof `flutter_secure_storage` is working and
      the GoRouter auth guard (Day 5) is redirecting correctly

### 5. Logout (bonus, not in the original script, but worth doing since it's built)
- [ ] Log out from the app
- [ ] Confirm: back at Login, and closing/reopening the app does NOT
      skip back to Home this time
- [ ] On the backend: confirm that device's `status` is now `revoked`
      and its `refresh_tokens` row has `revoked_at` set

## If something breaks

Note exactly which step, what you expected vs. what happened, and any
error shown on-screen or in either console. That's more useful for
debugging together than "OTP didn't work."

## Sign-off

- [ ] **GATE CHECK 1 PASSED** — all steps above completed successfully
      on a real device/emulator, by both of you, together.

If it doesn't fully pass today, that's normal for a first end-to-end
run — note exactly where it broke and that becomes the next thing to
fix, not a failure of the milestone process itself.
