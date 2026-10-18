import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Notification Functions
 * 
 * These functions handle reminder scheduling and notifications
 */

/**
 * Schedule reminders for users
 */
export const scheduleReminders = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { title, type, time, repeat } = data;

  try {
    // Validate input
    if (!title || !type || !time) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: title, type, time'
      );
    }

    const remindersRef = db.collection('users').doc(userId).collection('reminders');
    
    const reminderData = {
      userId,
      title,
      type, // 'medication', 'hydration', 'appointment', 'checkup'
      time: new Date(time),
      repeat: repeat || 'once', // 'once', 'daily', 'weekly'
      active: true,
      completed: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      nextNotificationTime: new Date(time)
    };

    const docRef = await remindersRef.add(reminderData);

    // Schedule the notification
    await scheduleNotification(userId, reminderData, docRef.id);

    console.log(`Reminder scheduled for user: ${userId}`);

    return {
      success: true,
      reminderId: docRef.id,
      message: 'Reminder scheduled successfully'
    };
  } catch (error) {
    console.error('Error scheduling reminder:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to schedule reminder'
    );
  }
});

/**
 * Send notification to user
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { title, body, type, data: notificationData } = data;

  try {
    // Get user's FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token for user:', userId);
      return {
        success: false,
        message: 'User has not registered for notifications'
      };
    }

    // Send notification via Firebase Cloud Messaging
    const message = {
      notification: {
        title,
        body
      },
      data: {
        type: type || 'general',
        ...notificationData
      },
      token: fcmToken
    };

    const response = await admin.messaging().send(message);

    // Store notification in database
    await storeNotification(userId, {
      title,
      body,
      type,
      data: notificationData,
      sent: true,
      sentAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('Notification sent to user:', userId, 'Message ID:', response);

    return {
      success: true,
      messageId: response
    };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send notification'
    );
  }
});

/**
 * Process notification queue (handles batched notifications)
 */
export const processNotificationQueue = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    try {
      const now = new Date();

      // Find all pending reminders that should trigger now
      const remindersSnapshot = await db.collectionGroup('reminders')
        .where('active', '==', true)
        .where('nextNotificationTime', '<=', now)
        .get();

      let processedCount = 0;

      for (const doc of remindersSnapshot.docs) {
        const reminder = doc.data();
        const userId = reminder.userId;

        try {
          // Send notification
          await sendNotificationForReminder(userId, reminder);

          // Update next notification time based on repeat setting
          const nextTime = calculateNextNotificationTime(reminder);

          if (nextTime) {
            await doc.ref.update({
              nextNotificationTime: nextTime,
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          } else {
            // Mark as inactive if no more notifications
            await doc.ref.update({
              active: false,
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }

          processedCount++;
        } catch (error) {
          console.error('Error processing reminder:', doc.id, error);
        }
      }

      console.log(`Processed ${processedCount} notifications`);
      return null;
    } catch (error) {
      console.error('Error processing notification queue:', error);
      throw error;
    }
  });

/**
 * Helper function to schedule a notification
 */
async function scheduleNotification(
  userId: string,
  reminder: any,
  reminderId: string
): Promise<void> {
  // This would be handled by the processNotificationQueue function
  // In a production environment, you might use a service like Cloud Tasks
  console.log(`Notification queued for user: ${userId}, Reminder: ${reminderId}`);
}

/**
 * Helper function to send notification for a reminder
 */
async function sendNotificationForReminder(userId: string, reminder: any): Promise<void> {
  // Get user's FCM token
  const userDoc = await db.collection('users').doc(userId).get();
  const fcmToken = userDoc.data()?.fcmToken;

  if (!fcmToken) {
    console.log('No FCM token for user:', userId);
    return;
  }

  const message = {
    notification: {
      title: reminder.title,
      body: `Time for your ${reminder.type} reminder`
    },
    data: {
      type: 'reminder',
      reminderType: reminder.type,
      reminderId: reminder.id
    },
    token: fcmToken
  };

  try {
    await admin.messaging().send(message);
    console.log(`Notification sent for reminder to user: ${userId}`);
  } catch (error) {
    console.error('Error sending reminder notification:', error);
  }
}

/**
 * Helper function to calculate next notification time
 */
function calculateNextNotificationTime(reminder: any): Date | null {
  const currentTime = new Date(reminder.nextNotificationTime);

  switch (reminder.repeat) {
    case 'daily':
      currentTime.setDate(currentTime.getDate() + 1);
      return currentTime;

    case 'weekly':
      currentTime.setDate(currentTime.getDate() + 7);
      return currentTime;

    case 'monthly':
      currentTime.setMonth(currentTime.getMonth() + 1);
      return currentTime;

    case 'once':
    default:
      return null; // No more notifications
  }
}

/**
 * Helper function to store notification in database
 */
async function storeNotification(
  userId: string,
  notificationData: any
): Promise<void> {
  try {
    const notificationsRef = db
      .collection('notifications')
      .doc(userId)
      .collection('history');

    await notificationsRef.add({
      ...notificationData,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false
    });
  } catch (error) {
    console.error('Error storing notification:', error);
  }
}

/**
 * Mark notification as read
 */
export const markNotificationAsRead = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { notificationId } = data;

  try {
    const notificationRef = db
      .collection('notifications')
      .doc(userId)
      .collection('history')
      .doc(notificationId);

    await notificationRef.update({
      read: true,
      readAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      message: 'Notification marked as read'
    };
  } catch (error) {
    console.error('Error marking notification as read:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to mark notification as read'
    );
  }
});

/**
 * Export notification functions
 */
export const notificationFunctions = {
  scheduleReminders,
  sendNotification,
  processNotificationQueue,
  markNotificationAsRead
};