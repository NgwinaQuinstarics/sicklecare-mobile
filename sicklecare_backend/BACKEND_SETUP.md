# SickleCare Backend Setup Guide

## 🎯 Overview
This is the Firebase-based backend for the SickleCare health management application. You already have Firebase set up in your Flutter app, so this backend extends and enhances that setup with Cloud Functions and advanced configurations.

## ✅ What's Already Done

Your Flutter app (`sicklecare_frontend`) already has:
- ✅ Firebase Authentication
- ✅ Cloud Firestore database
- ✅ Basic data structure
- ✅ Real-time updates

## 🚀 What We're Adding (Backend Folder)

The new `sicklecare_backend` folder contains:

1. **Enhanced Security Rules** (`firestore.rules`)
   - Owner-scoped health data and validated writes
   - Admin/support access based on trusted Firebase custom claims
   - Profile fields cannot grant or change privileged roles

2. **Storage Security** (`storage.rules`)
   - Secure file upload/download
   - File type and size validation
   - User-specific storage buckets

3. **Firestore Indexes** (`firestore.indexes.json`)
   - Optimized queries for health data
   - Fast searches and aggregations

4. **Cloud Functions** (`functions/`)
   - Authenticated Sika proxy with App Check, bounded input, and per-user rate limits
   - User-data cleanup when an Auth account is deleted
   - Analytics and JSON/CSV exports for the Flutter tracker schema
   - JSON health reports stored in each user's reports subcollection

## 📋 Prerequisites

1. **Node.js 18+** installed
2. **Firebase CLI** installed: `npm install -g firebase-tools`
3. **Firebase Project** (you already have this from Flutter app setup)

## 🏗️ Project Structure

```
sicklecare_backend/
├── firebase.json              # Firebase project config
├── .firebaserc               # Firebase environment aliases
├── firestore.rules           # Firestore security rules
├── firestore.indexes.json    # Database indexes
├── storage.rules             # Firebase Storage rules
├── functions/                # Cloud Functions
│   ├── src/
│   │   ├── index.ts         # Main functions entry
│   │   ├── users/           # User functions
│   │   ├── health/          # Health data functions
│   │   ├── notifications/   # Reminder functions
│   │   ├── analytics/       # Analytics functions
│   │   ├── reports/         # Report generation
│   │   └── utils/           # Utility functions
│   ├── package.json         # Functions dependencies
│   └── tsconfig.json        # TypeScript config
```

## 🔧 Setup Instructions

### Step 1: Install Dependencies

```bash
cd sicklecare_backend/functions
npm install
```

### Step 2: Build TypeScript

```bash
npm run build
```

This compiles TypeScript files to JavaScript in the `lib/` directory.

### Step 3: Deploy to Firebase

```bash
# Deploy everything
firebase deploy

# Or deploy specific parts
firebase deploy --only functions
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
firebase deploy --only firestore:indexes
```

## 🌐 What Gets Deployed

### 1. Firestore Security Rules
- Controls who can read/write data
- Validates data structure
- Prevents unauthorized access

### 2. Storage Security Rules
- Manages file uploads/downloads
- Enforces file size limits
- Protects user privacy

### 3. Database Indexes
- Optimizes frequently used queries
- Improves performance for health data lookups

### 4. Cloud Functions (TypeScript → JavaScript)

#### User Functions
- `onUserCreate`: Initialize profile when user signs up
- `onUserDelete`: Clean up user-owned Firestore and Storage data when account is deleted
- `updateUserProfile`: Update user settings/profile

#### Health Functions
- `validateHealthEntry`: Validate and process `users/{uid}/tracker_entries/{entryId}`
- `processHealthAnalytics`: Calculate health insights
- `exportHealthData`: Export up to 1,000 tracker entries as JSON/CSV

#### Notification Functions
- `scheduleReminders`: Create medication/hydration reminders
- `sendNotification`: Send push notifications to user
- `processNotificationQueue`: Scheduled job to trigger reminders
- Mobile reminders remain on-device; the Flutter app does not currently register FCM tokens.

#### Analytics Functions
- `aggregateDailyStats`: Daily automated aggregation
- `generateTrends`: Calculate health trends for user
- `backupUserData`: Automated daily backups
- `getUserStats`: Get user statistics summary

#### Report Functions
- `generateHealthReport`: Create and store bounded JSON reports
- `sendWeeklyReport`: Store weekly reports for users with notifications enabled; no email is sent

#### Utility Functions
- `cleanupTempFiles`: Remove old temporary files
- `sendEmail`: Admin-only, rate-limited queue; delivery requires a separately configured worker
- `validateApiKey`: Validate API keys for integrations
- `getSystemHealth`: Health check endpoint

#### Sika assistant

The Flutter app calls the `askSika` callable after the user opts in to online
chat. The callable requires Firebase Authentication and App Check, accepts only
bounded chat text/history, and does not receive tracker or profile data. Its
Groq credential is a server-side Secret Manager secret:

```bash
cd sicklecare_backend
firebase functions:secrets:set GROQ_API_KEY
firebase deploy --only functions
```

Set the secret interactively in the authorized Firebase project. Never add the
provider key to Flutter assets, source, or local Hive storage. Without the
secret, the callable returns a configuration error and the app uses its local
fallback. Register a Firebase App Check debug token for local debug builds.

