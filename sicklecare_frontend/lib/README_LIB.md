# SickleCare Flutter `lib/`

The Flutter app initializes Firebase, local Hive storage, and device
notifications from `main.dart`. Configure Firebase with the project settings
in `firebase_options.dart` and `firebase.json` before running the app.

## AI assistant

Sika calls the authenticated `askSika` Firebase callable. Provider credentials
belong in Firebase Secret Manager and are not bundled with the app. The client
keeps emergency guidance and a local fallback available when the callable is
unavailable. Health context used for local fallback and daily advice is not
included in callable requests.

## Data paths

- `users/{uid}/tracker_entries/{id}` stores tracker entries.
- `support_messages/{id}` stores signed-in support submissions.
- `contacts/{id}` stores contact form submissions.
- `content/home` stores the home content edited by the in-app admin screen.

Administrator access is controlled by trusted Firebase Authentication custom
claims. Do not grant access by changing a client-writable profile field.
