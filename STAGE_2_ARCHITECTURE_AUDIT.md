# SickleCare Stage 2A Architecture Audit

**Audit date:** 4 November 2026
**Audit branch/base:** `feature/backend-stage-2`, based on Stage 1 commit `76ebf5316f924fda5c882617c3ca20019a620641`.
**Scope:** Static review of committed source at that base, the separate `origin/feature/frontend` snapshot, and the existing `main` worktree's uncommitted files for comparison. No application code, rules, Firebase configuration, or production data were changed.

## Executive summary

SickleCare has a Flutter client, Firebase Auth and Firestore integration in source, local Hive tracking/reminders, two distinct Firebase Functions codebases, and an in-app Flutter administration screen. There is no separate admin web application in the inspected project. Source presence does not establish successful builds, deployed functions, live Firebase project configuration, or production behavior.

The principal architecture issue is that there are multiple competing configurations and data paths. The mobile config identifies project `sicklecare-15d7a`, while the backend `.firebaserc` default alias is `sicklecare-app`. The mobile `firebase.json` configures Firestore rules and FlutterFire generation but not Functions, Storage, or indexes. The backend `firebase.json` configures TypeScript Functions, a different rules file, Storage, indexes, and Hosting. A JavaScript Functions package also exists under the Flutter app and exports password-reset and AI callables, but it is not declared as a Functions source in the app config. Firebase Console state and deploy history were unavailable, so the active project and deployed code cannot be determined from this audit.

The app actively writes `users/{uid}/tracker_entries`; TypeScript health, analytics, and report modules query `users/{uid}/health`; the JS AI callable reads `users/{uid}/daily`. These are not interchangeable contracts. Support is similarly split between app `support_messages`/`contacts` and backend rules `/support`. Preserve all paths until inventory and an additive migration plan exist.

## Audit basis and branch/worktree caveat

- The isolated Stage 2 branch starts at Stage 1 commit `76ebf53`, whose code baseline is `main` commit `c17917f` plus the Stage 1 docs.
- The original `main` worktree remains at `c17917f` and contains numerous pre-existing modified and untracked Flutter/Firebase files. Those were inspected read-only and were not copied into this branch.
- `origin/feature/frontend` is at `2c36c56` and adds care/clinician/facility UI, but its tree also deletes the backend directory and several root reports relative to `origin/main`. It is not a safe wholesale merge source. The current main worktree contains related uncommitted care/clinician UI files; they are not in this audit branch.
- The local `origin/docs/backend-audit-stage-1` tracking ref points to `76ebf53`. A live remote query could not be completed during this audit because GitHub port 443 was unreachable; no fresh server-side claim is made here.

## Project structure found

| Area | Source | Notes |
|---|---|---|
| Flutter app | `sicklecare_app/lib/`, `android/`, `ios/`, `web/`, desktop runners | The `web/` folder is the Flutter app's web target; it is not an admin portal. |
| Mobile Firebase configuration | `sicklecare_app/firebase.json`, `lib/firebase_options.dart`, `android/app/google-services.json` | The mobile JSON and Dart options identify `sicklecare-15d7a`. No `GoogleService-Info.plist` was found under `ios/Runner`; actual iOS native setup/build was not verified. |
| TypeScript backend | `sicklecare_backend/functions/src/` | User, health, notification, analytics, report, and utility modules. Its package declares Node 18 and `firebase-functions` 4.x; backend `firebase.json` links this package and its own Firestore/Storage rules. |
| JavaScript backend | `sicklecare_app/functions/index.js` | Separate package declares Node 24 and `firebase-functions` 7.x, with `requestPasswordReset` and `sickleCareAI` callables. Not linked from `sicklecare_app/firebase.json`'s deployment services. |
| In-app admin | `sicklecare_app/lib/screens/admin/admin_screen.dart` | Edits `content/home` and displays up to 20 recent `support_messages`. No web dashboard or broad CRUD console found. |
| Tests | `sicklecare_app/test/widget_test.dart`; package scripts in both Functions directories | Flutter has a widget test source. No backend test files were found in the inspected source tree, despite the TypeScript package's Jest script and JS package's test dependency. Tests were not run. |
| Local/build configuration | ignored `sicklecare_app/.env` and generated `build/**` assets in original worktree | A non-empty `GROQ_API_KEY` variable was detected in the ignored local `.env` and generated asset files; values were not read or compared. Artifact distribution status is unknown. |

## Implemented in source (runtime not verified)

