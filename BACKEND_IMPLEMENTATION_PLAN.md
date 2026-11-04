# SickleCare Backend Implementation Plan

**Status:** Sequenced plan only; Stage 2A audit did not change application/backend code.
**Base:** `feature/backend-stage-2` at Stage 1 audit commit `76ebf53`.

## Constraints and gates

- Preserve the existing main worktree and frontend branch changes; do not merge either wholesale.
- Do not deploy, migrate, delete, or mutate production data in this plan.
- Confirm Firebase project ownership/configuration and actual deployed services before selecting a deploy root.
- Keep secrets out of Flutter, repository history, logs, and build assets. The current original worktree has a non-empty Groq key in an ignored `.env` and generated build assets; key values were not read. Confirm artifact distribution and rotate the credential if distributed before any AI release.
- Use synthetic records in emulators. No test may use real patient information.
- Do not claim runtime behavior until the corresponding test/device result is recorded.
- Every implementation stage must be independently reviewed, tested, committed, pushed to its feature branch and remotely verified before proceeding.

## Stage 0 - unblock architecture decisions

**Work:** Obtain project-owner confirmation of the Firebase project ID, environments, authorized deploy operators, live service inventory, support process, clinician model, and whether Flutter Web is the preferred admin runtime. Securely determine if key-bearing artifacts were distributed. Capture a read-only collection/config inventory without emitting record contents.

**Gate:** A named authoritative project and deployment root; protected credentials; reviewed inventory/backup and explicit change approval for any production migration. No deploy or data mutation in this stage.

## Stage 1 - canonical Firebase and package boundary

**Work:** Compare Firebase Console state with `sicklecare_app/firebase.json`, `lib/firebase_options.dart`, Android config, backend `.firebaserc`, backend `firebase.json`, and both Functions packages. Select one canonical Functions codebase and explicitly configure it. Confirm whether Functions are first- or second-generation, required runtimes, indexes, Storage and Hosting. Avoid changing identifiers by inference.

**Tests/checks:** Parse config, `firebase use`/project list under authorized account, emulator startup, functions discovery, package build/lint, no secret scan output. Live inspection/deploy is not assumed.

**Gate:** A reviewed deployment matrix mapping each resource to one project/config/package, backed by owner/Console evidence. Do not deploy.

## Stage 2 - authorization and rules baseline

**Work:** Design claims for platform owner/content editor/support operator and a separate patient-clinician relationship/consent model. Prevent owner profile writes to privilege/status/claims fields. Restrict health data to the owner unless explicit relationship and consent permit access. Restrict feedback/support payloads and reads. Align notification paths and Storage metadata ownership. Remove or protect unauthenticated catch-all HTTP operations.

**Prioritized source risks:** backend `isCaregiver()` trusts caller's profile role while profile owner writes are allowed; app role gates read that same client-writable field; profile writes are broad; app feedback create is unvalidated; top-level notification reads are shared across signed-in users; backend HTTP `api` has wildcard CORS/no explicit auth; Storage doctor access lacks an evident relationship check. Actual deploy state is unknown.

**Tests/checks:** Firestore and Storage emulator rules tests for owner success, cross-user deny, profile role mutation deny, caregiver self-escalation deny, doctor without consent deny, valid support/contact boundaries, published content, notification isolation, upload ownership/type/size, and admin claim positive paths. Include callable tests because Admin SDK bypasses rules.

**Gate:** All negative and positive security tests pass. No production rules release until separately approved.

## Stage 3 - migration-safe data contract and backend readers

**Work:** Adopt the proposal in `FIREBASE_DATA_CONTRACT.md` after owner/product approval. Prefer the app's current `tracker_entries` path and adapt backend readers rather than deleting or blindly rewriting data. Keep `/health`, `/daily`, `/support`, and old reminder data available until inventory and parity criteria are met. Add versioned fields and compatibility readers. Implement idempotent migration tooling only after a written plan and backup verification.

**Tests/checks:** Synthetic old/new fixtures; unit tests for timestamp, timezone and hydration unit conversions; idempotent migration dry-run; count/hash/parity checks; mixed-client compatibility; rollback demonstration. No production run.

**Gate:** Approved field mapping and retention policy, tested rollback, known source/destination counts and no destructive step.

## Stage 4 - callable backend hardening and Sika

**Work:** Consolidate backend entry points; strict schemas and allowlists; consistent `HttpsError` mapping; request size and usage limits; structured redacted logs; audit privileged actions. Implement Sika through authenticated server-side callable/HTTPS with secret-manager configuration, consent/minimum context, only the caller's permitted data, provider timeouts, output/error controls, emergency escalation language, no diagnosis/prescription and no raw health logging. Client chat must stop making direct provider calls and stop accepting provider API keys for production use.

**Additional findings to test:** JS AI reads `daily`, not the app tracker path; accepts `messages` without evident bounds/rate limit; prompt calls Sika a medical AI assistant; callable is not used by client. Password-reset callable exists in JS source but deployment is unknown and custom SMTP errors may distinguish existing users. TypeScript functions validate only parts of input; some errors are rewrapped as internal. Do not treat source as deployed.

