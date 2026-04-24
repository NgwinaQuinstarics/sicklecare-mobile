import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/app_drawer.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  final chatController = TextEditingController();
  final scrollController = ScrollController();

  List<String> emergencyContacts = [];
  List<Map<String, String>> messages = [];
  bool isTyping = false;
  bool loading = true;

  static const Color danger = Color(0xFFB91C1C);
  static const Color primaryBlue = Color.fromARGB(255, 203, 94, 86);
  static const Color bgGrey = Color(0xFFF8FAFC);

  String get uid => user?.uid ?? "";

  @override
  void initState() {
    super.initState();
    loadContacts();
    // Initial Greeting
    messages.add({
      "role": "assistant",
      "text": "Hello! I am your SickleCare AI. How are you feeling today?"
    });
  }

  Future<void> loadContacts() async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        emergencyContacts = List<String>.from(doc.data()?['emergencyContacts'] ?? []);
      });
    }
    if (mounted) setState(() => loading = false);
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ================= SOS LOGIC =================
  void sendSOS() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: danger),
            SizedBox(width: 10),
            Text("Confirm SOS"),
          ],
        ),
        content: const Text("This will open your SMS app to alert your primary emergency contact. Proceed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              if (emergencyContacts.isNotEmpty) {
                _launchSMS(emergencyContacts.first);
              } else {
                _showSnack("No emergency contacts found in profile.");
              }
            },
            child: const Text("SEND ALERT"),
          )
        ],
      ),
    );
  }

  Future<void> _launchSMS(String number) async {
    final uri = Uri.parse("sms:$number?body=EMERGENCY: I am experiencing a Sickle Cell crisis and need help immediately. My location is being shared.");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ================= AI CHAT LOGIC =================
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isTyping = true;
    });
    chatController.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer YOUR_OPENAI_API_KEY" // SECURE THIS IN PRODUCTION
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content": "You are a professional medical assistant for Sickle Cell patients. "
                  "Provide support on hydration, crisis prevention, and warmth. "
                  "Always advise contacting a doctor for severe pain. Keep responses concise."
            },
            ...messages.map((m) => {"role": m["role"], "content": m["text"]})
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["choices"][0]["message"]["content"];
        setState(() => messages.add({"role": "assistant", "text": reply}));
      } else {
        throw Exception("Failed to reach AI");
      }
    } catch (e) {
      setState(() => messages.add({"role": "assistant", "text": "I'm having trouble connecting. Please ensure you are online."}));
    }

    setState(() => isTyping = false);
    _scrollToBottom();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Care Assistant", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_share, color: Colors.white),
            onPressed: sendSOS,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : Column(
              children: [
                _buildEmergencyBanner(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final isUser = msg["role"] == "user";
                      return _buildChatBubble(msg["text"] ?? "", isUser);
                    },
                  ),
                ),
                if (isTyping)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Align(alignment: Alignment.centerLeft, child: Text("Assistant is thinking...", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))),
                  ),
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: danger.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.medical_services, color: danger, size: 28),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Vaso-occlusive Crisis?", style: TextStyle(color: danger, fontWeight: FontWeight.w900, fontSize: 13)),
                Text("Alert your support network immediately.", style: TextStyle(color: danger, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: sendSOS,
            style: ElevatedButton.styleFrom(backgroundColor: danger, shape: const StadiumBorder(), elevation: 0),
            child: const Text("SOS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14, height: 1.4)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 25),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: chatController,
              decoration: InputDecoration(
                hintText: "Describe your symptoms...",
                hintStyle: const TextStyle(fontSize: 14),
                filled: true,
                fillColor: bgGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: primaryBlue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: () => sendMessage(chatController.text),
            ),
          )
        ],
      ),
    );
  }
}