## 💻 Local Development

### Test Cloud Functions Locally

```bash
cd functions
npm run serve
```

This starts the Firebase emulator at http://localhost:5001

To run Auth, Firestore, and Storage locally while checking authorization rules:

```bash
cd ..
firebase emulators:start --project demo-sicklecare --only auth,firestore,storage
```

### Watch Mode (Auto-rebuild)

```bash
npm run build:watch
```

### Run Linting

```bash
npm run lint
npm run lint:fix
```

## 🔑 Function Examples

### Call a Cloud Function from Flutter

You've already done this in your Flutter app! Here's how it works:

```dart
// Example: Call the generateTrends function
final callable = FirebaseFunctions.instance.httpsCallable('generateTrends');

try {
  final result = await callable.call({
    'days': 30
  });
  print('Trends: ${result.data}');
} catch (e) {
  print('Error: $e');
}
```

### Trigger a Scheduled Function

Scheduled functions run automatically (no user action needed):
- Daily stats aggregation: Every day at 1 AM UTC
- Weekly reports: Every Monday at 9 AM UTC
- Data backups: Every day at 2 AM UTC
- Temp file cleanup: Every day at 3 AM UTC

### Use Firestore Rules

Rules are automatically enforced:
```dart
// Users can only write to their own tracker entries
// This is validated by firestore.rules before saving

final entriesRef = FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('tracker_entries');

// This succeeds only if rules allow it
await entriesRef.doc(entryId).set(trackerEntry);
```

## 🔒 Security

### Built-in Protections
1. **Authentication**: User must be logged in
2. **Authorization**: Users can access their own health data; admin/support access requires trusted custom claims
3. **Validation**: Profile, tracker, support, and health writes are bounded by Firestore rules
4. **Storage**: Uploads are owner-scoped, type/size limited, and do not have a broad user-path write rule
5. **Email**: The callable email queue is admin-only and validates bounded message fields
6. **Rate limiting**: The exported helper uses an atomic fixed-window counter and fails closed, but callers must invoke it explicitly

### Admin Setup

From `sicklecare_backend/functions`, set administrator claims only in a trusted environment using the Firebase Admin SDK. Never let a client set custom claims or treat a profile document's `role` field as authorization:
```bash
node -e "const admin=require('firebase-admin'); admin.initializeApp(); (async()=>{const uid=process.argv[1]; const user=await admin.auth().getUser(uid); await admin.auth().setCustomUserClaims(uid,{...(user.customClaims||{}),admin:true})})().then(()=>process.exit(0)).catch(e=>{console.error(e);process.exit(1)})" USER_UID
```

Run this only where Application Default Credentials are configured for an authorized operator. Ask the user to refresh their ID token after changing claims.

## 📊 Firestore Collections

```
/users/{userId}
  ├── profile
  ├── settings
  ├── tracker_entries/{entryId}
  ├── processed_tracker_entries/{entryId}
  ├── tracker_entries/{entryId}
  ├── reminders/{reminderId}
  └── reports/{reportId}

/analytics/{userId}
  └── aggregated health stats

/notifications/{userId}/history/{notificationId}
  └── notification history

/support/{ticketId}
  └── support tickets

/support_messages/{messageId}
  └── Admin dashboard support inbox

/content/{contentId}
  └── Public app content; admin writes only

/audit_logs/{logId}
  └── operation logs

/backups/{backupId}
  └── backup metadata
```

`tracker_entries` is the canonical Flutter health record path. Older
`health/{date}` records are not automatically migrated. `backupUserData`
currently records backup metadata only; it is not a recoverable data backup.

## 🚨 Troubleshooting

### Functions not deploying?
```bash
# Make sure you're authenticated
firebase login

# Check project is set
firebase projects:list

# Try building locally first
cd functions
npm run build
```

### Getting permission errors?
- Make sure your Firebase project is set correctly in `.firebaserc`
- Check that you're logged in: `firebase logout && firebase login`

### Emulator not starting?
```bash
# Make sure Java is installed
java -version

# Try clearing cache
rm -rf ~/.firebase
firebase emulators:start --only functions
```

## 📚 Next Steps

1. **Review Security Rules**
   - Edit `firestore.rules` to match your requirements
   - Test rules with the Firebase Emulator

2. **Deploy to Firebase**
   - Run `firebase deploy` to push everything live

3. **Test Cloud Functions**
   - Call functions from your Flutter app
   - Monitor logs: `firebase functions:log`

4. **Monitor Usage**
   - Check Firebase Console for usage stats
   - Set up billing alerts

5. **Iterate**
   - Add more functions as needed
   - Update rules based on feedback
   - Monitor performance

## 🎓 Learning Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Cloud Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)

## 🆘 Support

For issues or questions:
1. Check Firebase error messages in the console
2. Review function logs: `firebase functions:log`
3. Check the Firestore Rules Playground in Firebase Console
4. Consult the official Firebase documentation

## ✨ Success Indicators

Your backend is working correctly when:
- ✅ `firebase deploy` completes without errors
- ✅ Functions appear in Firebase Console
- ✅ Flutter app can call Cloud Functions
- ✅ Security rules are active
- ✅ Data is visible in Firestore Console

---

**Good luck with your backend development! 🚀**