**Tests/checks:** Auth/claim/App Check behavior, payload validation, rate limits, secret unavailable/invalid, provider timeout/errors, prompt injection/boundaries, no PII logs, synthetic privacy checks, reset enumeration behavior.

**Gate:** No AI key in Flutter package or assets, documented data flow, bounded authenticated requests, medical safety review and tested failures.

## Stage 5 - notifications and reminders

**Work:** Decide local alarm versus cross-device reminder synchronization. Keep OS-scheduled local reminders for precise on-device delivery; use FCM for best-effort server events where appropriate. Implement per-installation token registration/refresh/removal, platform permission states, user preferences, multiple devices, timezone rules, idempotent delivery IDs and dead-token cleanup. Avoid sensitive lock-screen text. Set server scheduler/queue ownership and retry policy.

**Tests/checks:** Android/iOS permission flows; token rotation/revocation; two-device synthetic account; duplicate scheduler delivery; expired token; app killed/background/locked; timezone/DST and exact-alarm policy checks. Firebase push delivery requires a configured project/APNs credentials and physical devices; report unavailable cases honestly.

**Gate:** Clear delivery guarantees/limits and tested permissions/retry/duplicate behavior. Do not present FCM as guaranteed exact-time alarm delivery.

## Stage 6 - Flutter integration and privacy

**Work:** Scope local Hive data by authenticated UID or otherwise prevent cross-account data display/sync; identify unsynced entries per account; expose retry and last-sync/error status. Make tracker records read from the canonical remote path with offline merge/conflict policy. Make deletes update remote records only under clear owner rules. Update support/resources and AI/notification clients to use agreed contracts. Improve loading/error/empty states. Keep local privacy export/deletion separate from server account erasure until full server deletion is implemented.

**Tests/checks:** Signup/profile and role flows; offline creation/retry; logout/login with another account on the same device; server read-back; remove/update semantics; support-to-admin flow; AI request; local notification; account deletion and Auth reauthentication. Widget/unit tests plus Flutter analyze/build for Android. iOS requires macOS/Xcode and valid native Firebase/APNs config.

**Gate:** No cross-user local leakage, correct owner reads/writes, surfaced sync errors, offline and account lifecycle verified.

## Stage 7 - administration experience

**Work:** Follow `ADMIN_DASHBOARD_PLAN.md`: secure the current Flutter admin screen and extend it responsively in the existing Flutter web target unless project owners approve a separate web product. Implement real aggregate overview, minimally exposed user directory, support queue, resource CRUD/publication, audited status actions and clear errors. No fake/demo metrics or patient-detail exports.

**Tests/checks:** Claim roles and denied paths, real/emulator data calculations, search/pagination, support transitions, resource publication, audit records, accessibility and desktop/tablet browser layouts.

**Gate:** Admin data access is enforced server-side/rules-side, staff views are least-privilege, all actions are auditable.

## Stage 8 - end-to-end, release and operations

**Work:** Document backup/restore, retention, key rotation, monitoring, rollback, deployment operator, iOS requirements and environment setup. Confirm production settings and complete privacy/security review. Prepare release checklist and presentation readiness assessment based only on evidence.

**Tests/checks:** Emulator rules suite, Functions unit/integration tests, Flutter tests/analyze/build, Android device workflow, iOS review/build only on macOS/Xcode, browser dashboard checks, staged end-to-end tests with synthetic data. Separate smoke checks from production deployment.

**Gate:** Explicit deployment approval with rollback plan. No automatic deploy or production migration.

## Test and evidence matrix

| Area | Current evidence | Required before release |
|---|---|---|
| Flutter | `test/widget_test.dart` exists; not run in Stage 2A | Widget/unit tests, `flutter analyze`, Android build and device scenarios. |
| TypeScript Functions | Build/lint/Jest scripts exist; no backend test files found | Install state and tool versions confirmed; build/lint + function tests. |
| JavaScript Functions | Lint/deploy scripts and test dependency exist; no function test files found | Build/lint + emulator callable tests and explicit deployment wiring. |
| Firestore/Storage | Two source rule sets, no rule-test files found | Emulator positive/negative suite for canonical rules and data model. |
| Firebase live state | Not accessed; live GitHub failed, Firebase credentials not used | Authorized Console review and controlled staging verification. |
| iOS/notifications | plist absent in inspected Runner folder; no FCM SDK in Flutter deps | Native Firebase/APNs setup and physical iOS tests on macOS. |
| AI secrets | `.env`/generated build assets contain non-empty key variable (value not read) | Key rotation if artifact distributed; prove client artifacts contain no provider secret. |

## Stage 2A documentation checkpoint

The only Stage 2A implementation files should be the four audit/plan documents. Run Markdown checks, review diffs, commit only those files as `docs: complete SickleCare stage 2 architecture audit`, push `feature/backend-stage-2`, and verify the remote hash. If the push fails, keep the local commit and report the exact network error; do not claim Stage 2A is remotely complete and do not start implementation until the required remote verification succeeds.
