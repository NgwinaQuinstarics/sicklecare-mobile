# SickleCare Backend Integration Audit

**Updated:** 7 November 2026
**Scope:** Source/configuration review and local build/test verification for the Flutter app and Firebase backend. No production Firebase project, production data, or deployed service was accessed.

## Summary

The Flutter app is in `sicklecare_frontend/`; the TypeScript Cloud Functions and canonical Firebase CLI configuration are in `sicklecare_backend/`. The backend project alias matches the Flutter Firebase project ID (`sicklecare-15d7a`). No Firebase deployment was performed.

The project now includes an in-app Flutter admin screen and a Firebase Hosting web console. The web console provides a summary, paginated Auth account directory, live support/contact inbox, status management, home-content publishing, and recent audit events. It uses Firebase Auth ID-token claims for UI gating and admin-only, rate-limited Cloud Functions for sensitive reads/writes. Firestore and Storage rules also rely on trusted claims; client-editable profile fields are not an authorization source.

## Integration work completed

- Aligned tracker validation, analytics, exports, and JSON reports with the app's `users/{uid}/tracker_entries` schema.
- Added the authenticated, App Check-protected `askSika` callable with bounded input/history, per-user rate limiting, emergency escalation, medication-dose refusal, and server-side Groq secret access.
- Tightened Firestore/Storage authorization and reminder validation; corrected support and report collection rules.
- Improved account-deletion cleanup for known user subcollections, related metadata, analytics, and user Storage files.
- Removed duplicate frontend Firestore deployment configuration; the backend directory is authoritative for Firebase deployment configuration.
- Removed the redundant backend README and updated the root/frontend setup and integration documentation.
- Added four admin callables for dashboard summaries, bounded account listings, audited inbox/content changes, and audit-history reads.
- Restricted direct client writes to home content and inbox records; dashboard changes are validated and audited through the server.
- Routed the Flutter in-app home editor through the same audited content callable.
- Added a responsive React/Vite admin SPA, session-only auth persistence, CSP/security headers, and Firebase Hosting integration.

## Local verification

- Backend TypeScript build, ESLint, and Jest tests passed (45 tests).
- Admin dashboard strict TypeScript check and production build passed; npm audit reports zero vulnerabilities.
- Flutter analysis passed after the in-app admin editor was switched to the audited callable.
- Browser review verified sign-in/access-denied states and responsive desktop/mobile layouts. No production account was used to test data-bearing pages.
- Current Firestore, Storage, and Auth rules loaded in the local Firebase Emulator Suite. The emulator process exited successfully; Java emitted a deprecated-API warning.
- Flutter built the Android debug APK successfully using a temporary local Firebase Android configuration generated from the checked-in FlutterFire options. That ignored config was removed afterward, and the APK is a testing artifact, not a Play Store release.

## Remaining limitations

- No Firebase service was deployed or queried. Production rules, indexes, functions, App Check enforcement, and custom-claim provisioning remain unverified.
- Firebase Hosting domain authorization and deployment are not configured or verified.
- `GROQ_API_KEY` must be provisioned in Firebase Secret Manager and App Check configured before online AI requests can work in a deployed environment.
- Reminders are local-only in Flutter; FCM token registration and cloud push delivery are not integrated.
- Reports are JSON; email delivery is not implemented. Backup handling stores metadata rather than a recoverable data backup.
- Existing legacy `users/{uid}/health` records are not automatically migrated to `tracker_entries`.
- Auth deletion cleanup is source-aligned but has not been exercised against a deployed project.
- No iOS/device runtime validation or clinical safety certification is claimed.

## Operational cautions

Do not treat a successful local build or emulator rule load as evidence of production readiness. Provision trusted admin claims only through an authorized server-side process, review the target project before any deployment, and test account deletion and all sensitive access paths in an isolated emulator environment before release.
