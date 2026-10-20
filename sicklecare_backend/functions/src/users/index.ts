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
    
    // Send welcome email
    if (user.email) {
      await sendWelcomeEmail(user.email, user.displayName);
    }
    
    return null;
  } catch (error) {
    console.error('Error creating user profile:', error);
    throw error;
  }
});

/**
 * Triggered when a user is deleted from Firebase Auth
 * Cleans up user data from Firestore
 */
export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  try {
    const userRef = db.collection('users').doc(user.uid);
    
    // Delete user document
    await userRef.delete();
    
    // Delete user's health data (in batches)
    const healthRef = userRef.collection('health');
    await deleteCollection(healthRef, 100);
    
    // Delete user's reminders
    const remindersRef = userRef.collection('reminders');
    await deleteCollection(remindersRef, 100);
    
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
  const query = collectionRef.orderBy('__name__').limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, batchSize, resolve, reject);
  });
}

async function deleteQueryBatch(
  query: FirebaseFirestore.Query,
  batchSize: number,
  resolve: () => void,
  reject: (error: any) => void
): Promise<void> {
  try {
    const snapshot = await query.get();

    if (snapshot.size === 0) {
      resolve();
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    // Recurse on the next process tick to avoid
    // exploding the stack.
    process.nextTick(() => {
      deleteQueryBatch(query, batchSize, resolve, reject);
    });
  } catch (error) {
    reject(error);
  }
}

/**
 * Send welcome email to new users
 */
async function sendWelcomeEmail(email: string, name: string | null | undefined): Promise<void> {
  if (!email) return;

  // In a real implementation, use an email service like SendGrid
  // For now, we'll just log it
  console.log(`Welcome email would be sent to: ${email}`);
  console.log(`Welcome ${name || 'User'} to SickleCare!`);
  
  // Example with SendGrid (commented out):
  /*
  const sgMail = require('@sendgrid/mail');
  sgMail.setApiKey(functions.config().sendgrid.key);
  
  const msg = {
    to: email,
    from: 'welcome@sicklecare.com',
    subject: 'Welcome to SickleCare!',
    text: `Hello ${name || 'User'},\n\nWelcome to SickleCare! We're excited to help you manage your health.`,
    html: `<strong>Welcome to SickleCare!</strong><p>Hello ${name || 'User'},</p><p>We're excited to help you manage your health.</p>`,
  };
  
  await sgMail.send(msg);
  */
}

/**
 * Export user functions
 */
export const userFunctions = {
  onUserCreate,
  onUserDelete,
  updateUserProfile
};