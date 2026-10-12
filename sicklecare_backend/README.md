# SickleCare Firebase Backend

This is the Firebase backend for the SickleCare mobile application. It extends the existing Firebase setup with Cloud Functions, enhanced security rules, and additional Firebase services.

## 🔥 Existing Firebase Setup
Your Flutter app already uses:
- ✅ **Firebase Authentication** (Email/Password)
- ✅ **Cloud Firestore** (NoSQL database)
- ✅ **Cloud Functions** (Serverless functions)
- ✅ **Firebase Hosting** (Optional for web)

## 🚀 What We're Adding

### 1. Enhanced Cloud Functions
- **Analytics processing** - Process health data for insights
- **Notification scheduling** - Smart reminder system
- **Data validation** - Validate health entries
- **Report generation** - Generate health reports
- **Backup automation** - Automated data backups

### 2. Advanced Security Rules
- **Role-based access** (Patients, Doctors, Admins)
- **Data validation rules** 
- **Rate limiting** in security rules
- **Audit logging** for sensitive operations

### 3. Firebase Extensions
- **Schedule exports** - Automatically export data
- **Algolia search** - Fast search for health records
- **Stripe payments** - For premium features (optional)
- **Translation** - Multi-language support

### 4. Monitoring & Analytics
- **Firebase Analytics** - User behavior tracking
- **Crashlytics** - Error reporting
- **Performance Monitoring** - App performance
- **Remote Config** - Feature flags and A/B testing

## 📁 Project Structure
```
sicklecare_backend/
├── firebase.json           # Firebase configuration
├── .firebaserc            # Firebase project aliases
├── firestore.rules        # Firestore security rules
├── firestore.indexes.json # Firestore indexes
├── storage.rules          # Firebase Storage rules
├── functions/             # Cloud Functions
│   ├── src/
│   │   ├── analytics/     # Analytics functions
│   │   ├── notifications/ # Notification functions
│   │   ├── users/         # User management functions
│   │   ├── health/        # Health data functions
│   │   ├── reports/       # Report generation
│   │   └── utils/         # Utility functions
│   ├── package.json       # Functions dependencies
│   └── index.ts          # Functions entry point
├── extensions/            # Firebase extensions config
└── documentation/        # Backend documentation
```

## 🛠️ Tech Stack (Continuing with Firebase)
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore (NoSQL)
- **Serverless**: Cloud Functions (Node.js)
- **Storage**: Firebase Storage
- **Hosting**: Firebase Hosting
- **Monitoring**: Firebase Analytics, Crashlytics
- **ML**: Firebase ML Kit (for health insights)

## 🚀 Getting Started

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### 2. Initialize Firebase (if not done)
```bash
cd sicklecare_backend
firebase init
```
Select:
- ☑️ Functions
- ☑️ Firestore
- ☑️ Storage
- ☑️ Hosting (optional)

### 3. Deploy Backend
```bash
# Deploy everything
firebase deploy

# Deploy specific services
firebase deploy --only functions
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

### 4. Environment Setup
Create `.env` file in `functions/` directory:
```env
# Firebase Admin SDK (auto-configured)
# Add any API keys for external services
SENDGRID_API_KEY=your_sendgrid_key
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
STRIPE_SECRET_KEY=your_stripe_key
```

## 🔧 Cloud Functions Structure

### User Management Functions
- `onUserCreate` - Initialize user profile
- `onUserDelete` - Clean up user data
- `updateUserProfile` - Update user information

### Health Data Functions
- `validateHealthEntry` - Validate daily health logs
- `processHealthAnalytics` - Generate health insights
- `generateHealthReport` - Create PDF health reports

### Notification Functions
- `scheduleReminders` - Schedule medication reminders
- `sendNotification` - Send push notifications
- `processNotificationQueue` - Process notification queue

### Analytics Functions
- `aggregateDailyStats` - Aggregate daily statistics
- `generateTrends` - Generate health trends
- `exportUserData` - Export user data for download

## 🔐 Security Rules Examples

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /health/{healthId} {
        allow read: if request.auth.uid == userId;
        allow write: if request.auth.uid == userId 
          && request.resource.data.userId == userId;
      }
    }
    
    // Admins can read all data
    match /admin/{document=**} {
      allow read, write: if request.auth.token.admin == true;
    }
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can upload their own health documents
    match /users/{userId}/health/{allPaths=**} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## 📊 Database Schema

### Collections Structure
```
/users/{userId}
  ├── profile (document)
  ├── settings (document)
  └── health/{date} (documents - daily entries)
     ├── hydration: number
     ├── painLevel: number
     ├── meals: array
     ├── medications: array
     └── timestamp: timestamp

