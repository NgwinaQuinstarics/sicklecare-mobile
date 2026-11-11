# SickleCare Project Status

**Updated:** 11 November 2026
**Flutter app:** `sicklecare_frontend/`
**Firebase backend:** `sicklecare_backend/`

## Current state

- Flutter tracker entries sync under `users/{uid}/tracker_entries`; backend health validation, analytics, exports, and reports use the same schema.
- Admin UI visibility is based on the Firebase Auth ID-token `admin` custom claim. Firestore and Storage rules also enforce trusted claims; client profile roles are not trusted.
- `askSika` is implemented as an authenticated, App Check-protected callable. It uses a server-side Groq secret and excludes tracker/profile data from the request.
- The mobile admin screen and Firebase Hosting web console use trusted admin claims. The web console provides a live summary, paginated account directory, support/contact inbox with status filters, home-content editor, and audit activity view.
- Admin content and inbox status changes use rate-limited backend callables that validate input and create append-only audit events. The user directory can fetch allowlisted profile fields and paginated, synced health tracker records through an admin-only read callable; each page view creates a metadata-only audit event.
- Reminders remain local to the device; FCM token registration/cloud push is not integrated.
- Account deletion has backend cleanup for known user data and Storage paths. The deployed trigger has not been verified.

## Verification

- Backend TypeScript build, ESLint, and Jest tests passed (54 tests including admin authorization and request validation).
- Admin dashboard strict TypeScript check and production build passed; npm audit reports zero vulnerabilities.
- Flutter analysis passed after routing the in-app admin editor through the audited callable.
- Backend and admin dashboard builds pass; all 54 Functions tests pass. Firestore rules compile in the Firebase CLI dry run.
- Firebase CLI confirms there are currently no deployed Cloud Functions in `sicklecare-15d7a`. A targeted production dry run was blocked because the project is not on the Blaze plan and Cloud Build cannot be enabled. No Functions, rules, Hosting, or production user records were deployed/read.
- Android debug APK built successfully for local testing; it is not a Play Store release.

## Not yet verified or implemented

- Deploying the admin callables, Firestore rules, and Hosting app. Cloud Functions deployment requires Blaze; see `sicklecare_backend/BACKEND_SETUP.md`.
- Production App Check, external Groq connectivity, and scheduled jobs.
- Cloud FCM token lifecycle and delivery.
- Firebase Hosting/custom-domain deployment and real admin-account workflow.
- Email delivery, PDF reports, and recoverable user-data backups (current reports are JSON; backups are metadata only).
- Migration of legacy `users/{uid}/health` records into `tracker_entries`.
- Deployed account-erasure execution, iOS builds, and real-device workflows.

See [BACKEND_AUDIT_REPORT.md](BACKEND_AUDIT_REPORT.md) and [FRONTEND_BACKEND_INTEGRATION.md](FRONTEND_BACKEND_INTEGRATION.md) for details.
