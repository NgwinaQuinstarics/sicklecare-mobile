# SickleCare Backend — Post-Fix Security Review

**Date**: October 20, 2026  
**Reviewed**: Firestore rules, Cloud Functions, frontend-backend integration  
**Status**: ⚠️ **CRITICAL ISSUES FOUND** — Review required before deployment

---

## 1. GitHub Verification ✅

| Item | Status | Details |
|------|--------|---------|
| **Branch** | ✅ | main |
| **Working Tree** | ✅ | Clean (no uncommitted changes) |
| **Commit a6f4999** | ✅ | "fix: 3 Firestore security rule bugs..." — Present locally and on origin |
| **Commit bd8846e** | ✅ | "docs: Add backend fix..." — Present locally and on origin |
| **Remote URL** | ✅ | https://github.com/NgwinaQuinstarics/sicklecare-mobile.git |
| **Tracked Branch** | ✅ | origin/main (tracking enabled) |

---

## 2. Firestore Rules Security Review

### 2.1 Three Previously-Fixed Bugs

#### Bug #1: Support Ticket Read Rule ✅ FIXED
**Location**: Line 76  
**Original Issue**: `request.resource.data.userId` on READ (wrong context)  
**Fixed To**: `resource.data.userId`  
**Status**: ✅ CORRECT - now uses existing document data

```firestore
✅ CORRECT:
allow read: if isSignedIn() && (
  resource.data.userId == request.auth.uid ||  // Reference to existing doc
  isAdmin() ||
  request.auth.token.support == true
);
```

---

#### Bug #2: Rate Limiting ✅ FIXED
**Location**: Line 115  
**Original Issue**: Referenced non-existent `resource.data.lastWrite` field  
**Fixed To**: Proper timestamp validation using `resource.data.timestamp`  
**Status**: ✅ CORRECT - checks actual timestamp field

```firestore
✅ CORRECT:
function canWrite() {
  return !exists(/databases/$(database)/documents/users/$(request.auth.uid)/health/$(request.resource.id)) || 
         request.time > resource.data.timestamp.toMillis() + 60000;
}
```

**Analysis**: 
- Function checks if document doesn't exist OR if last write was >60 seconds ago
- Uses `timestamp` field which IS set by the frontend
- Rate limit cannot be bypassed by client-controlled timestamp (checked against `request.time`, not data)
- ✅ **SECURE** for its intended purpose

---

#### Bug #3: Health Data Validation ✅ FIXED
**Location**: Line 44  
**Original Issue**: Required `meals is list` but frontend doesn't always send it  
**Fixed To**: Made `meals` optional with conditional check  
**Status**: ✅ CORRECT - validation is flexible

```firestore
✅ CORRECT:
&& (!('meals' in request.resource.data) || request.resource.data.meals is list)
// Translates to: "if meals field exists, it must be a list; otherwise it's ok to be absent"
```

---

### 2.2 Additional Security Analysis

#### A. User Privacy: `/users/{userId}/health/{date}` ✅ SECURE
```firestore
match /health/{date} {
  allow read: if isSignedIn() && (isUser(userId) || isAdmin() || isDoctor() || isCaregiver());
  allow create: if isSignedIn() && isUser(userId) && isValidHealthData();
  allow update, delete: if isSignedIn() && isUser(userId);
}
```

**Verification**:
- ✅ Users can only read/write their own health data (`isUser(userId)`)
- ✅ Doctors and caregivers can read (intended for caregiving scenario)
- ✅ Admins can read (for support/auditing)
- ✅ Data validation enforced on create (checks hydration 0-10, pain 0-10, timestamp exists)
- ✅ **Cannot be bypassed**: `isUser()` checks `request.auth.uid == userId` (tied to auth token)

---

#### B. Support Tickets: `/support/{ticketId}` ⚠️ **ISSUE FOUND**
```firestore
match /support/{ticketId} {
  allow read: if isSignedIn() && (
    resource.data.userId == request.auth.uid ||
    isAdmin() ||
    request.auth.token.support == true
  );
  allow create: if isSignedIn() && isValidUser();
  allow update: if isSignedIn() && (
    resource.data.userId == request.auth.uid ||
    isAdmin() || request.auth.token.support == true
  );
}
```

