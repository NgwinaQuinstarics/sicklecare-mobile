import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Analytics Functions
 * 
 * These functions handle data aggregation, trends, and backups
 */

/**
 * Aggregate daily statistics (scheduled to run daily)
 */
export const aggregateDailyStats = functions.pubsub
  .schedule('0 1 * * *') // Daily at 1 AM UTC
  .onRun(async () => {
    try {
      const usersSnapshot = await db.collection('users').get();
      let processedCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        try {
          await aggregateUserDailyStats(userDoc.id);
          processedCount++;
        } catch (error) {
          console.error(`Error aggregating stats for user ${userDoc.id}:`, error);
        }
      }

      console.log(`Daily stats aggregated for ${processedCount} users`);
      return null;
    } catch (error) {
      console.error('Error in daily aggregation:', error);
      throw error;
    }
  });

/**
 * Generate health trends for a user
 */
export const generateTrends = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { days = 30 } = data;

  try {
    const trends = await calculateHealthTrends(userId, days);

    return {
      success: true,
      data: trends
    };
  } catch (error) {
    console.error('Error generating trends:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate trends'
    );
  }
});

/**
 * Backup user data (scheduled daily)
 */
export const backupUserData = functions.pubsub
  .schedule('0 2 * * *') // Daily at 2 AM UTC
  .onRun(async () => {
    try {
      const usersSnapshot = await db.collection('users').get();
      let backupCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        try {
          await createUserBackup(userDoc.id);
          backupCount++;
        } catch (error) {
          console.error(`Error backing up user ${userDoc.id}:`, error);
        }
      }

      console.log(`Backup created for ${backupCount} users`);
      return null;
    } catch (error) {
      console.error('Error in backup process:', error);
      throw error;
    }
  });

/**
 * Helper function to aggregate user daily stats
 */
async function aggregateUserDailyStats(userId: string): Promise<void> {
  const healthRef = db.collection('users').doc(userId).collection('health');
  
  // Get today's data
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const snapshot = await healthRef
    .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(today))
    .where('timestamp', '<', admin.firestore.Timestamp.fromDate(tomorrow))
    .get();

  if (snapshot.empty) {
    return;
  }

  const entries = snapshot.docs.map(doc => doc.data());

  // Calculate daily aggregates
  const painLevels = entries.map(e => e.painLevel);
  const hydrationLevels = entries.map(e => e.hydration);

  const dailyStats = {
    date: today,
    dataPoints: entries.length,
    painLevel: {
      average: painLevels.reduce((a, b) => a + b, 0) / painLevels.length,
      min: Math.min(...painLevels),
      max: Math.max(...painLevels)
    },
    hydration: {
      average: hydrationLevels.reduce((a, b) => a + b, 0) / hydrationLevels.length,
      min: Math.min(...hydrationLevels),
      max: Math.max(...hydrationLevels)
    },
    meals: entries.filter(e => e.meals && e.meals.length > 0).length,
    medications: entries.filter(e => e.medications && e.medications.length > 0).length
  };

  // Store in analytics collection
  const analyticsRef = db.collection('analytics').doc(userId);
  await analyticsRef.set({
    [`daily_${today.toISOString().split('T')[0]}`]: dailyStats
  }, { merge: true });

  console.log(`Daily stats aggregated for user: ${userId} on ${today.toDateString()}`);
}

/**
 * Helper function to calculate health trends
 */
async function calculateHealthTrends(userId: string, days: number): Promise<any> {
  const healthRef = db.collection('users').doc(userId).collection('health');
  
  // Calculate date range
  const endDate = new Date();
  const startDate = new Date();
  startDate.setDate(endDate.getDate() - days);

  const snapshot = await healthRef
    .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startDate))
    .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(endDate))
    .orderBy('timestamp', 'desc')
    .get();

  if (snapshot.empty) {
    return {
      period: days,
      dataPoints: 0,
      trends: []
    };
  }

  // Group data by date
  const groupedByDate: { [key: string]: any[] } = {};

  snapshot.docs.forEach(doc => {
    const data = doc.data();
    const date = data.timestamp.toDate().toISOString().split('T')[0];

    if (!groupedByDate[date]) {
      groupedByDate[date] = [];
    }
    groupedByDate[date].push(data);
  });

  // Calculate daily trends
  const trends = Object.entries(groupedByDate).map(([date, entries]) => {
    const painLevels = entries.map(e => e.painLevel);
    const hydrationLevels = entries.map(e => e.hydration);

    return {
      date,
      painLevel: Math.round(painLevels.reduce((a, b) => a + b, 0) / painLevels.length * 10) / 10,
      hydration: Math.round(hydrationLevels.reduce((a, b) => a + b, 0) / hydrationLevels.length * 10) / 10,
      entries: entries.length
    };
  });

  // Calculate overall trend direction
  const firstThird = trends.slice(0, Math.floor(trends.length / 3));
  const lastThird = trends.slice(-Math.floor(trends.length / 3));

  const firstAvgPain = firstThird.reduce((a, b) => a + b.painLevel, 0) / firstThird.length;
  const lastAvgPain = lastThird.reduce((a, b) => a + b.painLevel, 0) / lastThird.length;

  const painTrend = lastAvgPain < firstAvgPain ? 'improving' : 
                    lastAvgPain > firstAvgPain ? 'worsening' : 'stable';

  return {
    period: days,
    dataPoints: snapshot.size,
    painTrend,
    trends: trends.reverse() // Show chronologically
  };
}

/**
 * Helper function to create user backup
 */
async function createUserBackup(userId: string): Promise<void> {
  try {
    // Get all user data
    const userDoc = await db.collection('users').doc(userId).get();
    const healthSnapshot = await db.collection('users').doc(userId).collection('health').get();
    const remindersSnapshot = await db.collection('users').doc(userId).collection('reminders').get();

    // Create backup document
    const backupData = {
      userId,
      backupDate: admin.firestore.FieldValue.serverTimestamp(),
      dataSize: JSON.stringify({
        user: userDoc.data(),
        health: healthSnapshot.docs.map(d => d.data()),
        reminders: remindersSnapshot.docs.map(d => d.data())
      }).length,
      recordCount: {
        health: healthSnapshot.size,
        reminders: remindersSnapshot.size
      }
    };

    // Store backup metadata
    await db.collection('backups').add(backupData);

    console.log(`Backup created for user: ${userId}`);
  } catch (error) {
    console.error('Error creating backup:', error);
  }
}

/**
 * Get user statistics summary
 */
export const getUserStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const healthSnapshot = await db.collection('users').doc(userId).collection('health').get();
    const remindersSnapshot = await db.collection('users').doc(userId).collection('reminders').get();

    const stats = {
      totalHealthEntries: healthSnapshot.size,
      totalReminders: remindersSnapshot.size,
      activeReminders: remindersSnapshot.docs.filter(d => d.data().active).length,
      healthStats: userDoc.data()?.healthStats || {},
      lastUpdate: userDoc.data()?.updatedAt
    };

    return {
      success: true,
      data: stats
    };
  } catch (error) {
    console.error('Error getting user stats:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get user statistics'
    );
  }
});

/**
 * Export analytics functions
 */
export const analyticsFunctions = {
  aggregateDailyStats,
  generateTrends,
  backupUserData,
  getUserStats
};