- Email/password Firebase Auth flows, an auth-state provider, profile reads/writes, and account deletion attempt.
- Offline-first tracker storage in Hive with a Firestore write attempt at `users/{uid}/tracker_entries/{id}`. Failed Firestore writes are swallowed, and the provider's history is populated from local Hive rather than server read-back.
- Local reminders stored in Hive and scheduled through `AwesomeNotifications`, with permission/settings code and schedule recovery logic.
- Support/contact submission to Firestore; the in-app admin view reads `support_messages` and edits a single public home-content document.
- Sika has a keyword-based local fallback and an optional direct Groq HTTP request using a user key stored in Hive. A separate server callable exists in the JS Functions package, but the chat code calls `AIService`, not that callable.
- App Check initialization is present in `AppSecurityService` and invoked during app startup. Console enforcement and production attestation behavior were not checked.
- Doctor/care/facility preview screens and local UI state are present in the frontend branch and/or uncommitted main worktree. The current `CareUiProvider` is explicitly UI-only/mock state; doctor registration comments describe mock-only behavior pending a backend contract.

The label "Implemented in source" means code was found, not that its behavior passed a test or is deployed.

## Confirmed architecture problems and security concerns

### Firebase configuration and deployment ambiguity

1. `sicklecare_app/firebase.json` names Firestore rules and FlutterFire platform configuration for `sicklecare-15d7a`; it contains no `functions`, `storage`, or `firestore.indexes` deployment key.
2. `sicklecare_backend/firebase.json` deploys the TypeScript Functions package, `sicklecare_backend/firestore.rules`, `storage.rules`, and indexes. Its `.firebaserc` default is `sicklecare-app`, not the mobile config's project ID. Dev/prod aliases are names in a file, not proof those Firebase projects exist.
3. `sicklecare_app/functions` is a second Functions codebase with its own package scripts, Node engine and dependency generation. It is not configured as a Functions source in the app root `firebase.json`. The reset and AI callable implementations therefore cannot be assumed deployed.
4. Hosting points at `sicklecare_backend/public`, which was not found in the source inventory. This does not establish whether Hosting is deployed or used.
5. The ignored `.env` and generated build asset `.env` files each contain a non-empty `GROQ_API_KEY` variable (values were not read or compared). The committed baseline includes `flutter_dotenv` and declares `.env` as a Flutter asset; the original worktree has uncommitted changes removing that dependency/asset, but generated `.env` assets remain. Treat any distributed artifact containing the provider key as exposed; distribution is unknown. Do not copy the key to the Stage 2 branch or commit it. Rotate it if it has been distributed.

### Data contracts and ownership

- Mobile tracker document: `users/{uid}/tracker_entries/{entryId}`; fields are `id:string`, `date:ISO-8601 string`, `painLevel:int 0..10`, `hydrationMl:int 0..10000`, `mood:string`, `notes:string<=2000`. Document ID is set to entry ID. Hive has local sync metadata, but Firestore writes only `TrackerEntry.toMap()`.
- Backend health trigger/rules/functions expect `users/{uid}/health/{date}` with `userId`, numeric `painLevel`, `hydration` on a 0..10 scale, and Firestore `timestamp`. Analytics and reports read that collection.
- JS AI callable reads `users/{uid}/daily/{YYYY-MM-DD}` and expects `painLevel`, `hydration`, and `meals`; no writer for that contract was found in the inspected Flutter source.
- Signed-in mobile support uses top-level `support_messages` with `uid`, identity/contact fields, subject/message, status/source, and server timestamp. Signed-out contact uses `contacts`. Backend rules instead describe `/support` with `userId`.
- Reminder client schema is local `id,title,body,time,repeatDaily,enabled`; backend reminder schema is `users/{uid}/reminders` with `type`, `repeat`, `active`, `completed`, and `nextNotificationTime`. No client synchronization was found.

### Authorization and privacy

- `AuthProvider.isAdmin` and `.isDoctor` read `users/{uid}.role`. The profile owner can update their own user document under app rules, so the role field is not a trusted authorization source. The current app rules use the `admin` custom claim for privileged collections; self-editing a profile role may expose UI but does not by itself satisfy those claim checks.
- In the separate backend rules, `users/{uid}` allows owner writes while `isCaregiver()` reads the caller's profile `role`; if that rules file is deployed, a user may be able to change their own role to `caregiver` and gain cross-user health/reminder reads. Treat as a critical conditional risk and test/fix before deploying those rules.
- App rules allow any signed-in user to read top-level `/notifications/{notificationId}` documents, while backend writers use nested `/notifications/{uid}/history/{id}`. That nested path is not covered by the same explicit mobile rule and otherwise falls to default deny.
- App rules permit unauthenticated `feedback` creation without payload validation; abuse controls and content handling are unspecified.
- Both rulesets grant administrators broad access. Backend rules grant doctor/caregiver access by role/claim without a patient-provider relationship or consent check. Storage rules similarly allow doctor reads on user health paths. No least-privilege staff relationship model is evident.
- Account deletion in the client best-effort deletes the root profile before deleting Auth. The TypeScript Auth deletion trigger removes the root, `health`, and `reminders`, but does not show cleanup for `tracker_entries`, reports, notification history, support messages, analytics, or device tokens. The trigger's deployed state and full recursive cleanup are unknown.

