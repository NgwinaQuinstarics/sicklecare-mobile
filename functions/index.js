const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

exports.autoReply = functions.firestore
  .document("support_chats/{userId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    if (data.sender !== "user") return;

    const userId = context.params.userId;
    const message = data.text;

    const apiKey = functions.config().openai.key;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: "You are a helpful health assistant." },
          { role: "user", content: message }
        ],
      }),
    });

    const result = await response.json();

    const reply =
      result.choices?.[0]?.message?.content ||
      "Sorry, I couldn't respond.";

    const chatRef = admin.firestore()
      .collection("support_chats")
      .doc(userId);

    await chatRef.collection("messages").add({
      text: reply,
      sender: "ai",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      lastMessage: reply,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });