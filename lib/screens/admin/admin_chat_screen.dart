import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_chat_detail_screen.dart';

class AdminChatScreen extends StatelessWidget {
  const AdminChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Chats"),
        backgroundColor: const Color(0xFF317FED),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('support_chats')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              return ListTile(
                title: Text(chat.id),
                subtitle: Text(chat['lastMessage'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminChatDetailScreen(userId: chat.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}