# SickleCare

SickleCare is a Flutter app for offline-first health tracking, reminders, and
support for people affected by sickle cell disease. Firebase Authentication
and Firestore are used for account and cloud features; health tracking and
reminders continue to work locally.

## Repository layout

- `sicklecare_frontend/` — Flutter application and platform projects.
- `sicklecare_backend/` — Firebase Functions, Firestore and Storage rules,
  indexes, and backend setup.
- `BACKEND_AUDIT_REPORT.md` — current findings, verification, and remaining
  operational work.
- `FRONTEND_BACKEND_INTEGRATION.md` — app/backend data and callable contracts.

## Run the Flutter app

Requirements: Flutter and Dart versions allowed by
[`pubspec.yaml`](./sicklecare_frontend/pubspec.yaml), Android SDK, and Java 17.

```bash
cd sicklecare_frontend
flutter pub get
flutter run
```

Firebase Android configuration (`android/app/google-services.json`) is local
and ignored by Git. Configure the app with the approved Firebase project before
testing cloud features. Do not commit Firebase service-account keys, local
configuration, provider secrets, or signing keys.

## Backend development

Cloud Functions, Firestore rules, Storage rules, and indexes are configured
under `sicklecare_backend/`. That folder's `.firebaserc` default project matches
the Flutter app's Firebase project configuration.

```bash
cd sicklecare_backend/functions
npm ci
npm run build
npm run lint
npm test -- --runInBand
```

The backend's `askSika` callable requires an authorized Secret Manager value for
`GROQ_API_KEY`. Provision it interactively with the Firebase CLI from
`sicklecare_backend/`; never place the key in Flutter or source control. The app
uses its local fallback if the online callable is unavailable.

Deployments are **not** performed by these local build/test commands. Before
deploying, review Firebase project selection, App Check configuration, billing,
indexes, and security rules. Only trusted operators should grant custom Auth
claims; a Firestore profile role is not authorization.

## Verification

```bash
cd sicklecare_frontend
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is written to
`sicklecare_frontend/build/app/outputs/flutter-apk/app-debug.apk` and is
ignored by Git. It is for testing, not Play Store distribution. Release
distribution requires a separately managed Android signing key.

## Current feature boundaries

- Sika online chat is opt-in and sends bounded chat text/history to the
  authenticated backend callable; tracker, profile, and reminder data are not
  attached.
- Tracker entries use
  `users/{uid}/tracker_entries/{entryId}`. Older records under `health/` are
  not automatically migrated.
- Reminders are device-local. Cloud FCM delivery is not integrated in the
  Flutter app.
- The admin surface is an in-app Flutter screen for home content and support
  messages; this repository does not contain a separate web admin console.
- Weekly report generation stores JSON reports. Email delivery and recoverable
  user backups require additional services and are not represented as working
  features.
