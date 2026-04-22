import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  Future<void> sendMessage() async {
    final uid = user?.uid;
    if (uid == null || messageController.text.trim().isEmpty) return;

    final text = messageController.text.trim();

    final chatRef = firestore.collection('support_chats').doc(uid);

    await chatRef.set({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'text': text,
      'sender': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Support"),
        backgroundColor: const Color(0xFF317FED),
      ),
      body: Column(
        children: [

          // 💬 CHAT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('support_chats')
                  .doc(uid)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                        messages[index].data() as Map<String, dynamic>;

                    final sender = data['sender'];

                    bool isUser = sender == 'user';

                    Color color = isUser
                        ? const Color(0xFF317FED)
                        : sender == 'admin'
                            ? Colors.green
                            : Colors.grey.shade300;

                    Alignment align = isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft;

                    return Align(
                      alignment: align,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ✏️ INPUT
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF317FED)),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}