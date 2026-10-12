import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Health Data Functions
 * 
 * These functions handle health data validation, processing, and analytics
 */

/**
 * Validates health entry before it's saved to Firestore
 */
export const validateHealthEntry = functions.firestore
  .document('users/{userId}/health/{date}')
  .onCreate(async (snap, context) => {
    const { userId, date } = context.params;
    const data = snap.data();

    try {
      // Validate data structure
      if (!isValidHealthData(data)) {
        throw new Error('Invalid health data structure');
      }

      // Log the entry
      console.log(`Health entry validated for user: ${userId} on ${date}`);

      // Update user's health stats
      await updateUserHealthStats(userId, data);

      // Process analytics if needed
      await processHealthAnalyticsForEntry(userId, date, data);

      return null;
    } catch (error) {
      console.error(`Error validating health entry for ${userId}:`, error);
      throw error;
    }
  });

/**
 * Process health analytics and aggregate data
 */
export const processHealthAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { period = 'week' } = data;

  try {
    const analytics = await calculateHealthAnalytics(userId, period);

    return {
      success: true,
      data: analytics
    };
  } catch (error) {
    console.error('Error processing health analytics:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to process analytics'
    );
  }
});

/**
 * Export health data for user
 */
export const exportHealthData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { format = 'json', startDate, endDate } = data;

  try {
    // Fetch health data
    const healthRef = db.collection('users').doc(userId).collection('health');
    let query = healthRef;

    if (startDate && endDate) {
      query = query
        .where('timestamp', '>=', new Date(startDate))
        .where('timestamp', '<=', new Date(endDate));
    }

    const snapshot = await query.get();
    const healthData = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Format data based on format parameter
    let exportedData: any;

    if (format === 'csv') {
      exportedData = convertToCSV(healthData);
    } else {
      exportedData = healthData;
    }

    console.log(`Health data exported for user: ${userId}`);

    return {
      success: true,
      data: exportedData,
      count: healthData.length
    };
  } catch (error) {
    console.error('Error exporting health data:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to export health data'
    );
  }
});

/**
 * Helper function to validate health data structure
 */
function isValidHealthData(data: any): boolean {
  const requiredFields = ['userId', 'painLevel', 'hydration', 'timestamp'];
  
  for (const field of requiredFields) {
    if (!(field in data)) {
      return false;
    }
  }

  // Validate data types and ranges
  if (typeof data.painLevel !== 'number' || data.painLevel < 0 || data.painLevel > 10) {
    return false;
  }

  if (typeof data.hydration !== 'number' || data.hydration < 0 || data.hydration > 10) {
    return false;
  }

  if (!(data.timestamp instanceof admin.firestore.Timestamp)) {
    return false;
  }

  return true;
}

/**
 * Update user's aggregated health statistics
 */