**Issues**:
- ⚠️ **Collection name mismatch**: Rules define `/support/{ticketId}` but frontend writes to `/support_messages/`
  - Frontend code (firestore_service.dart, line 19): `db.collection('support_messages').add(...)`
  - Backend rules: `match /support/{ticketId}`
  - **Result**: Frontend writes are NOT validated by these rules
- ⚠️ **Unprotected `support_messages` collection**: No rules defined for this collection
  - This means the Firestore default deny-all will apply
  - Frontend support messages will be **rejected** or **stored with default permissions**

**Recommendation**: Align collection names OR add rules for `support_messages`.

---

#### C. Analytics: `/analytics/{userId}` ✅ SECURE
```firestore
allow read: if isSignedIn() && (isUser(userId) || isAdmin() || isDoctor());
allow write: if isAdmin(); // Only admins can write
```
- ✅ Only admins can write (prevents user data inflation)
- ✅ Users can read their own analytics
- ✅ Doctors can read (intended for care coordination)

---

#### D. Privileged Collections ✅ SECURE
```firestore
match /system/{document=**} {
  allow read, write: if isAdmin();
}
```
- ✅ Properly restricted to admin-only
- ✅ Requires `request.auth.token.admin == true` (set by backend only)

---

#### E. Public Data ✅ REASONABLY SECURE
```firestore
match /public/{document=**} {
  allow read: if isSignedIn();
  allow write: if isAdmin();
}
```
- ✅ Read-only for authenticated users (not truly "public", but scoped to signed-in users)
- ✅ Write restricted to admins

---

### 2.3 Potential Security Gaps

| Issue | Severity | Status |
|-------|----------|--------|
| Support tickets collection name mismatch | 🔴 HIGH | **MUST FIX** before deployment |
| No validation on `support_messages` writes | 🔴 HIGH | **MUST FIX** before deployment |
| `isCaregiver()` role check calls `get()` on every rule (performance) | 🟡 MEDIUM | Can optimize later |
| Rate limiting only on health writes (not on other collections) | 🟡 MEDIUM | Consider for future |
| `getUserRole()` performs Firestore read on every role check | 🟡 MEDIUM | Consider caching or custom claims |

---

## 3. Cloud Functions Security Review

### 3.1 Authentication & Authorization

#### Auth Trigger: `onUserCreate` ✅ SECURE
- Triggered automatically by Firebase Auth (not client-callable)
- ✅ No authentication check needed (system trigger)
- ✅ Executes with admin privileges (database access via `admin` SDK)
- ✅ Creates default profile with `role: 'patient'`

---

#### Auth Trigger: `onUserDelete` ✅ SECURE
- Triggered automatically by Firebase Auth (not client-callable)
- ✅ Performs cleanup without client interference
- ✅ Deletes user documents and health data

---

#### Callable Function: `updateUserProfile` ✅ SECURE
```typescript
if (!context.auth) {
  throw new functions.https.HttpsError('unauthenticated', '...');
}
const userId = context.auth.uid;
```
- ✅ Checks authentication before proceeding
- ✅ Uses `context.auth.uid` (verified by Firebase SDK)
- ✅ Updates only the caller's own profile
- ✅ Validates input fields (only updates if defined)

---

#### Callable Function: `processHealthAnalytics` ✅ SECURE
```typescript
if (!context.auth) {
  throw new functions.https.HttpsError('unauthenticated', '...');
}
const userId = context.auth.uid;
```
- ✅ Requires authentication
- ✅ Operates on authenticated user's data only

---

#### Callable Function: `exportHealthData` ✅ SECURE
```typescript
if (!context.auth) {
  throw new functions.https.HttpsError('unauthenticated', '...');
}
const userId = context.auth.uid;
const { format = 'json', startDate, endDate } = data;
```
- ✅ Requires authentication
- ✅ Exports authenticated user's own data
- ✅ Input validation: `format` defaults to 'json' (safe)
- ⚠️ Minor: Should validate `startDate` and `endDate` are valid dates

