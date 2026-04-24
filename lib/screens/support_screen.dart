import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  bool isLoading = false;

  String get uid => user!.uid;

  CollectionReference get chatRef => firestore
      .collection('users')
      .doc(uid)
      .collection('chat')
      .doc('messages')
      .collection('items');

  // ================= SEND MESSAGE =================
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    controller.clear();

    // 1. Save user message
    await chatRef.add({
      "role": "user",
      "content": text,
      "timestamp": FieldValue.serverTimestamp(),
    });

    scrollToBottom();

    setState(() => isLoading = true);

    try {
      // 2. Call Firebase AI Function
      final callable =
          FirebaseFunctions.instance.httpsCallable('sickleCareAI');

      final snapshot = await chatRef.orderBy("timestamp").get();

      final messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "role": data["role"],
          "content": data["content"]
        };
      }).toList();

      final result = await callable.call({
        "messages": messages,
      });

      final reply = result.data["reply"];

      // 3. Save AI response
      await chatRef.add({
        "role": "assistant",
        "content": reply,
        "timestamp": FieldValue.serverTimestamp(),
      });

    } catch (e) {
      await chatRef.add({
        "role": "assistant",
        "content":
            "I'm having trouble connecting right now. Please try again.",
        "timestamp": FieldValue.serverTimestamp(),
      });
    }

    setState(() => isLoading = false);

    scrollToBottom();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF4F7FA),

      appBar: AppBar(
        title: const Text("Care AI Chat 💬"),
        backgroundColor: const Color(0xFF1E40AF),
      ),

      body: Column(
        children: [

          // ================= CHAT STREAM =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatRef.orderBy("timestamp").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    final isUser = data["role"] == "user";

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFF1E40AF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.05),
                            )
                          ],
                        ),
                        child: Text(
                          data["content"] ?? "",
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ================= TYPING INDICATOR =================
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "AI is thinking...",
                style: TextStyle(color: Colors.grey),
              ),
            ),

          // ================= INPUT =================
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: sendMessage,
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send,
                      color: Color(0xFF1E40AF)),
                  onPressed: () =>
                      sendMessage(controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}