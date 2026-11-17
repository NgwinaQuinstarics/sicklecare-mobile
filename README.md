# SickleCare

SickleCare is a Flutter health-management app with a Firebase backend and a
claim-protected web administration console.

## Repository layout

- `sicklecare_app/` — active Flutter app and Android/iOS projects.
- `sicklecare_backend/` — canonical Firebase Functions, Firestore and Storage
  rules, indexes, and hosted admin console.

The retired `sicklecare_frontend/` project is not used. Firebase deployments
should be run from `sicklecare_backend/`, which owns the Firestore and Storage
rules and indexes. The app's Firebase config contains only FlutterFire platform
configuration.

## Run and build the app

Install Flutter and the Android SDK, then run these commands from PowerShell:

```powershell
Set-Location .\sicklecare_app
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The release APK is written to
`sicklecare_app/build/app/outputs/flutter-apk/app-release.apk`. Android's
`google-services.json` is local and Git-ignored; install the approved
SickleCare Firebase Android configuration at
`sicklecare_app/android/app/google-services.json` before running Firebase
features or building. Do not commit Firebase service-account keys, signing
keys, or other private credentials. Release builds currently use the Android
debug signing configuration and are for testing/sideloading only.

## Backend and admin console

The doctor onboarding flow creates an Auth account, submits a validated
application, and uploads a bounded PDF/image to private Firebase Storage.
Only admins with the trusted `admin: true` custom claim can review credentials
or approve/reject applications. Approval assigns `doctor: true`; rejection
retains the record for resubmission. Deactivation disables sign-in, revokes
refresh tokens, removes doctor access, and preserves the application and audit
history; admins can reactivate an account.

The admin overview reads registered account profiles, doctor application
statuses, and recent submissions from Firebase. The user directory shows
account/profile details and paginated tracker entries that have synced to
Firestore; records kept only on a device are not visible to admins. User
profile and health-record access is restricted to admin-claim protected
functions, with health-record views audited.

Run the backend tests from `sicklecare_backend/functions`:

```powershell
npm ci
npm run build
npm run lint
npm test -- --runInBand
```

Run the admin console locally from `sicklecare_backend/admin` with `npm ci` and
`npm run dev`. Its authenticated credential downloads are authorized by
callable functions and Storage rules; they do not use public download URLs.

Cloud Functions deployment requires an eligible Firebase billing plan and
Cloud Build access. Review `sicklecare_backend/BACKEND_SETUP.md` for targeted
deployment steps. Local build and test commands do not deploy production
services. Never grant admin or doctor access by editing a Firestore profile
role; use trusted server-side custom claims.

## Feature boundaries

- Health tracking and reminders include device-local/offline behavior; not all
  app data is synchronized to Firebase.
- Doctor registration, credential review, approval, and deactivation are
  connected to the backend. Appointment and availability management are not
  connected yet.
- APK artifacts and local Firebase configuration are ignored by Git.