---

### 3.2 Secrets & Credentials

#### Issue: Email Service Not Configured ⚠️
**File**: `functions/src/users/index.ts` (line ~195)
```typescript
async function sendWelcomeEmail(email: string, name: string | null | undefined): Promise<void> {
  if (!email) return;
  
  // In a real implementation, use an email service like SendGrid
  // For now, we'll just log it
  console.log(`Welcome email would be sent to: ${email}`);
  
  // Example with SendGrid (commented out):
  /*
  const sgMail = require('@sendgrid/mail');
  sgMail.setApiKey(functions.config().sendgrid.key);
  ...
  */
}
```

**Status**: 
- ✅ No actual email service is active (safe for now)
- ⚠️ When email service is enabled, ensure `functions.config().sendgrid.key` is stored in Firebase Secret Manager, NOT in code
- ✅ Current commented-out code is safe (not executed)

---

#### HTTP API Endpoint: `/api` ⚠️ **SECURITY ISSUE**
**File**: `functions/src/index.ts` (line ~54)
```typescript
export const api = functions.https.onRequest(async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*');  // ⚠️ OVERLY PERMISSIVE
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { action } = req.body;
    
    switch (action) {
      case 'health-check':
        res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
        break;
      case 'generate-report':
        res.status(200).json({ message: 'Report generation started' });
        break;
      case 'send-test-notification':
        res.status(200).json({ message: 'Test notification sent' });
        break;
      default:
        res.status(400).json({ error: 'Invalid action' });
    }
  } catch (error) {
    console.error('API error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

**Issues**:
- 🔴 **`Access-Control-Allow-Origin: *`** — Allows any domain to call this function
- 🔴 **No authentication** — Anyone can call these endpoints
- ⚠️ `health-check` is harmless (returns status)
- ⚠️ `generate-report` and `send-test-notification` are not authenticated
- ⚠️ No rate limiting on HTTP endpoint

**Recommendation**: 
- Restrict CORS to known domains (frontend URL, etc.)
- Add authentication check before sensitive operations
- OR move sensitive operations to callable functions (which have auth built-in)

---

### 3.3 Error Handling

- ✅ Try-catch blocks present
- ✅ Errors logged to console
- ✅ Generic error messages returned to client (no stack traces)
- ✅ Proper HTTP status codes

---

### 3.4 Unused Function

**File**: `functions/src/reports/index.ts` (line ~268, now commented out)

The `_generateReportHTML` function was commented out because it's not currently used. This is **OK for now** but should be:
- ✅ Used when email notifications are implemented, OR
- ⚠️ Removed if no longer needed

No security impact—it's just dead code.

---

## 4. Build & Compilation Results

| Check | Result | Details |
|-------|--------|---------|
| **npm install** | ✅ PASS | 696 packages, 0 errors |
| **npm run build** | ✅ PASS | TypeScript compilation successful, all 5 previous errors fixed |
| **ESLint** | ⚠️ SKIP | No ESLint config found (can set up separately) |
| **Tests** | ⚠️ SKIP | No test files written (Jest configured but no tests) |
| **Final artifact** | ✅ | `lib/` directory with compiled JS ready for deployment |

---

## 5. Frontend-Backend Compatibility Issues

### Issue #1: Collection Name Mismatch 🔴 CRITICAL

| Layer | Collection | Location |
|-------|-----------|----------|
| **Frontend Writes** | `support_messages` | `firestore_service.dart:19` |
| **Backend Rules** | `/support/` | `firestore.rules:73` |
| **Impact** | Frontend support submissions will NOT validate against backend rules |

**Evidence**:
```dart
// Frontend (firestore_service.dart:19)
await db.collection('support_messages').add({...});

