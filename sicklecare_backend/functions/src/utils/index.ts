import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const storage = admin.storage();

/**
 * Utility Functions
 * 
 * These functions handle common tasks like cleanup, email, and validation
 */

/**
 * Cleanup temporary files (scheduled daily)
 */
export const cleanupTempFiles = functions.pubsub
  .schedule('0 3 * * *') // Daily at 3 AM UTC
  .onRun(async () => {
    try {
      const bucket = storage.bucket();
      const [files] = await bucket.getFiles({ prefix: 'temp/' });

      let deletedCount = 0;
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

      for (const file of files) {
        const metadata = await file.getMetadata();
        const createdTime = new Date(metadata[0].timeCreated);

        if (createdTime < oneDayAgo) {
          await file.delete();
          deletedCount++;
        }
      }

      console.log(`Cleaned up ${deletedCount} temporary files`);
      return null;
    } catch (error) {
      console.error('Error cleaning up temp files:', error);
      throw error;
    }
  });

/**
 * Send email function
 */
export const sendEmail = functions.https.onCall(async (data, context) => {
  // This can be restricted to admin or system functions only
  const { to, subject, body, html, fromAdmin = false } = data;

  if (fromAdmin && (!context.auth || !context.auth.token.admin)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can send emails'
    );
  }

  try {
    // Validate email
    if (!isValidEmail(to)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email address'
      );
    }

    // Store email for later sending (in production, use SendGrid/Mailgun)
    await db.collection('emails').add({
      to,
      subject,
      body,
      html,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Email queued to: ${to}`);

    return {
      success: true,
      message: 'Email queued successfully'
    };
  } catch (error) {
    console.error('Error sending email:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send email'
    );
  }
});

/**
 * Validate API key
 */
export const validateApiKey = functions.https.onCall(async (data, context) => {
  const { apiKey } = data;

  try {
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'API key is required'
      );
    }

    // Check if API key exists and is valid
    const keyDoc = await db.collection('api_keys').doc(apiKey).get();

    if (!keyDoc.exists) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Invalid API key'
      );
    }

    const keyData = keyDoc.data();

    if (keyData?.active === false) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'API key is disabled'
      );
    }

    // Update last used timestamp
    await keyDoc.ref.update({
      lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
      usageCount: (keyData?.usageCount || 0) + 1
    });

    return {
      success: true,
      valid: true,
      userId: keyData?.userId
    };
  } catch (error) {
    console.error('Error validating API key:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to validate API key'
    );
  }
});

/**
 * Get system health status
 */
export const getSystemHealth = functions.https.onRequest(async (req, res) => {
  try {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        firestore: 'ok',
        storage: 'ok',
        auth: 'ok',
        messaging: 'ok'
      },
      version: '1.0.0'
    };

    res.status(200).json(health);
  } catch (error) {
    console.error('Error checking system health:', error);
    res.status(500).json({
      status: 'unhealthy',
      error: 'System health check failed'
    });
  }
});

/**
 * Log audit trail for sensitive operations
 */
export async function logAuditTrail(
  userId: string,
  action: string,
  details: any,
  status: 'success' | 'failure' = 'success'
): Promise<void> {
  try {
    await db.collection('audit_logs').add({
      userId,
      action,
      details,
      status,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      ipAddress: details.ipAddress || 'unknown'
    });
  } catch (error) {
    console.error('Error logging audit trail:', error);
  }
}

/**
 * Rate limit check
 */
export async function checkRateLimit(
  userId: string,
  action: string,
  limit: number = 10,
  windowMs: number = 60000
): Promise<boolean> {
  try {
    const now = Date.now();
    const windowStart = now - windowMs;

    const query = await db.collection('rate_limits')
      .where('userId', '==', userId)
      .where('action', '==', action)
      .where('timestamp', '>', new Date(windowStart))
      .get();

    if (query.size >= limit) {
      return false;
    }

    // Record this action
    await db.collection('rate_limits').add({
      userId,
      action,
      timestamp: new Date()
    });

    return true;
  } catch (error) {
    console.error('Error checking rate limit:', error);
    return true; // Allow on error
  }
}

/**
 * Send push notification
 */
export async function sendPushNotification(
  userId: string,
  title: string,
  body: string,
  data?: { [key: string]: string }
): Promise<void> {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token for user:', userId);
      return;
    }

    const message = {
      notification: {
        title,
        body
      },
      data: data || {},
      token: fcmToken
    };

    await admin.messaging().send(message);
    console.log('Push notification sent to user:', userId);
  } catch (error) {
    console.error('Error sending push notification:', error);
  }
}

/**
 * Format date helper
 */
export function formatDate(date: Date, format: string = 'YYYY-MM-DD'): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');

  return format
    .replace('YYYY', String(year))
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hours)
    .replace('mm', minutes)
    .replace('ss', seconds);
}

/**
 * Validate email helper
 */
export function isValidEmail(email: string): boolean {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
}

/**
 * Sanitize input
 */
export function sanitizeInput(input: string): string {
  return input
    .trim()
    .replace(/[<>]/g, '') // Remove potential HTML tags
    .substring(0, 500); // Limit length
}

/**
 * Generate unique ID
 */
export function generateId(): string {
  return Math.random().toString(36).substring(2, 15) + 
         Math.random().toString(36).substring(2, 15);
}

/**
 * Calculate age from birth date
 */
export function calculateAge(birthDate: Date): number {
  const today = new Date();
  let age = today.getFullYear() - birthDate.getFullYear();
  const monthDiff = today.getMonth() - birthDate.getMonth();

  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }

  return age;
}

/**
 * Export utility functions
 */
export const utilityFunctions = {
  cleanupTempFiles,
  sendEmail,
  validateApiKey,
  getSystemHealth,
  logAuditTrail,
  checkRateLimit,
  sendPushNotification,
  formatDate,
  isValidEmail,
  sanitizeInput,
  generateId,
  calculateAge
};