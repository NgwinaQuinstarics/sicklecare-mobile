# SickleCare Project Audit

**Audit date:** 3 November 2026
**Scope:** Static inspection of the checked-out Flutter app and Firebase source/configuration. No Firebase project, production data, emulator, or deployed service was accessed.
**Stage:** 1 — audit and implementation priorities.

## Executive summary

This workspace contains an established Flutter application, two competing Firebase configurations, and a TypeScript Cloud Functions codebase. The mobile app has real Firebase Authentication and Firestore code, but several features remain local-only or are wired to a different schema than the backend. There is no separate web administration dashboard. The existing `AdminScreen` is a Flutter screen for editing home content and viewing recent support messages.

The most consequential finding is authorization drift: the Flutter `AuthProvider` treats `users/{uid}.role == 'admin'` as an admin role, and the mobile rules permit a profile owner to update the entire user document. A client can therefore write the profile role used by the UI. The TypeScript backend rules instead check custom token claims, but that rules file is not referenced by either checked-in `firebase.json`. No trusted admin provisioning flow is visible in the inspected source. Admin UI visibility is not a secure authorization mechanism.

Existing source and documents contain useful work, but this audit does not validate deployed behavior. No build, test, emulator, or network check was run as part of this audit.

## Workspace and configuration

- `sicklecare_app/` is the Flutter application. It includes Android, iOS, web, Windows, macOS, and Linux platform folders.
- `sicklecare_backend/` contains TypeScript Cloud Functions, Firestore and Storage rules, indexes, and setup documentation.
- `sicklecare_app/firebase.json` points Firestore deployment at `sicklecare_app/firestore.rules`; it does not configure Functions, Storage, or indexes.
- `sicklecare_backend/firebase.json` points Functions, Firestore, and Storage at the backend tree; it has a Hosting stanza for a `public/` directory, but no admin web app or Hosting content was found in the workspace inventory.
- The app Firebase configuration identifies project `sicklecare-15d7a`; the backend `.firebaserc` aliases need verification against actual Firebase Console projects. No deploy was attempted.
- The TypeScript Functions package has a `node_modules` directory despite the older audit claiming it was absent. Its current compile/lint state is unknown.
- The working tree already contains numerous modified and untracked files before this audit. Those changes were preserved.

## Feature and data-flow findings

| Feature | Observed implementation | Audit finding |
|---|---|---|
| Authentication | Firebase Auth calls in login/signup; `AuthProvider` listens to auth state and loads `users/{uid}` | Real Auth integration exists. Profile read failures may fall back locally. Password reset references callable `requestPasswordReset`, but that export was not found in the TypeScript Functions entry point. |
| User profile and roles | Signup writes profile fields including `role: user`; provider reads the profile role for `isAdmin`/`isDoctor` | The profile document is client writable under the app rules. UI role checks are therefore not trusted authorization. The backend `onUserCreate` writes `role: patient`, which conflicts with the app's `user` role. |
| Pain / hydration tracker | `TrackerProvider` loads Hive and writes `users/{uid}/tracker_entries/{id}` | Offline-first local storage plus Firestore sync exists. The app rules validate tracker payloads. Backend Functions and its separate rules mainly target `users/{uid}/health`, so backend analytics do not consume these tracker records. Sync exceptions are swallowed and no server read-back is used in the provider. |
| Reminders | `ReminderProvider` persists Hive records; `AlarmService` uses local notification scheduling | Local reminders are implemented. No app FCM token registration or synchronization to backend reminder documents was found. Local alarm delivery and Cloud Functions scheduling are separate systems. |
| Sika AI assistant | `AIService` can call Groq's public-compatible endpoint using a key stored in Hive; otherwise it returns keyword-based local responses. It includes emergency and medication boundary replies. | A provider key and health context may leave the device directly. This does not meet the brief's server-side credential requirement. The backend has no corresponding AI endpoint. Whether any user-configured key is present at runtime is unknown. |
| Support/contact | `FirestoreService` writes signed-in messages to `support_messages`, unauthenticated contact to `contacts` | App rules provide bounded payload checks for contacts and signed-in support; admin reads are custom-claim gated. Flutter AdminScreen listens to support messages. The separate backend rules use a different `/support` schema. |
| Content/resources | App rules permit public reads of `content`, `resources`, and `faqs`; admin writes require claim | Mobile admin UI edits only `content/home`. No full resource CRUD interface or separate web dashboard was found. Resource publication flow to mobile is not established by the inspected screen. |
| Health analytics/reports | TypeScript modules include health analytics, exports, report and aggregation functions | They query `/users/{uid}/health`, while the observed app tracker writes `/users/{uid}/tracker_entries`. Scheduled/report/backup paths require runtime review; no backend test files were found in the inspected inventory. |
| Notifications | TypeScript module has reminder/notification functions that read `users/{uid}.fcmToken` and send FCM | The app dependency list has no `firebase_messaging`; no token registration was found. Cloud delivery is not connected to app reminders. |
| Account deletion/privacy | Provider deletes the Firestore profile best-effort, then deletes Firebase Auth user. Privacy service exports/deletes local Hive data. Backend has an Auth deletion trigger. | Client deletion can leave subcollections if the trigger is unavailable or incomplete; local privacy deletion does not delete server records. End-to-end erasure and reauthentication behavior have not been verified. |
| Doctor/facility flows | Doctor registration and verification screens, profile/schedule screens and facility screens exist | Screens/models exist, but the inspected role-selection source labels clinician onboarding as mock-only. No trusted clinician verification workflow has been established by this audit. |

