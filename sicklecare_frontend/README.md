# SickleCare Flutter app

This folder contains the Flutter application and its Android, iOS, desktop, and
web platform projects. The repository-level [README](../README.md) contains
setup, Firebase, security, and build instructions.

## App data contracts

- Firebase Auth owns account authentication.
- User profile documents are stored at `users/{uid}`. Privileged access is
  determined by the trusted Firebase Auth `admin` custom claim, not by the
  profile's `role` field.
- Offline-first tracker entries are stored locally and synced to
  `users/{uid}/tracker_entries/{entryId}` when signed in.
- Reminders are stored locally and scheduled on-device.
- Signed-in support messages use `support_messages`; signed-out contact
  submissions use `contacts`.
- Home content is read from `content/home`. The in-app admin screen can edit
  it and review the most recent support messages when the account has the
  trusted admin claim.

Configure Firebase with the approved project before using cloud features.
Local Android Firebase configuration and signing material must not be added to
source control.
