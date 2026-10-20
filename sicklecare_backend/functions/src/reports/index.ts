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
  const { startDate, endDate, format = 'pdf' } = data;

  try {
    // Validate dates
    if (!startDate || !endDate) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Start date and end date are required'
      );
    }

    const report = await createHealthReport(
      userId,
      new Date(startDate),
      new Date(endDate)
    );

    // Store report metadata
    await db.collection('reports').add({
      userId,
      title: report.title,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      format,
      size: JSON.stringify(report).length
    });

    console.log(`Health report generated for user: ${userId}`);

    return {
      success: true,
      report,
      downloadUrl: `/api/reports/${userId}/${Date.now()}.${format}`
    };
  } catch (error) {
    console.error('Error generating health report:', error);
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

          // Send via email or notification
          await sendReportToUser(userId, report, user.email);

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
    const healthSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('health')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startDate))
      .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(endDate))
      .get();

    const healthEntries = healthSnapshot.docs.map(doc => doc.data());

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
    const hydrationLevels = healthEntries.map(e => e.hydration);

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
        name: userData?.displayName || 'Patient',
        email: userData?.email || ''
      },
      summary: {
        totalEntries: healthEntries.length,
        averagePainLevel: Math.round(averagePain * 10) / 10,
        averageHydration: Math.round(averageHydration * 10) / 10,
        maxPainLevel: Math.max(...painLevels),
        minPainLevel: Math.min(...painLevels),
        reportGeneratedAt: new Date().toISOString()
      },
      details: {
        dailyEntries: groupDataByDate(healthEntries),
        recommendations: generateRecommendations(averagePain, averageHydration)
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
  report: any,
  email: string | undefined
): Promise<void> {
  try {
    // Store report in user's collection
    await db.collection('users').doc(userId).collection('reports').add({
      report,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false
    });

    console.log(`Report stored for user: ${userId}`);

    // In production, send via email service
    if (email) {
      console.log(`Weekly report would be sent to: ${email}`);
      // Example with SendGrid:
      // await sendGridClient.send({
      //   to: email,
      //   from: 'reports@sicklecare.com',
      //   subject: 'Your Weekly Health Report',
      //   html: generateReportHTML(report)
      // });
    }
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
    const date = entry.timestamp.toDate().toISOString().split('T')[0];
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
function generateRecommendations(avgPain: number, avgHydration: number): string[] {
  const recommendations: string[] = [];

  if (avgPain > 6) {
    recommendations.push('High pain levels detected. Consider consulting with your healthcare provider.');
  } else if (avgPain > 4) {
    recommendations.push('Moderate pain levels. Continue monitoring and follow your pain management plan.');
  }

  if (avgHydration < 5) {
    recommendations.push('Low hydration levels. Increase fluid intake to improve health outcomes.');
  } else if (avgHydration > 8) {
    recommendations.push('Excellent hydration! Keep up the good work.');
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