### Sika AI and health-data exposure

- The mobile service directly sends user prompts/history and optional health context to Groq using a client-held key. The key can be read from Hive; the committed baseline also has a dotenv fallback. The user's provider-key entry is not a server-side secret.
- The separate `sickleCareAI` callable requires Auth and reads the caller's `daily` document with Admin SDK, then sends pain/hydration/meals plus user messages to a configurable AI endpoint. The callable accepts `data.messages` without an evident shape/length limit, has no evident rate limit or App Check enforcement in its source, and does not supply deterministic medical emergency handling. Its prompt labels Sika a "medical AI assistant" while also forbidding diagnosis/prescribing; wording and product boundaries need revision.
- The callable is not used by the Flutter chat and its data path differs from tracker storage. No provider secret value was displayed or committed by this audit.

### Notifications

- Local alarms can be scheduled by the OS and may work while the app process is closed when platform permissions/configuration allow; actual locked/force-stopped device behavior was not tested.
- No `firebase_messaging` package, FCM token registration, token-refresh listener, or device-token collection was found in Flutter source. No APNs configuration was verified.
- TypeScript functions read one `users/{uid}.fcmToken`; reminder scheduling helper only logs "queued", while a five-minute scheduled job attempts to send due reminders. This is not a reliable exact-time alarm contract, can miss multiple device tokens, and lacks demonstrated idempotent occurrence/lease handling.
- Local and server reminders have divergent schemas and no preferences/duplicate-delivery contract.

## Duplicate or potentially obsolete surfaces (do not delete during this stage)

| Surface | Evidence | Disposition |
|---|---|---|
| `sicklecare_backend/functions` TypeScript vs `sicklecare_app/functions` JavaScript | Separate package manifests, engines, dependencies, entry points, and function exports | Competing backend implementations. Select one canonical deployed codebase only after Firebase Console/deployment history review. Keep both until then. |
| `sicklecare_app/firebase.json` vs `sicklecare_backend/firebase.json` and two rulesets | Different deployment resources, paths, and project identifiers/aliases | Both are active source config for their own directories; determine intended deploy root/project before consolidating. |
| `users/{uid}/tracker_entries`, `health`, and `daily` | Separate mobile writer, TS readers, and JS AI reader | Distinct schemas, not safe to merge/delete without inventory and backfill plan. |
| `support_messages`, `contacts`, `/support` | Mobile writers/admin reader vs backend security contract | Preserve existing records and implement explicit transitional access. |
| `origin/feature/frontend` vs current main workspace | Feature commit removes backend/docs compared with main while adding UI; uncommitted main files overlap some UI work | Not a duplicate file issue; history divergence requires path-level reconciliation, not wholesale merge. |
| Flutter `web/` vs Hosting stanza | Flutter web app assets exist; backend Hosting source directory `public/` does not | Not proof either is an admin dashboard. Confirm whether Flutter web target is intended to be deployed. |

## Audit checks and limitations

- Inspected branch/worktree status and compared local branch trees; no app changes were made on `feature/backend-stage-2`.
- Inspected configs, rules, data models/providers, AI code, Functions exports/modules, notification code, admin screen, platform config, and test inventory.
- A live GitHub remote query failed because `github.com:443` was unreachable. Firebase Console, project aliases, enabled services, deployed rules/functions, and production data were not inspected.
- No code tests, Flutter analysis/build, Functions build/lint, emulator, security rules test, deploy, migration, or real-device notification check was run in this audit-only phase.
- Findings about what is deployed, which project is authoritative, whether a key-bearing build was distributed, and actual notification delivery remain unverified.

## Stage 2A exit recommendation

Resolve the deployment owner/project and history first; confirm whether the `.env`-containing build was distributed and rotate the provider key if so; preserve the current `main` worktree and feature branch as separate inputs; then approve a single data/auth contract. Stage 2B must not deploy rules or migrate records until that inventory and emulator tests exist.
