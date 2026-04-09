import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessagesScreen extends StatelessWidget {
  const SupportMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Support Chats"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('support_messages').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView(
            children: users.map((userDoc) {
              return ListTile(
                title: Text("User: ${userDoc.id}"),
                trailing: const Icon(Icons.chat),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}