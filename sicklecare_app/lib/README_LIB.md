# SickleCare — `lib/` rebuild

Drop-in replacement for your existing `lib/` folder. Matches the `pubspec.yaml`
dependencies you shared.

## What it includes
- `main.dart` — app entry, providers, Hive + Firebase + notifications init
- `firebase_options.dart` — **placeholder**, replace via `flutterfire configure`
- Auth: `login.dart`, `signup.dart`, `auth_gate.dart`
- Screens: home, tracker, history (with fl_chart), reminders (with local notifications),
  AI chat (OpenAI-compatible, fallback if no key), hydration/nutrition, weather
  (Open-Meteo, no key needed), support (writes to `contact_messages` in Firestore),
  profile, settings, admin (edits `content/home` doc + lists contact messages),
  splash
- Providers: auth, theme (with persistence), tracker (Hive + Firestore sync),
  reminder (Hive + scheduled notifications)
- Services: notification, Firestore, AI, weather
- Theme, widgets (SectionCard, EmptyState), utils, store

## Setup steps after extracting
1. Replace your old `lib/` folder with this one.
2. Run `flutterfire configure` (this regenerates `firebase_options.dart`).
3. Make sure your `.env` (optional) contains `OPENAI_API_KEY=...` if you want
   the AI chat to call a real model. Otherwise it uses helpful canned replies.
4. `flutter pub get`
5. `flutter run`

## Firestore collections used
- `users/{uid}` — profile docs (created on signup). `role: 'admin'` unlocks admin screen.
- `users/{uid}/tracker_entries/{id}` — synced tracker entries
- `contact_messages/{id}` — submitted from Support screen
- `content/home` — admin-editable hero title/body

## Notes
- Android: ensure `android/app/build.gradle` has `minSdkVersion 21+` for
  `flutter_local_notifications` and Firebase.
- iOS: enable Push capability and add notification permission strings to `Info.plist`.
- The home screen shows an Admin button only when the signed-in user's
  `users/{uid}.role == 'admin'`. Set this manually in the Firestore console.
