import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  final messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, dynamic>> faqs = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadFAQs();
  }

  // ✅ LOAD FAQS (FIXED)
  Future<void> loadFAQs() async {
    try {
      final snapshot = await firestore
          .collection('admin')
          .doc('faqs')
          .collection('items')
          .get(); // ✅ FIX

      if (!mounted) return;

      setState(() {
        faqs = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      debugPrint("FAQ Load Error: $e");
    }
  }

  // ✅ ANALYTICS
  Future<void> updateAnalytics({required bool isUser}) async {
    final uid = user?.uid;
    if (uid == null) return;

    final ref = firestore.collection('support_analytics').doc(uid);

    await firestore.runTransaction((transaction) async {
      final doc = await transaction.get(ref);

      int total = doc.data()?['totalMessages'] ?? 0;
      int userMsg = doc.data()?['userMessages'] ?? 0;
      int aiMsg = doc.data()?['aiMessages'] ?? 0;

      total++;

      if (isUser) {
        userMsg++;
      } else {
        aiMsg++;
      }

      transaction.set(ref, {
        'totalMessages': total,
        'userMessages': userMsg,
        'aiMessages': aiMsg,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  // ✅ SEND MESSAGE
  Future<void> sendMessage() async {
    final uid = user?.uid;
    if (uid == null || messageController.text.trim().isEmpty) return;

    final text = messageController.text.trim();

    try {
      // USER MESSAGE
      await firestore
          .collection('support_messages')
          .doc(uid)
          .collection('messages')
          .add({
        'text': text,
        'isUser': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await updateAnalytics(isUser: true);

      messageController.clear();

      // 🤖 AI RESPONSE
      final aiResponse = generateAIResponse(text);

      await firestore
          .collection('support_messages')
          .doc(uid)
          .collection('messages')
          .add({
        'text': aiResponse,
        'isUser': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await updateAnalytics(isUser: false);

      _scrollToBottom();
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 🤖 AI
  String generateAIResponse(String input) {
    input = input.toLowerCase();

    if (input.contains("pain")) {
      return "Stay hydrated and rest. If pain persists, contact a doctor.";
    } else if (input.contains("water")) {
      return "Drink at least 2–3 liters daily to prevent crisis.";
    } else if (input.contains("food")) {
      return "Eat balanced meals rich in vitamins.";
    } else if (input.contains("emergency")) {
      return "If urgent, go to the Emergency tab immediately.";
    } else {
      return "Thanks for your message. A professional may respond if needed.";
    }
  }

  // 🚨 CALL
  Future<void> callEmergency() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '112');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;

    return Scaffold(
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text("Support Center"),
        backgroundColor: Colors.redAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Chat"),
            Tab(text: "Emergency"),
            Tab(text: "FAQs"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [

          // 💬 CHAT
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('support_messages')
                      .doc(uid)
                      .collection('messages')
                      .orderBy('createdAt')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!.docs;

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text("Start a conversation 👋"),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data =
                            messages[index].data() as Map<String, dynamic>;

                        final isUser = data['isUser'] ?? false;

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.redAccent
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // INPUT
              Container(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          hintText: "Type your message...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.redAccent),
                      onPressed: sendMessage,
                    )
                  ],
                ),
              )
            ],
          ),

          // 🚨 EMERGENCY
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  "Emergency Help",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text("Call emergency services immediately"),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: callEmergency,
                  icon: const Icon(Icons.call),
                  label: const Text("Call Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                )
              ],
            ),
          ),

          // ❓ FAQ
          faqs.isEmpty
              ? const Center(child: Text("No FAQs available"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: faqs.map((faq) {
                    return Card(
                      child: ExpansionTile(
                        title: Text(faq['question'] ?? ''),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(faq['answer'] ?? ''),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}