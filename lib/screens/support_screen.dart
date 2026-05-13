import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_drawer.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, String>> messages = [];

  List<String> emergencyContacts = [];

  static const Color primary = Color(0xFF1E40AF);
  static const Color danger = Color(0xFFB91C1C);
  static const Color bg = Color(0xFFF8FAFC);

  String get uid => user?.uid ?? "";

  @override
  void initState() {
    super.initState();
    loadContacts();

    messages.add({
      "role": "assistant",
      "text":
          "Hello 👋 I’m your SickleCare assistant. I can help you with pain, hydration, symptoms, and crisis advice."
    });
  }

  Future<void> loadContacts() async {
    if (uid.isEmpty) return;

    final doc = await firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      emergencyContacts =
          List<String>.from(doc.data()?['emergencyContacts'] ?? []);
    }
  }

  // ===================== OFFLINE AI BRAIN =====================
  String generateReply(String input) {
    final text = input.toLowerCase();

    if (text.contains("pain")) {
      return "⚠️ Pain management tip:\n"
          "- Drink water 💧\n"
          "- Rest in a warm environment\n"
          "- Use prescribed medication\n"
          "If pain is severe (>7/10), contact a doctor immediately.";
    }

    if (text.contains("hydrate") || text.contains("water")) {
      return "💧 Hydration advice:\n"
          "- Aim for 2–3L water daily\n"
          "- Drink small amounts frequently\n"
          "- Avoid dehydration triggers like heat";
    }

    if (text.contains("fever")) {
      return "🤒 Fever advice:\n"
          "- Rest and stay hydrated\n"
          "- Monitor temperature\n"
          "- Seek medical help if persistent";
    }

    if (text.contains("crisis") || text.contains("emergency")) {
      return "🚨 Sickle Cell Crisis Guidance:\n"
          "- Stay calm\n"
          "- Hydrate immediately\n"
          "- Warm compress may help\n"
          "- Contact emergency support if pain is severe";
    }

    if (text.contains("hello") || text.contains("hi")) {
      return "Hello 👋 I'm here to support your daily health tracking.";
    }

    return "I understand. Can you describe your symptoms more clearly? "
        "I can help with pain, hydration, fever, or crisis support.";
  }

  // ===================== SEND MESSAGE =====================
  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
    });

    controller.clear();
    scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      final reply = generateReply(text);

      setState(() {
        messages.add({"role": "assistant", "text": reply});
      });

      scrollToBottom();
    });
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===================== SOS =====================
  void sendSOS() {
    if (emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No emergency contact found")),
      );
      return;
    }

    final number = emergencyContacts.first;

    final uri = Uri.parse(
        "sms:$number?body=EMERGENCY: I need help for Sickle Cell crisis");

    launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      drawer: const AppDrawer(),

      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("Support AI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency, color: Colors.white),
            onPressed: sendSOS,
          )
        ],
      ),

      body: Column(
        children: [
          // SOS banner
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: danger.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: danger),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text("Emergency? Tap SOS to alert contact"),
                ),
                ElevatedButton(
                  onPressed: sendSOS,
                  style: ElevatedButton.styleFrom(backgroundColor: danger),
                  child: const Text("SOS"),
                )
              ],
            ),
          ),

          // CHAT LIST
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // INPUT
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Ask about pain, hydration, symptoms...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: primary),
                  onPressed: () => sendMessage(controller.text),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}