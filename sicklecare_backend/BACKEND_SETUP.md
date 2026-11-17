# SickleCare Backend Setup Guide

## 🎯 Overview
This is the Firebase-based backend for the SickleCare health management application. You already have Firebase set up in your Flutter app, so this backend extends and enhances that setup with Cloud Functions and advanced configurations.

## ✅ What's Already Done

The Flutter app in `sicklecare_app/` uses:
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
   - Doctor/admin privileges come only from verified Firebase Auth custom
     claims; clients cannot write application status or request elevated roles

2. **Credential storage**
   - Doctor credentials are stored in a private AWS S3 bucket, not Firebase
     Cloud Storage.
   - Firebase callable functions authorize short-lived upload and review URLs,
     verify file size and signatures, and audit administrator access.
   - Firebase Admin Storage cleanup remains for legacy user files; it is not
     used for new doctor credentials.

3. **Firestore Indexes** (`firestore.indexes.json`)
   - Optimized queries for health data
   - Fast searches and aggregations

4. **Cloud Functions** (`functions/`)
   - Authenticated Sika proxy with App Check, bounded input, and per-user rate limits
   - User-data cleanup when an Auth account is deleted
   - Analytics and JSON/CSV exports for the Flutter tracker schema
   - JSON health reports stored in each user's reports subcollection
   - Validated doctor applications, private credential uploads, and
     administrator-only review, approval, rejection, and reversible
     deactivation/reactivation

## 📋 Prerequisites

1. **Node.js 22** installed
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

### Admin dashboard

The secure web console is a Firebase Hosting SPA under `admin/`. Its overview
fetches registered-account and approved/pending-doctor totals, recent account
registrations, pending doctor applications, and recent support/contact
requests. It also provides a paginated account directory, live support/contact
inbox, request status changes, and home-content publishing. Dashboard content and
inbox mutations go through admin-claim protected, rate-limited callables and
write metadata-only records to `admin_audit_logs`. Individual user details and
synced tracker entries are available on demand from the user directory through
an admin-only, read-only, paginated callable; each request is recorded in the
audit log without including health details. Records still stored only on a
device are not available to the dashboard. Firestore client rules deny admin
reads of user profile and tracker documents, so sensitive user data must go
through this audited callable.

The **Doctor review** section lists server-paginated applications. Credential
access is separately authorized by an admin callable, recorded in the audit
log, and uses a five-minute, private S3 URL rather than a public download URL.
Approval assigns the trusted `doctor: true` Auth claim. Rejection retains the
application and credential history; deactivation disables sign-in, removes the
doctor claim, revokes refresh tokens, and retains records. Only an administrator
can reactivate a deactivated account.

Run the console locally:

```bash
cd sicklecare_backend/admin
npm ci
npm run dev
```

For isolated local integration testing, copy `.env.example` to `.env.local`
and run the Auth, Firestore, and Functions emulators first. The web app will
then connect only to local emulator endpoints.

Authorize administrators only through a trusted Firebase Admin SDK process
(see the custom-claim instructions below). A successful sign-in without the
literal boolean `admin: true` claim is denied access. Update the Firebase
Hosting authorized domains and review the Content Security Policy before
deploying Hosting. The Hosting site is explicitly configured as
`sicklecare-15d7a`.

Cloud Functions deployment requires the Firebase project to use the Blaze
(pay-as-you-go) plan so Firebase can enable Cloud Build and related APIs.
Review the expected usage and configure billing alerts before upgrading. The
dashboard depends on its callable functions; deploying Hosting without those
functions does not make the dashboard data workflows operational. Review production dependency advisories
with `npm audit --omit=dev` before launch. The current Functions dependency
tree has seven moderate uuid advisories in transitive Google/Firebase packages;
the production audit reports no high or critical advisories. Do not apply
`npm audit fix --force` without reviewing the proposed major-version upgrades
and validating the Functions.

Doctor credential storage also requires a private S3 bucket before deploying
the credential upload/review functions:

1. Enable S3 Block Public Access and default SSE-S3 (AES-256) encryption on the
   bucket. Do not configure public ACLs or public-read bucket policies.
2. Create an AWS IAM user whose policy grants only `s3:GetObject` and
   `s3:PutObject` on `arn:aws:s3:::YOUR_BUCKET/doctor_credentials/*`.
   Rotate its access keys periodically.
3. Store the access key pair in Firebase Secret Manager. The CLI prompts for
   each secret value; never commit or paste the values into source files:

   ```bash
   firebase functions:secrets:set AWS_ACCESS_KEY_ID --project sicklecare-15d7a
   firebase functions:secrets:set AWS_SECRET_ACCESS_KEY --project sicklecare-15d7a
   ```

