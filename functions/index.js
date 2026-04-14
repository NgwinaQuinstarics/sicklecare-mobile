const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onHealthUpdate = functions.firestore
  .document("users/{userId}/daily/{docId}")
  .onWrite(async (change, context) => {
    const data = change.after.exists ? change.after.data() : null;

    if (!data) return null;

    const {
      painLevel,
      hydrationLevel,
      fever,
      fatigue,
      headache,
      dizziness,
      nausea,
    } = data;

    const userId = context.params.userId;

    // 🚨 1. DANGER DETECTION
    let alerts = [];

    if (painLevel >= 8) {
      alerts.push("Severe pain detected");
    }

    if (hydrationLevel <= 2) {
      alerts.push("Very low hydration");
    }

    if (fever === true) {
      alerts.push("Fever detected");
    }

    if (fatigue && dizziness) {
      alerts.push("Possible crisis warning");
    }

    // 🚨 2. SAVE ALERTS
    if (alerts.length > 0) {
      await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("alerts")
        .add({
          alerts: alerts,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    return null;
  });