# SickleCare Administration Experience Plan

**Status:** Planning document only; no dashboard code or authorization changes were made.
**Audit basis:** Stage 1 commit plus read-only review of the separate frontend branch and current uncommitted main-worktree files. Live Firebase configuration and production data were unavailable.

## What exists today

The only administrative UI found is `sicklecare_app/lib/screens/admin/admin_screen.dart`, a Flutter screen reachable from the app's admin path. It edits the `content/home` document and streams the latest 20 `support_messages`. It does not provide a separate web admin application, user search/management, resource CRUD, analytics, exports, notification controls, or an audit-log view. The Firebase `web/` directory is the Flutter app's web target, not a dedicated admin console. Backend Hosting points at a `public/` folder not found in the source inventory.

The screen's UI gate reads `AuthProvider.isAdmin`, which is derived from the profile's `role` field. App Firestore rules require the `admin` custom claim for content/support access. Therefore a profile role may expose the UI without granting authorized data access. Its initial content load catches errors without showing them; the support `StreamBuilder` does not present a distinct error state; save handling lacks visible error/finally handling. These are source observations, not a runtime test result.

## Recommended product shape

Retain the current admin screen as the starting point and extend it into a responsive, role-gated administration area in the existing Flutter web target if desktop browser behavior is acceptable. This avoids creating a second product stack while keeping the existing mobile app intact. Before implementation, confirm that the web target is intended for staff use; if a separate desktop-only operational environment is required, document that as the reason to create a dedicated web client rather than duplicating the current screen by default.

The screen should call protected, narrowly scoped operations for aggregates and sensitive management tasks. Do not expose Firestore collections broadly just to simplify charts or tables. Use direct client queries only where rules can enforce the exact least-privilege read/write contract.

## Authorization model

| Capability | Proposed trusted authorization | Data exposure |
|---|---|---|
| Platform owner/bootstrap | Explicitly provisioned Firebase Auth custom claim through a controlled server/admin process; strong MFA and restricted operator access | No routine health-record access by default. |
| Content editor | Custom claim or explicit server-managed permission | Published/unpublished educational content only; changes audited. |
| Support staff | Custom claim plus support queue permission | Contact details and support message needed for response; no tracker health records. |
| User manager | Dedicated permission for status/account operations | Minimum identity/profile fields. No access to notes, pain, hydration, or meal history. |
| Clinician | Not an administrator by default; requires a verified clinician account plus explicit patient relationship/consent | Only the patient's permitted records for the approved purpose and period. |

Never grant privileged claims based on `users/{uid}.role`, a signup role selector, email domain alone, or a hidden UI button. Provision and revoke claims through a controlled, audited process. On existing accounts, inventory candidate UIDs with the project owner, verify identity/authorization out of band, set claims, force token refresh, verify rules, then stop using profile role for authorization. Do not automatically promote every profile currently labeled `admin`.

## Proposed sections and real data sources

### Overview

- Show counts and trends only when calculated from real Firebase data or server-maintained aggregate documents.
- Define each metric before building it: total Auth users vs Firestore profiles; registrations by date; active period definition; support counts by status; published resource counts; tracker record counts only as aggregate.
- Prefer server-side aggregate queries/rollups with bounded date windows over a dashboard downloading all patient documents.
- Include loading, empty, partial-failure, stale-data timestamp, date-range and refresh states. Never display fallback/demo numbers as live statistics.

### User directory

- Search by approved identity fields with pagination and server-side limits.
- Show account status, created date, profile-completion state and minimal role/permission metadata.
- User access suspend/reactivate operations require a privileged function and audit event; they must not edit client-writable profile roles.
- Avoid opening detailed health history from this screen.

### Support and feedback queue

- Use canonical `support_messages`; retain public contact intake separately and preserve legacy `/support` records pending migration.
- Filter by status/date/source, paginate, refresh, and show bounded message content only to support-authorized staff.
- Limit write operations to status and response metadata. If outbound replies are not yet implemented, do not present a dead "Respond" button; direct staff to an approved workflow.
- Add audited resolution notes that do not duplicate unnecessary health details.

### Education content

- Manage FAQ/resource title, body, language, category, publication state, and archive state.
- Preview published content and show which mobile clients consume it.
- Preserve existing `content/home`, `resources`, and `faqs` documents; establish a typed schema and validation before editing them.
- Uploads, if needed, must use scoped Storage rules and validated MIME/size limits.

### Activity and reports

- Show administrative audit events with actor, action, target ID, timestamp and outcome.
- Use anonymized/aggregated health trends only if there is a documented legitimate purpose and privacy review. Do not export detailed patient health data by default.
- Any export needs role checks, filters, audit logging, access expiry, and a justified retention process. No bulk export is proposed initially.

### Notification operations

- In the first version, show configuration/health status for delivery without exposing tokens.
- Do not provide arbitrary broadcast to all users without authorization, approval, rate controls, an idempotent campaign ID, audience limits and audit logging.
- Do not include pain scores, diagnoses, medication names or message bodies in lock-screen notification content.

## Data and service boundaries

- `content`, `resources`, and `faqs`: direct client access can remain only if claim rules and field-level validation are sufficient; otherwise use callable Functions.
- User counts/status: trusted function/rollup; avoid querying Authentication user lists from the browser.
- Support status changes and audit events: callable Functions that validate claim, request schema, target path, state transition and outcome.
- Aggregate analytics: server-owned aggregation with privacy-conscious dimensions and bounded windows. Detailed health data remains owner-only absent explicit consent workflow.
- All privileged functions independently verify Auth, custom claims, App Check where available, input bounds, rate limits, ownership/relationship and audit outcome; Admin SDK bypasses Firestore rules.

## UX and accessibility requirements

- Responsive desktop/tablet layouts using existing brand and typography.
- Clear section navigation, accessible labels, keyboard focus, table headers, contrast, and non-color-only status indicators.
- Consistent loading, empty, permission-denied, offline, retry and server-error states.
- Search/filter state visible; pagination must not silently load the whole collection.
- Confirm destructive account/resource actions and explain consequences; preserve reversible archive/disable behavior where possible.
- Do not add patient-facing implementation details to the admin UI.

## Verification plan

Before release, test with emulator fixtures (synthetic data only):

1. A non-privileged user cannot open admin operations or read queue/user/aggregate data.
2. Editing a profile `role` cannot grant access; stale ID tokens are handled after claim changes.
3. Support staff can only read/update authorized support documents; cannot read tracker records.
4. Content editors can edit content but cannot manage accounts or support.
5. A clinician without patient relationship/consent cannot read that patient's health data.
6. Server metrics match a deterministic fixture dataset, date filters and empty results.
7. Pagination/search bounds, error states, offline/refresh and responsive browser layouts.
8. Sensitive operations create audit records without logging health notes, credentials, tokens or message bodies.
9. Firestore/Storage rules and callable authorization have positive and negative tests.

## Decisions required before implementation

- Is staff administration expected inside the current Flutter web target, or is a separately hosted web console necessary?
- Which named operators are authorized for bootstrap and how will identity/MFA be verified?
- Which non-health metrics are useful to the NGO presentation and what date/activity definitions apply?
- Who may see support-message PII and what response/retention workflow is approved?
- Is any clinician workflow authorized for patient-specific data, and what consent/relationship record proves it?

Until these questions are resolved, keep the current interface as a limited content/support screen and do not grant broader data access.