4. Create `functions/.env.sicklecare-15d7a` with the bucket name and region.
   This file is ignored by Git:

   ```dotenv
   AWS_S3_BUCKET=your-private-bucket-name
   AWS_S3_REGION=eu-west-1
   ```

Previously submitted credentials in Firebase Storage are not copied
automatically. Migrate those objects securely to the private S3 bucket and set
their `credential.storageProvider` to `aws_s3`, or ask those applicants to
resubmit before enabling the new credential review flow.

The admin overview and account-directory callables can be deployed separately
to restore dashboard data while AWS is being configured:

```bash
firebase deploy --only "functions:getAdminDashboardSummary,functions:listAdminUsers,functions:getAdminUserDetails,functions:listAdminAuditLogs,functions:updateAdminInboxStatus,functions:updateAdminHomeContent" --project sicklecare-15d7a
```

After AWS is configured, deploy the full dashboard and doctor-review workflow,
Firestore rules, and Hosting together from this directory:

```bash
firebase deploy --only "functions:getAdminDashboardSummary,functions:listAdminUsers,functions:getAdminUserDetails,functions:listAdminAuditLogs,functions:updateAdminInboxStatus,functions:updateAdminHomeContent,functions:createDoctorApplication,functions:prepareDoctorCredentialResubmission,functions:createDoctorCredentialUpload,functions:finalizeDoctorApplication,functions:listDoctorApplications,functions:getDoctorApplicationCredential,functions:reviewDoctorApplication,firestore:rules,firestore:indexes,hosting" --project sicklecare-15d7a
```

No Firebase service has been deployed by the local build/test commands.

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

#### Admin functions

- `getAdminDashboardSummary`: bounded summary counts for accounts, doctor
  application states, open requests, and recent account/application previews.
- `listAdminUsers`: read-only, paginated Firebase Auth directory (maximum 50 per page), including the account type saved in each profile.
- `getAdminUserDetails`: returns allowlisted account/profile fields and a bounded page of synced tracker entries for one selected user. Every access writes an audit event; tracker fields are never read directly by the browser.
- `updateAdminInboxStatus`: validates a support/contact status change and records an audit event atomically.
- `updateAdminHomeContent`: validates bounded home copy and records an audit event atomically.
- All admin callables require the trusted boolean `admin` custom claim and are rate-limited. Clients cannot write the admin audit collection.

#### User Functions
- `onUserCreate`: Initialize or fill missing profile defaults when a user signs up without overwriting signup data
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

There is no shared or built-in administrator password. The dashboard signs in
to the same Firebase project as the Flutter app (`sicklecare-15d7a`). To create
an administrator login:

1. In Firebase Console, open **Authentication → Sign-in method** and enable
   **Email/Password** if it is not already enabled.
2. Under **Authentication → Users**, create the administrator's account with
   an individual, organization-controlled email address and a unique password.
   Deliver any temporary password through your approved secure channel and
   change it immediately after sign-in. Do not put credentials in source code,
   chat, or application configuration.
3. Copy the new user's **UID**. From `sicklecare_backend/functions`, run the
   command below in a trusted operator environment after configuring
   Application Default Credentials for the `sicklecare-15d7a` project.
4. Sign in to the dashboard with that Firebase Authentication email and
   password. After granting the claim, sign out and sign back in (or use
   **Refresh access**) so Firebase issues a token containing the new claim.

The claim command preserves existing custom claims. Never let a client set
custom claims or treat a profile document's `role` field as authorization:

```bash
node -e "const admin=require('firebase-admin'); admin.initializeApp({projectId:'sicklecare-15d7a'}); (async()=>{const uid=process.argv[1]; const user=await admin.auth().getUser(uid); await admin.auth().setCustomUserClaims(uid,{...(user.customClaims||{}),admin:true})})().then(()=>process.exit(0)).catch(e=>{console.error(e);process.exit(1)})" USER_UID
```

Run this only where Application Default Credentials are configured for an
authorized operator, with the intended Firebase project selected. Do not
download or commit service-account private keys. A signed-in account without
the literal boolean `admin: true` claim is denied dashboard access.

The dashboard reads Firebase Auth account metadata, the user's saved name,
phone, and genotype, support/contact requests, public home content, and
metadata-only admin audit events. When an administrator explicitly opens a
user's details, the dashboard can also read that user's synced tracker records
(pain score, hydration, mood, and notes) through `getAdminUserDetails`. The
callable requires the trusted admin claim, rate-limits requests, returns only
allowlisted fields in pages of at most 25, and records the actor, target user,
and record count in `admin_audit_logs`. It does not permit health-data writes.

The Flutter app keeps tracker data in local Hive storage and syncs it to
`users/{uid}/tracker_entries` after sign-in. Records that have not synced from
the user's device cannot be fetched remotely. Do not copy health record values
into logs, screenshots, support tickets, or exports.

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