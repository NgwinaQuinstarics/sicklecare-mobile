# SickleCare Firebase Data Contract Proposal

**Status:** Proposed Stage 2 contract, not implemented. No production documents were read, rewritten, migrated, or deleted.
**Basis:** Static source review of Stage 1 base plus read-only comparison with the original main worktree and frontend branch on 4 November 2026.

## Contract decisions

1. Treat `users/{uid}/tracker_entries/{entryId}` as the forward patient tracker path because it is the current Flutter writer and is represented in the app rules. This is a recommendation, not a deployed fact.
2. Preserve `users/{uid}/health` and `users/{uid}/daily` as legacy/incompatible datasets until their record counts, units, timestamps, and consumers are inventoried. Do not overwrite or delete them.
3. Treat top-level `support_messages` as the signed-in support path because it is written by the Flutter service and read by the current in-app admin screen. Keep signed-out `contacts` separate. Preserve `/support` as a legacy path until verified.
4. Keep local reminders local until the cloud delivery contract is designed and tested. If cross-device sync is approved, adopt one cloud reminder contract and make local schedules projections of that contract.
5. Represent administrative privilege using server-controlled Firebase Auth custom claims. A profile `role` may remain as non-authoritative display metadata during migration but must never grant access.

## Current source contracts and incompatibilities

| Path | Current source writer/reader | Observed shape | Issue |
|---|---|---|---|
| `users/{uid}` | Flutter signup/provider; TypeScript Auth trigger | Profile fields include name/email/role and timestamps/settings; trigger uses displayName/email, `role: patient`, stats/settings | Client and trigger use inconsistent name/role fields. Owner update rules do not protect role fields. |
| `users/{uid}/tracker_entries/{id}` | Flutter `TrackerProvider` | `id:string`, `date:string` ISO, `painLevel:int 0..10`, `hydrationMl:int 0..10000`, `mood:string`, `notes:string<=2000` | Mobile active write path. Local Hive adds sync metadata; Firestore write does not. |
| `users/{uid}/health/{date}` | TypeScript functions/rules | requires `userId`, pain 0..10, `hydration` 0..10, Firestore `timestamp`; analytics/report queries timestamp | Different scale, timestamp type, optional data and path from the app tracker. |
| `users/{uid}/daily/{date}` | JS `sickleCareAI` callable reader | AI expects painLevel, hydration in litres, meals array | No matching Flutter writer was found. Not safe to synthesize from tracker without unit/time semantics. |
| `support_messages/{id}` | Flutter support writer and AdminScreen reader | `uid`, name/email, subject/message, `status:new`, `source:mobile_support`, `createdAt:serverTimestamp`; userEmail/userName copied when signed in | Current admin view displays message body and contact data. Backend rules use another collection. |
| `contacts/{id}` | Signed-out Flutter support writer | name/email/subject/message/status/source/server timestamp | Public create path; needs abuse protection, retention and rate limits. |
| `support/{id}` | Backend Firestore rules | `userId` assumed by read/update rules | No matching current Flutter writer found. Legacy status unknown. |
| `users/{uid}/reminders/{id}` | TypeScript Functions only | title/type/time/repeat/active/completed/nextNotificationTime | Flutter currently stores a different reminder shape in Hive and does not sync it. |
| `notifications/{uid}/history/{id}` | TypeScript Functions writer | title/body/type/data/sent/read/timestamps | Mobile rules explicitly describe a different top-level notification path; no Flutter reader found. |
| `content/home`, `resources`, `faqs` | AdminScreen writes `content/home`; rules permit published resources/FAQs reads | Resource/FAQ field schema not documented in code inspected | No full CRUD or publish workflow in the existing admin screen. |

## Proposed fields, ownership and validation

### `users/{uid}` - profile

- Document ID and immutable `uid` equal the Firebase Auth UID.
- Client-managed allowlist: `displayName`, `photoURL`, locale/theme preferences, and `updatedAt`; validate lengths and type.
- Server-managed: account status, `createdAt`, administrative claims, access-review metadata. Client writes must not set these.
- Treat `role` as display-only if retained during transition. Security rules and server functions must use verified token claims and explicit relationships, not this field.
- Avoid putting detailed health records or FCM tokens in the root profile.

### `users/{uid}/tracker_entries/{entryId}` - canonical tracker proposal

| Field | Type | Requirement/validation |
|---|---|---|
| `schemaVersion` | integer | Required for the new shape; currently absent in legacy records. |
| `occurredAt` | Firestore Timestamp | Required for new writes; device event time, validated against an approved bound. Do not silently replace historical local event times with server time. |
| `createdAt` | Firestore Timestamp | Server timestamp; immutable after create. |
| `painLevel` | integer 0..10 | Required. |
| `hydrationMl` | integer 0..10000 | Required if preserving current UI contract; explicit millilitres, not litres. |
| `mood` | bounded string/enum | Optional or required per product decision; cap to current observed 8 characters. |
| `notes` | string up to 2000 chars | Optional; sensitive free text. Avoid copying into logs, push notifications, or admin analytics. |
| `id` / `date` | legacy string fields | Keep readable during transition; new code can dual-read while writing the versioned shape. Do not delete until all clients and migrations are validated. |

