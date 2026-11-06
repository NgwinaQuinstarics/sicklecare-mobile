import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Report Generation Functions
 * 
 * These functions handle PDF generation and report distribution
 */

/**
 * Generate health report for user
 */
export const generateHealthReport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { startDate, endDate, format = 'json' } = data ?? {};

  if (format !== 'json') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Only JSON reports are currently supported',
    );
  }
  if (typeof startDate !== 'string' || typeof endDate !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Start date and end date are required',
    );
  }

  const start = new Date(startDate);
  const end = new Date(endDate);
  if (
    !Number.isFinite(start.getTime()) ||
    !Number.isFinite(end.getTime()) ||
    start > end ||
    end.getTime() - start.getTime() > 366 * 24 * 60 * 60 * 1000
  ) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The report date range is invalid or exceeds one year',
    );
  }

  try {
    const report = await createHealthReport(
      userId,
      start,
      end,
    );

    const reportRef = db.collection('users').doc(userId)
      .collection('reports').doc();
    await reportRef.set({
      report,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      startDate: admin.firestore.Timestamp.fromDate(start),
      endDate: admin.firestore.Timestamp.fromDate(end),
      format,
    });

    return {
      success: true,
      report,
      reportId: reportRef.id,
    };
  } catch (error) {
    console.error('Error generating health report:', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate health report'
    );
  }
});

/**
 * Send weekly report to user (scheduled)
 */
export const sendWeeklyReport = functions.pubsub
  .schedule('0 9 * * 1') // Every Monday at 9 AM UTC
  .onRun(async () => {
    try {
      const usersSnapshot = await db.collection('users').get();
      let sentCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        try {
          const userId = userDoc.id;
          const user = userDoc.data();

          // Check if user has notifications enabled
          if (!user.settings?.notifications?.enabled) {
            continue;
          }

          // Generate report for past week
          const endDate = new Date();
          const startDate = new Date();
          startDate.setDate(endDate.getDate() - 7);

          const report = await createHealthReport(userId, startDate, endDate);

          await sendReportToUser(userId, report);

          sentCount++;
        } catch (error) {
          console.error(`Error sending report to user ${userDoc.id}:`, error);
        }
      }

      console.log(`Weekly reports sent to ${sentCount} users`);
      return null;
    } catch (error) {
      console.error('Error in weekly report job:', error);
      throw error;
    }
  });

/**
 * Helper function to create health report
 */
async function createHealthReport(
  userId: string,
  startDate: Date,
  endDate: Date
): Promise<any> {
  try {
    // Fetch user info
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    // Fetch health data for period
    const entriesSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('tracker_entries')
      .where('date', '>=', startDate.toISOString())
      .where('date', '<=', endDate.toISOString())
      .orderBy('date', 'asc')
      .limit(1000)
      .get();

    if (entriesSnapshot.size === 1000) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'The report contains too many entries; use a shorter date range',
      );
    }

    const healthEntries = entriesSnapshot.docs.map(doc => doc.data());

    if (healthEntries.length === 0) {
      return {
        title: 'Health Report',
        period: {
          start: startDate.toISOString().split('T')[0],
          end: endDate.toISOString().split('T')[0]
        },
        summary: {
          totalEntries: 0,
          message: 'No health data found for this period'
        }
      };
    }

    // Calculate statistics
    const painLevels = healthEntries.map(e => e.painLevel);
    const hydrationLevels = healthEntries.map(e => e.hydrationMl);

    const averagePain = painLevels.reduce((a, b) => a + b, 0) / painLevels.length;
    const averageHydration = hydrationLevels.reduce((a, b) => a + b, 0) / hydrationLevels.length;

    // Build report object
    const report = {
      title: 'SickleCare Health Report',
      period: {
        start: startDate.toISOString().split('T')[0],
        end: endDate.toISOString().split('T')[0]
      },
      user: {
        name: userData?.name || userData?.displayName || 'Patient',
        email: userData?.email || ''
      },
      summary: {
        totalEntries: healthEntries.length,
        averagePainLevel: Math.round(averagePain * 10) / 10,
        averageHydrationMl: Math.round(averageHydration),
        maxPainLevel: Math.max(...painLevels),
        minPainLevel: Math.min(...painLevels),
        reportGeneratedAt: new Date().toISOString()
      },
      details: {
        dailyEntries: groupDataByDate(healthEntries),
        recommendations: generateRecommendations(averagePain)
      }
    };

    return report;
  } catch (error) {
    console.error('Error creating health report:', error);
    throw error;
  }
}

/**
 * Helper function to send report to user
 */
async function sendReportToUser(
  userId: string,
  report: any
): Promise<void> {
  try {
    // Store report in user's collection
    await db.collection('users').doc(userId).collection('reports').add({
      report,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false
    });

    console.log(`Weekly report stored for user: ${userId}`);
  } catch (error) {
    console.error('Error sending report:', error);
  }
}

/**
 * Helper function to group data by date
 */
function groupDataByDate(entries: any[]): { [key: string]: any[] } {
  const grouped: { [key: string]: any[] } = {};

  entries.forEach(entry => {
    const date = entry.date.substring(0, 10);
    if (!grouped[date]) {
      grouped[date] = [];
    }
    grouped[date].push(entry);
  });

  return grouped;
}

/**
 * Helper function to generate recommendations
 */
function generateRecommendations(avgPain: number): string[] {
  const recommendations: string[] = [];

  if (avgPain > 6) {
    recommendations.push('High pain levels detected. Consider consulting with your healthcare provider.');
  } else if (avgPain > 4) {
    recommendations.push('Moderate pain levels. Continue monitoring and follow your pain management plan.');
  }

  if (recommendations.length === 0) {
    recommendations.push('Your health metrics are within normal ranges. Continue with your current routine.');
  }

  return recommendations;
}

/**
 * Helper function to generate HTML for email (currently unused - kept for future implementation)
 */
/*
function _generateReportHTML(report: any): string {
  return `
    <html>
      <body style="font-family: Arial, sans-serif;">
        <h1>${report.title}</h1>
        <h2>Report for ${report.period.start} to ${report.period.end}</h2>
        
        <h3>Summary</h3>
        <ul>
          <li>Total Entries: ${report.summary.totalEntries}</li>
          <li>Average Pain Level: ${report.summary.averagePainLevel}/10</li>
          <li>Average Hydration: ${report.summary.averageHydration}/10</li>
        </ul>
        
        <h3>Recommendations</h3>
        <ul>
          ${report.details.recommendations.map((rec: string) => `<li>${rec}</li>`).join('')}
        </ul>
        
        <p>For more details, please visit your SickleCare dashboard.</p>
      </body>
    </html>
  `;
}
*/

/**
 * Export report functions
 */
export const reportFunctions = {
  generateHealthReport,
  sendWeeklyReport
};