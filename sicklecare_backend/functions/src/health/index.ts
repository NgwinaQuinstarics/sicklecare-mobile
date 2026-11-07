import * as functions from 'firebase-functions';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import * as admin from 'firebase-admin';
import { isValidTrackerEntry } from './tracker_validation';

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
  .document('users/{userId}/tracker_entries/{entryId}')
  .onCreate(async (snap, context) => {
    const { userId, entryId } = context.params;
    const data = snap.data();

    try {
      if (!isValidTrackerEntry(data, entryId)) {
        throw new Error('Invalid tracker entry');
      }

      await updateUserHealthStats(userId, entryId, data);
      await processHealthAnalyticsForEntry(userId, entryId, data);
      return null;
    } catch (error) {
      console.error(`Error processing tracker entry for ${userId}:`, error);
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
  const period = data?.period ?? 'week';
  if (!['week', 'month', 'year'].includes(period)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Period must be week, month, or year',
    );
  }

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
  const format = data?.format ?? 'json';
  const { startDate, endDate } = data ?? {};
  if (format !== 'json' && format !== 'csv') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Format must be json or csv',
    );
  }
  if ((startDate === undefined) !== (endDate === undefined)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Both startDate and endDate must be provided together',
    );
  }

  const start = startDate === undefined ? undefined : new Date(startDate);
  const end = endDate === undefined ? undefined : new Date(endDate);
  if (
    start !== undefined &&
    end !== undefined &&
    (!Number.isFinite(start.getTime()) ||
      !Number.isFinite(end.getTime()) ||
      start > end)
  ) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Date range is invalid',
    );
  }

  try {
    const entriesRef = db.collection('users').doc(userId)
      .collection('tracker_entries');
    let query: FirebaseFirestore.Query = entriesRef;

    if (start !== undefined && end !== undefined) {
      query = query
        .where('date', '>=', start.toISOString())
        .where('date', '<=', end.toISOString());
    }

    const snapshot = await query.orderBy('date', 'desc').limit(1000).get();
    const healthData = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data()
    }));

    return {
      success: true,
      data: format === 'csv' ? convertToCSV(healthData) : healthData,
      count: healthData.length,
      truncated: snapshot.size === 1000
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
 * Helper function to validate the Flutter tracker entry schema.
 */
/**
 * Update user statistics once even if the Firestore trigger is retried.
 */
async function updateUserHealthStats(
  userId: string,
  entryId: string,
  data: FirebaseFirestore.DocumentData,
): Promise<void> {
  try {
    const userRef = db.collection('users').doc(userId);
    const processedRef = userRef.collection('processed_tracker_entries')
      .doc(entryId);
    const entryDate = new Date(data.date);

    await db.runTransaction(async (transaction) => {
      const processed = await transaction.get(processedRef);
      if (processed.exists) return;

      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      const stats = userDoc.data()?.healthStats ?? {};
      const totalEntries = Number.isInteger(stats.totalEntries)
        ? stats.totalEntries
        : 0;
      const trackerEntryCount = Number.isInteger(stats.trackerEntryCount)
        ? stats.trackerEntryCount
        : 0;
      const previousDate = stats.lastEntryDate instanceof Timestamp
        ? stats.lastEntryDate.toDate()
        : null;
      const isLatest = previousDate === null || entryDate > previousDate;
      const streakDays = isLatest
        ? calculateStreak(previousDate, entryDate, stats.streakDays || 0)
        : (stats.streakDays || 0);

      transaction.update(userRef, {
        healthStats: {
          ...stats,
          totalEntries: totalEntries + 1,
          trackerEntryCount: trackerEntryCount + 1,
          lastEntryDate: isLatest
            ? Timestamp.fromDate(entryDate)
            : stats.lastEntryDate,
          trackerAveragePainLevel: calculateNewAverage(
            stats.trackerAveragePainLevel || 0,
            trackerEntryCount,
            data.painLevel,
          ),
          averageHydrationMl: calculateNewAverage(
            stats.averageHydrationMl || 0,
            trackerEntryCount,
            data.hydrationMl,
          ),
          streakDays,
        },
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.create(processedRef, {
        processedAt: FieldValue.serverTimestamp(),
      });
    });
  } catch (error) {
    console.error('Error updating health stats:', error);
    throw error;
  }
}

/**
 * Process health analytics for a specific entry
 */
async function processHealthAnalyticsForEntry(
  userId: string,
  entryId: string,
  data: FirebaseFirestore.DocumentData
): Promise<void> {
  try {
    const analyticsRef = db.collection('analytics').doc(userId);
    const entryDate = new Date(data.date);
    await db.runTransaction(async (transaction) => {
      const analytics = await transaction.get(analyticsRef);
      const previousDate = analytics.data()?.latestEntryDate;
      const previousMillis = typeof previousDate === 'string'
        ? Date.parse(previousDate)
        : NaN;
      if (Number.isFinite(previousMillis) && previousMillis > entryDate.getTime()) {
        return;
      }

      transaction.set(analyticsRef, {
        userId,
        latestEntryId: entryId,
        latestEntryDate: data.date,
        latestPainLevel: data.painLevel,
        latestHydrationMl: data.hydrationMl,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    });
  } catch (error) {
    console.error('Error processing analytics:', error);
    throw error;
  }
}

/**
 * Calculate health analytics for a period
 */
async function calculateHealthAnalytics(
  userId: string,
  period: string
): Promise<any> {
  const entriesRef = db.collection('users').doc(userId)
    .collection('tracker_entries');
  const now = new Date();
  let startDate = new Date();

  switch (period) {
    case 'week':
      startDate.setUTCDate(now.getUTCDate() - 7);
      break;
    case 'month':
      startDate.setUTCMonth(now.getUTCMonth() - 1);
      break;
    case 'year':
      startDate.setUTCFullYear(now.getUTCFullYear() - 1);
      break;
  }

  const snapshot = await entriesRef
    .where('date', '>=', startDate.toISOString())
    .where('date', '<=', now.toISOString())
    .orderBy('date', 'asc')
    .get();

  if (snapshot.empty) {
    return {
      period,
      dataPoints: 0,
      averagePainLevel: 0,
      averageHydrationMl: 0,
      maxPainLevel: 0,
      minPainLevel: 0,
      trend: 'stable'
    };
  }

  const entries = snapshot.docs.map(doc => doc.data());

  // Calculate statistics
  const painLevels = entries.map(e => e.painLevel);
  const hydrationLevels = entries.map(e => e.hydrationMl);

  const averagePainLevel = painLevels.reduce((a, b) => a + b, 0) / painLevels.length;
  const averageHydration = hydrationLevels.reduce((a, b) => a + b, 0) / hydrationLevels.length;

  return {
    period,
    dataPoints: entries.length,
    averagePainLevel: Math.round(averagePainLevel * 10) / 10,
    averageHydrationMl: Math.round(averageHydration),
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
function calculateStreak(
  previousDate: Date | null,
  entryDate: Date,
  currentStreak: number,
): number {
  if (previousDate === null) {
    return 1;
  }

  const previousDay = Date.UTC(
    previousDate.getUTCFullYear(),
    previousDate.getUTCMonth(),
    previousDate.getUTCDate(),
  );
  const entryDay = Date.UTC(
    entryDate.getUTCFullYear(),
    entryDate.getUTCMonth(),
    entryDate.getUTCDate(),
  );

  if (entryDay === previousDay) {
    return currentStreak;
  }

  const dayMs = 24 * 60 * 60 * 1000;
  return entryDay - previousDay === dayMs ? currentStreak + 1 : 1;
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