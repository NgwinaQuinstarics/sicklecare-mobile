const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const nodemailer = require("nodemailer");

admin.initializeApp();

const appName = process.env.APP_NAME || "SickleCare";
const supportEmail = process.env.SUPPORT_EMAIL || "support@sicklecare.app";
const resetEmailFrom =
  process.env.RESET_EMAIL_FROM || `"${appName}" <${supportEmail}>`;

/**
 * Throws if custom reset-email SMTP settings are missing.
 */
function requireSmtpConfig() {
  const missing = [
    "SMTP_HOST",
    "SMTP_USER",
    "SMTP_PASS",
  ].filter((name) => !process.env[name]);

  if (missing.length) {
    throw new functions.https.HttpsError(
        "failed-precondition",
        `SMTP is not configured: ${missing.join(", ")}`,
    );
  }
}

/**
 * Builds the SMTP transport for custom password reset emails.
 * @return {object} Nodemailer transport.
 */
function smtpTransport() {
  requireSmtpConfig();
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === "true",
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });
}

/**
 * Builds the password reset email HTML body.
 * @param {string} link Firebase password reset action link.
 * @return {string} HTML email body.
 */
function resetEmailHtml(link) {
  const buttonStyle = [
    "display:inline-block",
    "background:#5b3cc4",
    "color:white",
    "padding:12px 18px",
    "border-radius:8px",
    "text-decoration:none",
    "font-weight:bold",
  ].join(";");

  return `
    <div style="font-family:Arial,sans-serif;line-height:1.5;color:#17202a">
      <h2 style="margin:0 0 16px">${appName} password reset</h2>
      <p>You requested a password reset for your ${appName} account.</p>
      <p>
        <a href="${link}" style="${buttonStyle}">
          Reset password
        </a>
      </p>
      <p>If the button does not work, copy this link into your browser:</p>
      <p style="word-break:break-all">${link}</p>
      <p>If you did not request this, you can ignore this email.</p>
    </div>
  `;
}

exports.requestPasswordReset = functions.https.onCall(async (data) => {
  const email = String(data.email || "").trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid email");
  }

  let link;
  try {
    link = await admin.auth().generatePasswordResetLink(email, {
      url: process.env.RESET_CONTINUE_URL ||
        "https://sicklecare-15d7a.firebaseapp.com",
      handleCodeInApp: false,
    });
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      return {ok: true};
    }
    console.error("generatePasswordResetLink failed", error);
    throw new functions.https.HttpsError(
        "internal",
        "Could not create reset link",
    );
  }

  const transporter = smtpTransport();
  await transporter.sendMail({
    from: resetEmailFrom,
    to: email,
    replyTo: supportEmail,
    subject: `${appName} password reset`,
    text:
      `You requested a password reset for your ${appName} account.\n\n` +
      `Reset password: ${link}\n\n` +
      "If you did not request this, you can ignore this email.",
    html: resetEmailHtml(link),
  });

  return {ok: true};
});

exports.sickleCareAI = functions.https.onCall(async (data, context) => {
  try {
    const uid = context.auth && context.auth.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated");
    }
    const aiKey = process.env.OPENAI_API_KEY || process.env.GROQ_API_KEY;
    if (!aiKey) {
      throw new functions.https.HttpsError(
          "failed-precondition",
          "AI provider key is not configured",
      );
    }
    const aiEndpoint = process.env.AI_CHAT_ENDPOINT ||
      "https://api.openai.com/v1/chat/completions";
    const aiModel = process.env.AI_CHAT_MODEL || "gpt-4o-mini";

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
- Never diagnose, prescribe, choose doses, or change treatment
- Act like WhatsApp chat assistant
`;

    const response = await fetch(aiEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${aiKey}`,
      },
      body: JSON.stringify({
        model: aiModel,
        messages: [
          {role: "system", content: systemPrompt},
          ...messages,
        ],
      }),
    });

    const dataRes = await response.json();
    if (!response.ok) {
      console.error("AI provider error", response.status, dataRes);
      throw new functions.https.HttpsError("internal", "AI request failed");
    }

    const reply = dataRes.choices &&
      dataRes.choices[0] &&
      dataRes.choices[0].message &&
      dataRes.choices[0].message.content;

    return {reply: reply || "Sika could not generate a reply."};
  } catch (error) {
    console.error(error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    return {
      reply: "I'm currently unable to respond. Please try again later.",
    };
  }
});