## Security and compatibility findings

1. **Admin privilege source is inconsistent.** App UI checks a Firestore profile role; app rules let the owner update their profile; backend rules check custom claims. There is no demonstrated trusted grant/revoke process.
2. **Two rule sets protect different schemas.** The app config deploys app rules, which include tracker entries, support_messages, and content. Backend rules include health, reminders, support, analytics, and public paths. Do not assume both sets are active together.
3. **Backend rule access is overly broad for sensitive records.** Backend rules grant doctors/caregivers access to health and reminder documents based on claims, with no patient relationship/consent check evident. The profile document itself allows owner writes in that rules file.
4. **Support schema differs.** Mobile writes `/support_messages`; backend rules describe `/support`. Administrative tooling in the mobile app expects `/support_messages`.
5. **Health schema differs.** Mobile writes `/users/{uid}/tracker_entries`; backend analytics and security functions use `/users/{uid}/health`.
6. **Admin dashboard is absent as a web product.** An in-app admin content/support screen is not equivalent to the requested web admin console.
7. **AI secret boundary is not met.** The mobile app sends requests directly to Groq with a locally stored bearer key. The source does not contain a backend proxy or server usage controls.
8. **No FCM client integration was found.** Backend token assumptions cannot currently be satisfied by the inspected app.
9. **Storage rules need a separate review.** The backend Storage rules have broad doctor/admin health-document reads and support writes that do not show ticket ownership binding in the write condition. The rules also include rate-limit metadata checks whose data contract needs verification.
10. **Operational claims are unverified.** Firebase project existence, app registration, indexes, deployed rules/functions, provider credentials, notification delivery, and iOS runtime behavior require environment access and tests.

## Current Stage 1 conclusion

The project has a useful foundation, but it is not currently evidenced as a single integrated production system. The highest risk is privileged access control, followed by the split schema/deployment configuration. Features that rely on Hive or local notifications should be described as local/offline behavior, not backend-synchronized functionality. No patient data was accessed.

## Proposed implementation priorities

1. **Resolve the canonical Firebase deployment and rules.** Confirm the intended project and select one authoritative rules/index/functions config before editing security behavior.
2. **Fix authorization contracts.** Make client role fields non-authoritative; use verified Firebase custom claims for privileged actions and document secure admin provisioning/revocation. Remove or gate privileged UI based on token claims while keeping server/rules enforcement authoritative.
3. **Reconcile data contracts.** Choose a canonical tracker/health collection and support schema, then adapt Functions/rules and Flutter together without silently losing existing records.
4. **Establish emulator security tests.** Test owner access, cross-user denial, privilege escalation denial, admin claim access, malformed payload denial, and support/content permissions before deployment.
5. **Close high-risk integration gaps.** Route AI calls through an authenticated, validated, rate-limited backend; define FCM token lifecycle and real notification delivery; document local-only reminder behavior until cloud delivery is verified.
6. **Implement the requested web admin console only after authorization/data contracts.** Use existing repository conventions if a web architecture is added, and show real data with least-privilege access and audit records.
7. **Run staged build and workflow checks.** Compile/lint Functions, analyze Flutter, and verify signup → profile, tracker sync → history, support → authorized review, resource publish → mobile read, and account deletion using emulators.

## Out of scope for this static audit

- Verifying Firebase Console state, credentials, custom claims, indexes, or deployment.
- Claiming clinical safety, production readiness, or successful security testing.
- Migrating Firestore data or deploying any change.
- Creating sample or fabricated patient data.
