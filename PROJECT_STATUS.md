# SickleCare Project Status

**Updated:** 6 November 2026
**Flutter app:** `sicklecare_frontend/`
**Firebase backend:** `sicklecare_backend/`

## Current state

- Flutter tracker entries sync under `users/{uid}/tracker_entries`; backend health validation, analytics, exports, and reports use the same schema.
- Admin UI visibility is based on the Firebase Auth ID-token `admin` custom claim. Firestore and Storage rules also enforce trusted claims; client profile roles are not trusted.
- `askSika` is implemented as an authenticated, App Check-protected callable. It uses a server-side Groq secret and excludes tracker/profile data from the request.
- The mobile `AdminScreen` edits home content and views support messages. There is no separate web admin dashboard.
- Reminders remain local to the device; FCM token registration/cloud push is not integrated.
- Account deletion has backend cleanup for known user data and Storage paths. The deployed trigger has not been verified.

## Verification

- Backend TypeScript build, ESLint, and Jest tests passed (10 tests).
- Flutter analysis and widget tests passed.
- Firestore, Storage, and Auth rules loaded in the local Firebase Emulator Suite. No Firebase deployment or production-project query was performed.
- Android debug APK built successfully for local testing; it is not a Play Store release.

## Not yet verified or implemented

- Provisioning/revoking production admin claims, deployed rules/functions/indexes, production App Check, and external Groq connectivity.
- Cloud FCM token lifecycle and delivery.
- A web admin console.
- Email delivery, PDF reports, and recoverable user-data backups (current reports are JSON; backups are metadata only).
- Migration of legacy `users/{uid}/health` records into `tracker_entries`.
- Deployed account-erasure execution, iOS builds, and real-device workflows.

See [BACKEND_AUDIT_REPORT.md](BACKEND_AUDIT_REPORT.md) and [FRONTEND_BACKEND_INTEGRATION.md](FRONTEND_BACKEND_INTEGRATION.md) for details.
