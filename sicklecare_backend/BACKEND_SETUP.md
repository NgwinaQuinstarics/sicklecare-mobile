# SickleCare Backend Setup Guide

## 🎯 Overview
This is the Firebase-based backend for the SickleCare health management application. You already have Firebase set up in your Flutter app, so this backend extends and enhances that setup with Cloud Functions and advanced configurations.

## ✅ What's Already Done

Your Flutter app (`sicklecare_app`) already has:
- ✅ Firebase Authentication
- ✅ Cloud Firestore database
- ✅ Basic data structure
- ✅ Real-time updates

## 🚀 What We're Adding (Backend Folder)

The new `sicklecare_backend` folder contains:

1. **Enhanced Security Rules** (`firestore.rules`)
   - Role-based access control (Patient, Doctor, Admin, Caregiver)
   - Data validation at database level
   - Rate limiting rules

2. **Storage Security** (`storage.rules`)
   - Secure file upload/download
   - File type and size validation
   - User-specific storage buckets

3. **Firestore Indexes** (`firestore.indexes.json`)
   - Optimized queries for health data
   - Fast searches and aggregations

4. **Cloud Functions** (`functions/`)
   - User management (onCreate, onDelete, profile updates)
   - Health data validation and analytics
   - Notification/reminder scheduling
   - Report generation
   - Data backup automation

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
└── README.md                # Full documentation
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
- `onUserDelete`: Clean up user data when account is deleted
- `updateUserProfile`: Update user settings/profile

#### Health Functions
- `validateHealthEntry`: Validate daily health logs
- `processHealthAnalytics`: Calculate health insights
- `exportHealthData`: Export user data as JSON/CSV

#### Notification Functions
- `scheduleReminders`: Create medication/hydration reminders
- `sendNotification`: Send push notifications to user
- `processNotificationQueue`: Scheduled job to trigger reminders

#### Analytics Functions
- `aggregateDailyStats`: Daily automated aggregation
- `generateTrends`: Calculate health trends for user
- `backupUserData`: Automated daily backups
- `getUserStats`: Get user statistics summary

#### Report Functions
- `generateHealthReport`: Create health reports (PDF/JSON)
- `sendWeeklyReport`: Automated weekly report distribution

#### Utility Functions
- `cleanupTempFiles`: Remove old temporary files
- `sendEmail`: Queue emails for sending
- `validateApiKey`: Validate API keys for integrations
- `getSystemHealth`: Health check endpoint

## 💻 Local Development

### Test Cloud Functions Locally

```bash
cd functions
npm run serve
```

This starts the Firebase emulator at http://localhost:5001

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
// Users can only write to their own health data
// This is validated by firestore.rules before saving

final healthRef = FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('health');

// This succeeds only if rules allow it
await healthRef.doc(date).set(healthData);
```

## 🔒 Security

### Built-in Protections
1. **Authentication**: User must be logged in
2. **Authorization**: Users can only access their own data (with exceptions for admins/doctors)
3. **Validation**: All data is validated before saving
4. **Rate Limiting**: Prevents abuse by limiting requests
5. **Audit Logging**: Tracks sensitive operations

### Admin Setup

To create an admin user:
```bash
firebase auth:set-custom-claims <uid> --claims '{"admin":true}'
```

To create a doctor user:
```bash
firebase auth:set-custom-claims <uid> --claims '{"doctor":true}'
```

## 📊 Firestore Collections

```
/users/{userId}
  ├── profile
  ├── settings
  ├── health/{date}
  ├── reminders/{reminderId}
  └── reports/{reportId}

/analytics/{userId}
  └── aggregated health stats

/notifications/{userId}/history/{notificationId}
  └── notification history

/support/{ticketId}
  └── support tickets

/audit_logs/{logId}
  └── operation logs

/backups/{backupId}
  └── backup metadata
```

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