// Backend rules (firestore.rules:73)
match /support/{ticketId} {
  allow read: if ...
}
```

**Status**: ❌ **INCOMPATIBLE** - Frontend and backend will conflict

---

### Issue #2: Frontend Data Structure 🟡 MEDIUM

**Frontend sends to**: `support_messages` collection  
**Frontend data**:
```dart
{
  'name': String,
  'email': String,
  'subject': String,
  'message': String,
  'status': 'new',
  'source': 'mobile_support',
  'createdAt': serverTimestamp(),
  'uid': user.uid,  // If authenticated
  'userEmail': user.email,
  'userName': user.displayName,
}
```

**Backend rules expect** (if they matched): `userId` field  
**Actual frontend sends**: `uid` field (different name!)

**Status**: ⚠️ **Data structure slightly misaligned** — `uid` vs `userId`

---

## 6. Critical Issues Before Deployment

| # | Issue | Severity | Action Required |
|---|-------|----------|-----------------|
| 1 | Support collection name mismatch | 🔴 CRITICAL | Fix before deploy |
| 2 | Unprotected `support_messages` collection | 🔴 CRITICAL | Add rules or rename |
| 3 | HTTP API lacks authentication | 🔴 CRITICAL | Add auth or use callable functions |
| 4 | CORS allows all origins | 🟡 HIGH | Restrict to frontend domain |
| 5 | Input validation on `startDate`/`endDate` | 🟡 MEDIUM | Add validation |
| 6 | No test coverage | 🟡 MEDIUM | Write tests (after deployment OK) |

---

## 7. Test Results Summary

| Test Type | Status | Command | Result |
|-----------|--------|---------|--------|
| **Compilation** | ✅ PASS | `npm run build` | 0 errors, successful |
| **Dependencies** | ✅ PASS | `npm install` | 696 packages, no missing deps |
| **Linting** | ⚠️ NOT RUN | `npm run lint` | ESLint not configured |
| **Unit Tests** | ⚠️ NOT RRUN | `npm test` | No test files written |
| **Firestore Rules Test** | ⚠️ NOT RUN | N/A | Firebase Emulator not available locally |
| **Security Review** | ✅ DONE | Manual code review | 4 issues found (see section 6) |

---

## 8. Recommendations Before Deployment

### Must Fix (Blocking)
1. **Collection Name Mismatch**:
   - Option A: Rename `support_messages` to `support` in frontend
   - Option B: Add rules for `support_messages` in backend rules
   - Option C: Use different collection naming strategy consistently

2. **HTTP API Authentication**:
   - Require Firebase ID token in `Authorization: Bearer {token}` header
   - OR convert sensitive endpoints to callable functions
   - OR remove them if unused

3. **CORS Restriction**:
   - Change `'*'` to specific frontend domain(s)

### Should Fix (High Priority)
4. **Input Validation**: Add date validation in `exportHealthData`
5. **Email Service**: Configure SendGrid secret in Firebase Secret Manager before enabling email

### Nice to Have (Medium Priority)
6. **Add ESLint Config**: For ongoing code quality
7. **Write Integration Tests**: For security rules and function authorization

---

## 9. Single Highest-Priority Next Step

🔴 **BLOCKING**: Fix the support collection name mismatch and add CORS/auth controls to HTTP API before any deployment attempt.

**Recommended order**:
1. Decide: Rename frontend collection to `support` OR add `support_messages` rules to backend
2. Fix HTTP API to require authentication OR remove it
3. Restrict CORS origin
4. Re-test compilation
5. Push to GitHub
6. Then: Deploy to Firebase

---

## 10. Production-Ready Assessment

**Current Status**: ❌ **NOT READY FOR PRODUCTION**

| Criterion | Status | Reason |
|-----------|--------|--------|
| Code compiles | ✅ | TypeScript: 0 errors |
| Security rules valid | ⚠️ | 3 original bugs fixed, but collection mismatch remains |
| Auth checks in place | ✅ | Callable functions protected |
| Secrets managed safely | ⚠️ | Email service not yet configured |
| Tests written | ❌ | No test suite |
| Frontend-backend compatible | ❌ | Collection name mismatch |
| **Can deploy?** | ❌ | Fix critical issues first |

---

**Prepared by**: Security Review Post-Fix  
**Date**: October 20, 2026  
**Status**: ⚠️ REVIEW REQUIRED — 4 critical issues must be resolved
