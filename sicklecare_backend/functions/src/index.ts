import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Import function modules
import { userFunctions } from './users';
import { healthFunctions } from './health';
import { notificationFunctions } from './notifications';
import { analyticsFunctions } from './analytics';
import { reportFunctions } from './reports';
import { utilityFunctions } from './utils';

// Export all functions
export const {
  onUserCreate,
  onUserDelete,
  updateUserProfile,
} = userFunctions;

export const {
  validateHealthEntry,
  processHealthAnalytics,
  exportHealthData,
} = healthFunctions;

export const {
  scheduleReminders,
  sendNotification,
  processNotificationQueue,
} = notificationFunctions;

export const {
  aggregateDailyStats,
  generateTrends,
  backupUserData,
} = analyticsFunctions;

export const {
  generateHealthReport,
  sendWeeklyReport,
} = reportFunctions;

export const {
  cleanupTempFiles,
  sendEmail,
  validateApiKey,
} = utilityFunctions;

// HTTP endpoints for webhooks and external integrations
export const api = functions.https.onRequest(async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle preflight requests
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
        // Generate report logic
        res.status(200).json({ message: 'Report generation started' });
        break;
        
      case 'send-test-notification':
        // Send test notification
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

// Scheduled functions (run on cron schedule)
export const scheduledDailyAggregation = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('UTC')
  .onRun(async () => {
    console.log('Running daily aggregation...');
    // Implement daily aggregation logic
    return null;
  });

export const scheduledWeeklyReports = functions.pubsub
  .schedule('0 9 * * 1') // Every Monday at 9:00 AM
  .timeZone('UTC')
  .onRun(async () => {
    console.log('Running weekly reports...');
    // Implement weekly report generation
    return null;
  });

export const scheduledDataBackup = functions.pubsub
  .schedule('0 2 * * *') // Daily at 2:00 AM
  .timeZone('UTC')
  .onRun(async () => {
    console.log('Running data backup...');
    // Implement data backup logic
    return null;
  });

// Error handling middleware
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  // Send to error tracking service
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  // Send to error tracking service
  process.exit(1);
});