Ownership is encoded by the user path and enforced against `request.auth.uid`. A user can read/create/update/delete only their own entries, with immutable ownership and creation fields. Staff access requires a narrowly scoped, documented care relationship and consent; an `admin` claim alone should not grant routine detailed health access.

### `users/{uid}/reminders/{reminderId}` - future cloud sync only

Use a stable client-generated ID and fields such as `title`, `type` (medication/hydration/appointment/checkup), local-time schedule plus IANA timezone, repeat rule, `enabled`, `createdAt`, `updatedAt`, and preferences. Medication reminder metadata must not imply a prescription or dosage recommendation. Completion events, if needed, should be separate immutable events with server receipt time and an optional validated `occurredAt`.

A future `users/{uid}/devices/{installationId}` document may hold FCM token, platform, permission state, token update time, and active state. Token writes must be limited to the authenticated owner, validated, and removable on sign-out/account deletion. Do not store tokens in public profiles or log them.

### `support_messages/{messageId}` and `contacts/{messageId}`

- `support_messages`: authenticated `uid`, bounded `name`, `email`, `subject`, and `message`, `status` (`new`, `in_review`, `resolved`), `source`, server `createdAt`, and server/admin `updatedAt`/resolution metadata.
- `contacts`: same bounded content without `uid`, only if signed-out contact is a required feature. Add App Check and abuse/rate controls; never expose list/read to the submitter or public clients.
- Admin updates should be status-only, permission-gated, and auditable. Do not treat a support message as consent to expose health records.
- Retention duration and deletion workflow require project-owner/privacy approval before implementation.

### Resources and admin records

- `resources/{resourceId}` / `faqs/{resourceId}` should have typed title, body, locale, publication state, created/updated timestamps, and author UID. Public clients read published items only; authorized editors create/update/archive.
- `audit_logs/{logId}` should record actor UID, action, target type/ID, timestamp, outcome, and minimal metadata. Do not log message bodies, health notes, credentials, tokens, or full before/after health documents.
- Admin dashboard metrics should use aggregate counts, not detailed patient documents. Define activity windows and allowed dimensions before showing counts.

## Backward-compatible migration plan (not executed)

1. Confirm authoritative Firebase project, database, rules deployment history, and retention policy. Obtain owner-approved, least-privilege access; this audit did not inspect production.
2. Use emulator fixtures based only on synthetic records. Inventory each collection's document count and field/type distribution with a reviewed, read-only script in the confirmed project. Never print patient values.
3. Preserve a secure, access-controlled backup/export and record its verification before data mutation. Define rollback, retention, and access logging.
4. Ship a compatibility reader that understands old `date` strings and new `occurredAt` timestamps. Continue writing the legacy fields needed by installed clients during a bounded transition. Avoid dual-writing two competing collections unless a reconciliation mechanism exists.
5. Backfill `health` to the chosen tracker model only after a field/unit mapping is approved. Use deterministic destination IDs, idempotent batches, migration markers, per-user counts, and timestamp/unit validation. Do not convert 0..10 hydration to millilitres without evidence.
6. Keep source records unchanged and readable through the observation period. Compare counts and aggregate checks; test old and new app versions against the compatibility reader.
7. Cut over analytics/admin reads after parity checks. Disable old writes only after adoption criteria and rollback window are approved. Deletion/cleanup requires a separate explicit plan and approval.
8. Apply an equivalent preserve-and-reconcile plan for `/support` to `support_messages`; keep unauthenticated `contacts` separate.

## Index and rules requirements

- Add only indexes required by concrete queries: user tracker `occurredAt` descending/range, user reminders by enabled/next delivery, support status plus creation time, and published resource locale/category as needed.
- Firestore rules must validate key allowlists, types, bounds, ownership, create/update field diffs, server-managed timestamps and role claims. Rules tests must prove cross-user denial, role-field mutation denial, profile allowlist, support ownership, published-only reads, and least-privilege staff access.
- Admin SDK functions bypass Firestore rules; validate auth/claims, request shape, ownership, rate limits and App Check independently.
- Storage paths must bind object ownership and metadata to authenticated identity; private health files are not broadly readable by all doctors/admins.

## Unresolved decisions

- Which project ID is authoritative: `sicklecare-15d7a` or `sicklecare-app`?
- Is `/health` an existing production dataset, test-only, or unused? What volume and data format?
- Does `/daily` contain user data, and is it actively written by any client not present in this workspace?
- Should current tracker dates represent local calendar date, UTC instant, or both?
- Is a cloud reminder feature required, or is local-only scheduling acceptable for the first release?
- What support retention, deletion and response workflow is approved?
- Which staff roles and patient relationship/consent model are legitimate?

No production schema migration is approved by this proposal.
