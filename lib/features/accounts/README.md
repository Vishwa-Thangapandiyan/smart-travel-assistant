# Accounts — REQ-1.1–1.4

Owner: Vishwa · Branch: `flex/accounts` · SRS 4.1 · Record:
[`docs/OWNERSHIP.md`](../../../docs/OWNERSHIP.md)

**Design:** follow [`DESIGN.md`](../../../DESIGN.md); screen picture: `design/screens/night-01-sign-in.png`.

Sign-up, sign-in (including Google), and the user profile. Every other
table keys on `user_id`, so this has to be solid — but nobody waits on it:
until it merges, other features use the fake signed-in user from the
service fakes (see `lib/services/README.md`).

## Tasks

1. Set up the Supabase project and run `db/schema.sql`, then
   `db/seed.sql`, in the SQL Editor. Post the URL and anon key to the
   group chat (see `RUN.md`).
2. Build sign-up and sign-in screens, including Google sign-in. Supabase
   Auth handles password hashing and sessions — none of that is written
   by hand.
3. Close the gap between `auth.users` and `profiles`: Supabase Auth
   creates the `auth.users` row on sign-up but **not** the `profiles` row.
   Insert it right after sign-up (or use a database trigger), using
   `UserProfile` from `lib/models/user_profile.dart` — otherwise the
   profile screen loads empty for every new user.
4. Build the profile screen: full name, default currency, preferences.
5. Map Supabase auth error codes to human-readable inline messages
   (REQ-1.4). Never show a raw `AuthException`.
6. Before release: configure the Google OAuth redirect in the Supabase
   dashboard for the app's real redirect scheme, or Google sign-in breaks
   on a real device.

## Done when

- [x] Sign-up creates both an `auth.users` row and a matching `profiles`
      row — REQ-1.1
- [x] Sign-in works, including Google — REQ-1.1
- [x] Profile screen reads and updates `profiles` via `UserProfile`
      (name, currency, preferences) — REQ-1.2, REQ-1.3
- [x] Auth errors show as human-readable messages — REQ-1.4
- [ ] Tested: email already in use, and a wrong password, both show a
      clear inline message with no crash
