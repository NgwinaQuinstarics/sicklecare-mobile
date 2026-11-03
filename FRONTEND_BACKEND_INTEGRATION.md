# Frontend and Backend Integration Map

**Updated:** 3 November 2026
**Status:** Static source map for Stage 1. Paths and runtime success are not asserted beyond inspected code.

| User workflow | Flutter source behavior | Backend/rules source behavior | Current gap |
|---|---|---|---|
| Register/login | Firebase Auth in `signup.dart` and `login.dart`; profile read/write in `AuthProvider` | TypeScript Auth triggers create/delete profile; profile role defaults to `patient` | App profile role defaults to `user`; profile ownership rules permit broad document updates. Trigger execution/deployment unknown. |
| Reset password | Login screen invokes callable `requestPasswordReset` | TypeScript entry point exports no function with this name | Callable mismatch; standard Firebase Auth reset behavior should be confirmed or implemented consistently. |
| Record pain/hydration | `TrackerProvider` stores Hive entry and syncs to `users/{uid}/tracker_entries/{entryId}` | Backend health functions query `users/{uid}/health`; backend rules validate that shape | Entries are not visible to current backend analytics. |
| View history/dashboard | Local provider/Hive data are used by tracker UI; sync status is tracked locally | Backend has analytics callable functions for the separate `health` collection | No demonstrated server-derived dashboard or history read path. |
| Reminders | Hive + `AlarmService` local notifications | Functions store reminders below user docs and process FCM queue using `fcmToken` | No client sync/token registration found; server delivery unverified. |
| Sika assistant | Local fallback or direct Groq request using Hive-stored user key | No Sika callable/HTTPS endpoint exported from TypeScript backend | Provider key and optional health context leave the device directly; no backend-side auth/rate limit. |
| Support/contact | `FirestoreService` writes `support_messages` or `contacts` | Mobile rules validate those paths; backend rules describe a different `/support` path | Must standardize paths and admin permissions before a dashboard depends on them. |
| Edit app content | Flutter AdminScreen writes `content/home` | Mobile rules allow content writes to admin claim; app UI role derives from profile role | UI role and trusted rules disagree; only home content is editable in this screen. |
| Manage resources | No resource management UI found in inspected admin screen | App rules support claim-gated writes to `resources` and `faqs` | CRUD and publish workflow not implemented in inspected admin UI. |
| Delete account | Client best-effort deletes profile then deletes Auth account; local data deletion is separate | Backend has Auth deletion trigger and recursive cleanup logic | Server cleanup completion and failure handling require emulator/integration tests. |

## Canonical contract decisions needed

1. Which Firebase project and deployment root is authoritative (`sicklecare_app` or `sicklecare_backend`)?
2. Will `tracker_entries` remain canonical, or will the app and existing data migrate to `health`?
3. Which support collection is canonical: `support_messages` or `support`?
4. Which trusted claims and relationships authorize staff access to health records?
5. Will reminders remain device-local, or is authenticated cloud delivery required for the first presentation?

These choices affect rules, indexes, Cloud Functions, migration, and admin UI and should be settled before cross-cutting implementation.
