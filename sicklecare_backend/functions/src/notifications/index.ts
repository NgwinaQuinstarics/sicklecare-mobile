import * as functions from 'firebase-functions';
import { FieldValue } from 'firebase-admin/firestore';
import * as admin from 'firebase-admin';
import { checkRateLimit } from '../utils';

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
  const { title, type, time, repeat = 'once' } = data ?? {};

  const reminderTime = typeof time === 'string' ? new Date(time) : new Date(NaN);
  if (
    typeof title !== 'string' ||
    title.trim().length === 0 ||
    title.length > 100 ||
    !['medication', 'hydration', 'appointment', 'checkup'].includes(type) ||
    !['once', 'daily', 'weekly', 'monthly'].includes(repeat) ||
    !Number.isFinite(reminderTime.getTime()) ||
    reminderTime.getTime() <= Date.now() ||
    reminderTime.getTime() > Date.now() + 366 * 24 * 60 * 60 * 1000
  ) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Reminder details are invalid',
    );
  }

  if (!(await checkRateLimit(userId, 'scheduleReminders', 30, 60000))) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Reminder limit reached; try again shortly',
    );
  }

  try {
    const remindersRef = db.collection('users').doc(userId).collection('reminders');
    
    const reminderData = {
      userId,
      title: title.trim(),
      type,
      time: reminderTime,
      repeat,
      active: true,
      completed: false,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
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
  const { title, body, type = 'general', data: notificationData = {} } =
    data ?? {};

  if (
    typeof title !== 'string' ||
    title.trim().length === 0 ||
    title.length > 100 ||
    typeof body !== 'string' ||
    body.trim().length === 0 ||
    body.length > 1000 ||
    typeof type !== 'string' ||
    type.trim().length === 0 ||
    type.length > 40 ||
    notificationData === null ||
    typeof notificationData !== 'object' ||
    Array.isArray(notificationData) ||
    Object.keys(notificationData).length > 20 ||
    Object.entries(notificationData).some(([key, value]) =>
      key.length > 40 || typeof value !== 'string' || value.length > 500
    )
  ) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Notification details are invalid',
    );
  }

  if (!(await checkRateLimit(userId, 'sendNotification', 30, 60000))) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Notification limit reached; try again shortly',
    );
  }

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
        title: title.trim(),
        body: body.trim()
      },
      data: {
        ...notificationData,
        type
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
      sentAt: FieldValue.serverTimestamp()
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
        const userRef = doc.ref.parent.parent;
        if (!userRef || userRef.parent.path !== 'users') {
          console.error('Skipping reminder with invalid document path:', doc.ref.path);
          continue;
        }
        const userId = userRef.id;

        try {
          // Send notification
          await sendNotificationForReminder(userId, doc.id, reminder);

          // Update next notification time based on repeat setting
          const nextTime = calculateNextNotificationTime(reminder);

          if (nextTime) {
            await doc.ref.update({
              nextNotificationTime: nextTime,
              updatedAt: FieldValue.serverTimestamp()
            });
          } else {
            // Mark as inactive if no more notifications
            await doc.ref.update({
              active: false,
              updatedAt: FieldValue.serverTimestamp()
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
async function sendNotificationForReminder(
  userId: string,
  reminderId: string,
  reminder: any
): Promise<void> {
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
      reminderId
    },
    token: fcmToken
  };

  try {
    await admin.messaging().send(message);
    console.log(`Notification sent for reminder to user: ${userId}`);
  } catch (error) {
    console.error('Error sending reminder notification:', error);
    throw error;
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
      createdAt: FieldValue.serverTimestamp(),
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
      readAt: FieldValue.serverTimestamp()
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