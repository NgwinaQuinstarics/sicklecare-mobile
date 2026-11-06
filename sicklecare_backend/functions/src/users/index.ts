import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * User Management Functions
 * 
 * These functions handle user lifecycle events and profile management
 */

/**
 * Triggered when a new user is created in Firebase Auth
 * Creates initial user profile in Firestore
 */
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  try {
    const userRef = db.collection('users').doc(user.uid);
    
    // Create initial user profile
    await userRef.set({
      uid: user.uid,
      email: user.email || '',
      displayName: user.displayName || '',
      photoURL: user.photoURL || '',
      role: 'patient', // Default role
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      settings: {
        notifications: {
          enabled: true,
          medication: true,
          hydration: true,
          appointment: true
        },
        privacy: {
          shareHealthData: false,
          shareWithDoctors: false,
          anonymousAnalytics: true
        },
        preferences: {
          language: 'en',
          theme: 'light',
          measurementSystem: 'metric'
        }
      },
      healthStats: {
        totalEntries: 0,
        lastEntryDate: null,
        averagePainLevel: 0,
        averageHydration: 0,
        streakDays: 0
      }
    });

    console.log(`User profile created for: ${user.uid}`);
    
    return null;
  } catch (error) {
    console.error('Error creating user profile:', error);
    throw error;
  }
});

/**
 * Triggered when a user is deleted from Firebase Auth
 * Removes user-owned Firestore and Storage data after account deletion.
 */
export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  try {
    const userRef = db.collection('users').doc(user.uid);

    await Promise.all([
      deleteCollection(userRef.collection('health'), 100),
      deleteCollection(userRef.collection('tracker_entries'), 100),
      deleteCollection(userRef.collection('processed_tracker_entries'), 100),
      deleteCollection(userRef.collection('reminders'), 100),
      deleteCollection(userRef.collection('settings'), 100),
      deleteCollection(userRef.collection('profile'), 100),
      deleteCollection(
        db.collection('notifications').doc(user.uid).collection('history'),
        100,
      ),
      deleteQuery(
        db.collection('support_messages').where('uid', '==', user.uid),
        100,
      ),
      deleteQuery(
        db.collection('reports').where('userId', '==', user.uid),
        100,
      ),
      deleteQuery(
        db.collection('backups').where('userId', '==', user.uid),
        100,
      ),
      db.collection('analytics').doc(user.uid).delete(),
      admin.storage().bucket().deleteFiles({ prefix: `users/${user.uid}/` }),
    ]);

    await userRef.delete();
    console.log(`User data cleaned up for: ${user.uid}`);
    return null;
  } catch (error) {
    console.error('Error deleting user data:', error);
    throw error;
  }
});

/**
 * Updates user profile information
 * Can be called via HTTP or triggered by other events
 */
export const updateUserProfile = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { displayName, photoURL, settings } = data;

  try {
    const userRef = db.collection('users').doc(userId);
    
    const updateData: any = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    if (displayName !== undefined) {
      updateData.displayName = displayName;
    }

    if (photoURL !== undefined) {
      updateData.photoURL = photoURL;
    }

    if (settings !== undefined) {
      updateData.settings = settings;
    }

    await userRef.update(updateData);
    
    console.log(`User profile updated for: ${userId}`);
    
    return {
      success: true,
      message: 'Profile updated successfully'
    };
  } catch (error) {
    console.error('Error updating user profile:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update profile'
    );
  }
});

/**
 * Helper function to delete a collection in batches
 */
async function deleteCollection(
  collectionRef: FirebaseFirestore.CollectionReference,
  batchSize: number
): Promise<void> {
  await deleteQuery(collectionRef.orderBy('__name__'), batchSize);
}

async function deleteQuery(
  query: FirebaseFirestore.Query,
  batchSize: number
): Promise<void> {
  let snapshot = await query.limit(batchSize).get();
  while (!snapshot.empty) {
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    if (snapshot.size < batchSize) return;
    snapshot = await query.limit(batchSize).get();
  }
}

/**
 * Export user functions
 */
export const userFunctions = {
  onUserCreate,
  onUserDelete,
  updateUserProfile
};