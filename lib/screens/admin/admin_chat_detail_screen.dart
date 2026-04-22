import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String userId;

  const AdminChatDetailScreen({super.key, required this.userId});

  @override
  State<AdminChatDetailScreen> createState() =>
      _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState
    extends State<AdminChatDetailScreen> {

  final firestore = FirebaseFirestore.instance;
  final messageController = TextEditingController();

  Future<void> sendReply() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final chatRef =
        firestore.collection('support_chats').doc(widget.userId);

    await chatRef.collection('messages').add({
      'text': text,
      'sender': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat: ${widget.userId}"),
        backgroundColor: const Color(0xFF317FED),
      ),
      body: Column(
        children: [

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('support_chats')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView(
                  children: messages.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isAdmin = data['sender'] == 'admin';

                    return Align(
                      alignment: isAdmin
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? const Color(0xFF317FED)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          data['text'],
                          style: TextStyle(
                            color:
                                isAdmin ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(controller: messageController),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: sendReply,
              )
            ],
          )
        ],
      ),
    );
  }
}