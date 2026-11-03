# SickleCare Project Status

**Updated:** 3 November 2026
**Current stage:** Stage 1 audit complete; implementation and runtime verification remain.

## Verified from source

- Flutter application is in `sicklecare_app/`, with Android and iOS project folders and Firebase Auth/Firestore dependencies.
- Firebase backend source is in `sicklecare_backend/`, with TypeScript Functions, Firestore rules, Storage rules, and indexes.
- Mobile tracker entries are stored locally in Hive and synced to `users/{uid}/tracker_entries` when signed in.
- Reminder scheduling uses local Hive storage and local notifications.
- Mobile support submissions use `support_messages` (signed in) or `contacts` (signed out).
- A Flutter `AdminScreen` exists for home content editing and recent support message viewing; no separate web dashboard was found.
- A TypeScript backend module set exists for users, health, notifications, analytics, reports, and utilities.

## Important gaps identified

- Admin role in the mobile provider is derived from a client-writable Firestore profile field. Backend rule source checks custom claims, but deployment configuration is split and the app rules are the ones configured by the mobile Firebase config.
- The mobile tracker schema (`tracker_entries`) differs from backend health analytics (`health`).
- Backend support rules refer to `/support`, while the app uses `/support_messages`.
- Backend notification functions expect `fcmToken`; no Flutter FCM registration integration was found.
- The Sika app service can send an API key from local Hive storage directly to the AI provider; no authenticated server proxy was found.
- App password reset calls `requestPasswordReset`; the TypeScript backend entry point does not export that name in the inspected source.
- The requested web administration dashboard does not exist in the inspected workspace.

See [BACKEND_AUDIT_REPORT.md](BACKEND_AUDIT_REPORT.md) for evidence and prioritized work.

## Not verified

No compile, lint, test, emulator, Firebase Console, deployment, real-device notification, or iOS build check was performed during Stage 1. The presence of config/source files does not establish that a Firebase project is configured or deployed. No production readiness or security assurance is claimed.

## Immediate next work

1. Confirm the canonical Firebase project and deployment configuration.
2. Design and test trusted admin authorization and claim provisioning/revocation.
3. Reconcile tracker/health and support collection contracts.
4. Add emulator rule tests before changing deployed security rules.
5. Integrate backend AI/FCM only after the authentication and data contracts are settled.
6. Build a web admin dashboard on the confirmed architecture and real data contracts.