/reminders/{reminderId}
  ├── userId: string
  ├── title: string
  ├── type: 'medication' | 'hydration' | 'appointment'
  ├── time: timestamp
  ├── repeat: 'daily' | 'weekly' | 'custom'
  └── active: boolean

/support/{ticketId}
  ├── userId: string
  ├── subject: string
  ├── message: string
  ├── status: 'open' | 'in-progress' | 'resolved'
  └── createdAt: timestamp

/analytics/{userId}
  ├── dailyStats: map
  ├── weeklyTrends: map
  ├── monthlyReports: map
  └── lastUpdated: timestamp
```

## 🔄 Integration with Flutter App

### Existing Integration (Already Working)
```dart
// Your Flutter app already has:
FirebaseAuth.instance // Authentication
FirebaseFirestore.instance // Database
FirebaseFunctions.instance // Cloud Functions
```

### Enhanced Integration
```dart
// We'll add:
FirebaseStorage.instance // File uploads
FirebaseAnalytics.instance // Analytics
FirebaseCrashlytics.instance // Error reporting
FirebaseRemoteConfig.instance // Feature flags
```

## 💰 Cost Optimization

### Free Tier (Spark Plan)
- 10GB Firestore storage
- 50K Firestore reads/day
- 20K Firestore writes/day
- 20K Firestore deletes/day
- 125K Cloud Function invocations/month
- 2GB Cloud Function compute time/month

### Tips to Stay in Free Tier
1. **Use Firestore efficiently** - Batch writes, use pagination
2. **Cache data locally** - Use Hive/shared_preferences
3. **Optimize functions** - Use triggers wisely
4. **Monitor usage** - Set up billing alerts

## 🚨 Monitoring & Alerts

### Firebase Console Monitoring
- **Usage metrics** - Track database reads/writes
- **Function execution time** - Optimize slow functions
- **Error rates** - Monitor for issues
- **User analytics** - Track feature usage

### Billing Alerts
Set up billing alerts at:
1. Google Cloud Console → Billing → Budgets & alerts
2. Set threshold at $1 (to get notified before charges)

## 📈 Scaling Strategy

### Phase 1: Free Tier (Current)
- Basic Firestore usage
- Simple Cloud Functions
- < 100 users

### Phase 2: Blaze Plan (Pay-as-you-go)
- Add more Cloud Functions
- Increase database operations
- Add Firebase Extensions
- 100-10,000 users

### Phase 3: Enterprise Features
- Custom domain for hosting
- Increased security features
- Premium support
- > 10,000 users

## 👥 Team Collaboration

### Frontend Team (Flutter)
- Works with existing Firebase SDK
- No changes needed to current implementation
- Can mock Firestore data for testing

### Backend Team (You)
- Focus on Cloud Functions
- Enhance security rules
- Implement new Firebase features
- Monitor and optimize costs

## 📞 Support & Resources

### Firebase Documentation
- [Firebase Documentation](https://firebase.google.com/docs)
- [Cloud Functions Guide](https://firebase.google.com/docs/functions)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

### Community
- [Firebase Community](https://firebase.community/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase)
- [Firebase YouTube Channel](https://www.youtube.com/user/Firebase)

## 🎯 Next Steps

1. **Review existing Firebase setup** - Check what's already working
2. **Enhance security rules** - Add role-based access control
3. **Add Cloud Functions** - Start with analytics processing
4. **Implement monitoring** - Set up Firebase Analytics
5. **Optimize costs** - Set up billing alerts

## 📄 License
Proprietary - SickleCare Project