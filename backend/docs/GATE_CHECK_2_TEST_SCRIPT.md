# Gate Check 2 — Manual Test Script (Week 4, Day 6)

**Goal:** confirm two real, separate accounts — on two real
devices/emulators — can find each other and successfully exchange
Signal Protocol public keys, entirely through the app, no Postman.

Run this together. You'll need two phones/emulators and two different
phone numbers or emails.

## Prerequisites

- [ ] Backend running (`make run`), `/health` returns `200`
- [ ] Both devices/emulators can reach the backend (same LAN IP or
      tunnel — not `localhost` if testing on two separate physical
      devices)
- [ ] The two auth bugs from `README.md`'s "Bugs to fix" section are
      actually fixed — this gate check calls `/users/search` and
      `/users/keys`, both protected routes; if the interceptor still
      sends an empty token, nothing here will work at all
- [ ] Both of you can see the backend's console log (for OTP codes)

## The walkthrough

Call the two accounts **Account A** and **Account B** throughout.

### 1. Create both accounts
- [ ] Register Account A (Device 1): Register → OTP → Login → Home
- [ ] Register Account B (Device 2): same steps, different
      phone/email
- [ ] Confirm both in Postgres:
      ```sql
      SELECT name, phone_number, email, account_status FROM users ORDER BY created_at DESC LIMIT 2;
      ```
      Both should show `active`.

### 2. Both accounts upload their keys
- [ ] If Day 3-5's Flutter work auto-uploads keys right after
      registration (that was the Day 5 checkpoint), this should have
      already happened for both — confirm rather than assume:
      ```sql
      SELECT d.id AS device_id, u.name
      FROM devices d JOIN users u ON u.id = d.user_id
      ORDER BY d.created_at DESC LIMIT 2;

      SELECT device_id, registration_id FROM signal_identity_keys;
      SELECT device_id, key_id, is_active FROM signal_signed_prekeys WHERE is_active;
      SELECT device_id, count(*) AS unused_prekeys FROM signal_one_time_prekeys WHERE is_used = false GROUP BY device_id;
      ```
- [ ] Both devices should have exactly one row in
      `signal_identity_keys`, at least one active row in
      `signal_signed_prekeys`, and a non-zero count of unused
      one-time pre-keys.
- [ ] If either is missing, that's the actual blocker for this gate
      check — go back and fix the auto-upload step before continuing.

### 3. Account A searches for Account B
- [ ] On Device 1, use the User Search screen to search for Account
      B's phone number or email
- [ ] Confirm: Account B's name/about/photo appear (not their phone
      number or email — the search response deliberately excludes
      those, see `docs/API_CONTRACT_REVIEW.md` if this looks like a
      bug, it isn't)
- [ ] Try searching for a phone number that doesn't exist — confirm
      the app shows a real "not found" state, not a crash

### 4. Account A fetches Account B's key bundle
- [ ] From the search result (or wherever this is wired up), trigger
      the key-bundle fetch for Account B
- [ ] Confirm: the app receives `identity_key`, `signed_prekey`, and
      (probably) a `one_time_prekey`
- [ ] **Immediately check Postgres** — one of Account B's one-time
      pre-keys should now show `is_used = true`:
      ```sql
      SELECT key_id, is_used, used_at FROM signal_one_time_prekeys
      WHERE device_id = '<account B device id>' ORDER BY used_at DESC LIMIT 1;
      ```
      This is the real proof the atomic claim logic from Day 4 works
      end-to-end, not just in isolation.

### 5. Do it in reverse
- [ ] Account B searches for and fetches Account A's key bundle too —
      a real chat needs both directions eventually, and this confirms
      the flow isn't accidentally one-directional

### 6. Repeat the fetch once more
- [ ] Fetch Account B's bundle a second time
- [ ] Confirm: a **different** one-time pre-key was consumed this
      time (or `one_time_prekey: null` if the batch ran out) — never
      the same key twice. This is the one thing that would be a
      genuine security-critical bug if it failed.

## If something breaks

Note exactly which step, and check both the backend console log and
Postgres state before assuming it's a frontend bug — the queries above
tell you definitively whether the backend did its part correctly.

## Sign-off

- [ ] **GATE CHECK 2 PASSED** — both accounts, on real
      devices/emulators, discovered each other via search and
      successfully exchanged public keys, with one-time pre-keys
      correctly consumed and never reused.

If it doesn't fully pass today, note exactly where it broke — that
becomes the next concrete fix.
