# Frontend/backend integration

**Reviewed:** 7 November 2026
**Firebase project in checked-in config:** `sicklecare-15d7a`
**Deployment status:** No Firebase services were deployed or queried.

| Workflow | Flutter contract | Backend contract | Status |
|---|---|---|---|
| Sign-in and profile | Firebase Auth; `users/{uid}` | Auth creation initializes the profile; Firestore rules allow bounded owner profile fields | Aligned |
| Admin access | Mobile and web consoles read the Auth ID-token `admin` claim | Firestore/Storage rules and admin callables check trusted claims | Aligned; claim grant/revocation remains an operator task |
| Tracker | Hive offline store; sync to `users/{uid}/tracker_entries/{entryId}` with `id`, ISO `date`, integer `painLevel`, integer `hydrationMl`, `mood`, `notes` | Rules and the health trigger validate this payload; analytics, export, and JSON reports query `tracker_entries` | Aligned for new app writes |
| Legacy health records | No current Flutter writes to `users/{uid}/health` | Existing legacy records are not automatically migrated | Migration not performed |
| Sika online chat | Consent-gated `askSika` callable sends prompt and up to six recent messages; tracker/profile data are not included | Authenticated, App Check-protected callable; bounded inputs, per-user rate limit, Groq key from Secret Manager | Source aligned; provider secret and production App Check configuration must be provisioned |
| Support | Signed-in submissions to `support_messages`; signed-out submissions to `contacts` | Rules validate submissions; only trusted admins can read/manage messages | Aligned |
| Admin console | React/Vite Hosting SPA: summary, paginated Auth directory, live inbox, content editor, recent activity | Admin-claim callables provide summary/list reads and validate/audit writes | Implemented; Firebase Hosting deployment and authorized-domain configuration remain |
| Admin content | `content/home`; mobile and web editors publish title/body through callable | Public content reads; direct client writes denied; bounded admin callable writes and logs audit metadata | Implemented |
| Admin activity | Read-only activity view for administrative content/inbox changes | Append-only audit records written/read through admin-only callables | Implemented for dashboard/mobile editor actions |
| Reminders and push | Hive and local device alarms | Legacy cloud reminder/FCM functions remain separate; Flutter does not register FCM tokens | Local reminders work; cloud push is not integrated |
| Reports | No current Flutter callable integration | Authenticated JSON report callable stores a user-readable report; email delivery is not implemented | Backend-only |
| Account deletion | Deletes Auth account, then clears local health data | Auth deletion trigger removes known user subcollections, related metadata, and user Storage files | Source flow aligned; production trigger execution not verified |

## Firebase configuration

The backend Firebase CLI configuration is in `sicklecare_backend/` and its
default alias now matches the Flutter Firebase project ID. The Flutter folder
keeps generated FlutterFire platform configuration; it no longer has a second
Firestore rules file. Deploy rules, indexes, Storage, and Functions only from
the backend directory after reviewing the selected Firebase project.

## Local verification performed

- Backend TypeScript build, ESLint, and Jest schema tests passed (10 tests).
- Admin backend build/lint and Jest tests passed; the admin dashboard production build and dependency audit passed.
- Flutter static analysis and widget tests passed.
- Current Firestore, Storage, and Auth rules loaded in the local Firebase
  Emulator Suite. This confirms emulator startup/rule loading, not a full
  authorization test of the latest rule edits.
- Earlier local checks exercised owner access, cross-user denial,
  profile-role escalation denial, admin-claim access, and sequential and
  concurrent rate-limit requests against the earlier rules version.
- Flutter built the Android debug APK successfully using a temporary local
  Firebase Android configuration generated from the checked-in FlutterFire
  options. The ignored config was removed afterward; the APK is a local
  testing artifact, not a Play Store release.

Production Firebase state, external Groq connectivity, real-device behavior,
App Check enforcement, scheduled jobs, and account-erasure completion still
require an authorized project and device validation.
