# SickleCare Flutter app

This is the active Flutter application. Run `flutter pub get`, `flutter
analyze`, `flutter test`, or `flutter build apk --release` from this folder.

Firebase Android configuration is local and Git-ignored:
`android/app/google-services.json`. Firebase Functions, Firestore rules,
Storage rules, indexes, and the admin console are maintained in the sibling
`sicklecare_backend/` directory. Doctor credentials are uploaded to private
Storage and can be reviewed only by administrators with the trusted Firebase
Auth admin claim.

See the repository-root `README.md` for setup, build, and backend details.