async function updateUserHealthStats(userId: string, data: any): Promise<void> {
  try {
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return;
    }

    const stats = userDoc.data()?.healthStats || {};
    
    // Update stats
    const updatedStats = {
      totalEntries: (stats.totalEntries || 0) + 1,
      lastEntryDate: new Date(),
      averagePainLevel: calculateNewAverage(
        stats.averagePainLevel || 0,
        stats.totalEntries || 0,
        data.painLevel
      ),
      averageHydration: calculateNewAverage(
        stats.averageHydration || 0,
        stats.totalEntries || 0,
        data.hydration
      ),
      streakDays: calculateStreak(stats)
    };

    await userRef.update({
      healthStats: updatedStats,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Health stats updated for user: ${userId}`);
  } catch (error) {
    console.error('Error updating health stats:', error);
  }
}

/**
 * Process health analytics for a specific entry
 */
async function processHealthAnalyticsForEntry(
  userId: string,
  date: string,
  data: any
): Promise<void> {
  try {
    // Store in analytics collection for trend analysis
    const analyticsRef = db.collection('analytics').doc(userId);
    
    await analyticsRef.set({
      userId,
      latestPainLevel: data.painLevel,
      latestHydration: data.hydration,
      latestTimestamp: data.timestamp,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    console.log(`Analytics processed for user: ${userId}`);
  } catch (error) {
    console.error('Error processing analytics:', error);
  }
}

/**
 * Calculate health analytics for a period
 */
async function calculateHealthAnalytics(
  userId: string,
  period: string
): Promise<any> {
  const healthRef = db.collection('users').doc(userId).collection('health');
  
  // Calculate date range
  const now = new Date();
  let startDate = new Date();

  switch (period) {
    case 'week':
      startDate.setDate(now.getDate() - 7);
      break;
    case 'month':
      startDate.setMonth(now.getMonth() - 1);
      break;
    case 'year':
      startDate.setFullYear(now.getFullYear() - 1);
      break;
    default:
      startDate.setDate(now.getDate() - 7);
  }

  const snapshot = await healthRef
    .where('timestamp', '>=', startDate)
    .where('timestamp', '<=', now)
    .get();

  if (snapshot.empty) {
    return {
      period,
      dataPoints: 0,
      averagePainLevel: 0,
      averageHydration: 0,
      maxPainLevel: 0,
      minPainLevel: 0,
      trend: 'stable'
    };
  }

  const entries = snapshot.docs.map(doc => doc.data());

  // Calculate statistics
  const painLevels = entries.map(e => e.painLevel);
  const hydrationLevels = entries.map(e => e.hydration);

  const averagePainLevel = painLevels.reduce((a, b) => a + b, 0) / painLevels.length;
  const averageHydration = hydrationLevels.reduce((a, b) => a + b, 0) / hydrationLevels.length;

  return {
    period,
    dataPoints: entries.length,
    averagePainLevel: Math.round(averagePainLevel * 10) / 10,
    averageHydration: Math.round(averageHydration * 10) / 10,
    maxPainLevel: Math.max(...painLevels),
    minPainLevel: Math.min(...painLevels),
    medianPainLevel: getMedian(painLevels),
    standardDeviation: calculateStandardDeviation(painLevels),
    trend: calculateTrend(painLevels)
  };
}

/**
 * Helper function to calculate new average
 */
function calculateNewAverage(
  oldAverage: number,
  count: number,
  newValue: number
): number {
  return (oldAverage * count + newValue) / (count + 1);
}

/**
 * Helper function to calculate streak
 */
function calculateStreak(stats: any): number {
  const lastEntryDate = stats.lastEntryDate;
  
  if (!lastEntryDate) {
    return 1;
  }

  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  const lastDate = lastEntryDate instanceof admin.firestore.Timestamp 
    ? lastEntryDate.toDate() 
    : new Date(lastEntryDate);

  // If last entry was today or yesterday, continue streak
  if (lastDate.toDateString() === today.toDateString() || 
      lastDate.toDateString() === yesterday.toDateString()) {
    return (stats.streakDays || 0) + 1;
  }

  // Otherwise, reset streak
  return 1;
}

/**
 * Helper function to get median
 */
function getMedian(arr: number[]): number {
  const sorted = [...arr].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

/**
 * Helper function to calculate standard deviation
 */
function calculateStandardDeviation(arr: number[]): number {
  const mean = arr.reduce((a, b) => a + b, 0) / arr.length;
  const variance = arr.reduce((sq, n) => sq + Math.pow(n - mean, 2), 0) / arr.length;
  return Math.sqrt(variance);
}

/**
 * Helper function to calculate trend
 */
function calculateTrend(values: number[]): string {
  if (values.length < 2) return 'stable';

  const firstHalf = values.slice(0, Math.floor(values.length / 2));
  const secondHalf = values.slice(Math.floor(values.length / 2));

  const firstAvg = firstHalf.reduce((a, b) => a + b, 0) / firstHalf.length;
  const secondAvg = secondHalf.reduce((a, b) => a + b, 0) / secondHalf.length;

  const difference = secondAvg - firstAvg;
  const threshold = 0.5;

  if (difference > threshold) {
    return 'increasing';
  } else if (difference < -threshold) {
    return 'decreasing';
  }

  return 'stable';
}

/**
 * Helper function to convert array to CSV
 */
function convertToCSV(data: any[]): string {
  if (data.length === 0) return '';

  const headers = Object.keys(data[0]);
  const csv = [
    headers.join(','),
    ...data.map(row => 
      headers.map(header => {
        const value = row[header];
        if (typeof value === 'string' && value.includes(',')) {
          return `"${value}"`;
        }
        return value;
      }).join(',')
    )
  ];

  return csv.join('\n');
}

/**
 * Export health functions
 */
export const healthFunctions = {
  validateHealthEntry,
  processHealthAnalytics,
  exportHealthData
};