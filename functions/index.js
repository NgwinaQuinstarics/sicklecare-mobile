const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

exports.sickleCareAI = functions.https.onCall(async (data, context) => {
  try {
    const uid = context.auth.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated");
    }

    const db = admin.firestore();

    // 🔥 GET USER HEALTH DATA (REAL CONTEXT)
    const today = new Date().toISOString().split("T")[0];

    const doc = await db
      .collection("users")
      .doc(uid)
      .collection("daily")
      .doc(today)
      .get();

    const health = doc.exists ? doc.data() : {};

    const messages = data.messages || [];

    // 🧠 BUILD SMART PROMPT
    const systemPrompt = `
You are a medical AI assistant specialized in Sickle Cell Disease.

User Health Context:
- Pain Level: ${health.painLevel || 0}/10
- Hydration: ${health.hydration || 0}L
- Meals: ${JSON.stringify(health.meals || [])}

Rules:
- Be calm, short, and supportive
- Detect possible crisis risk
- Always advise doctor for severe symptoms
- Act like WhatsApp chat assistant
`;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer YOUR_OPENAI_API_KEY`
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: systemPrompt },
          ...messages
        ]
      })
    });

    const dataRes = await response.json();

    const reply = dataRes.choices[0].message.content;

    return { reply };

  } catch (error) {
    console.error(error);
    return {
      reply: "I'm currently unable to respond. Please try again later."
    };
  }
});
