import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAnalyticsScreen extends StatelessWidget {
  const UserAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Analytics"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('support_analytics').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView(
            children: users.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text("User: ${doc.id}"),
                  subtitle: Text(
                    "Total: ${data['totalMessages'] ?? 0} | "
                    "User: ${data['userMessages'] ?? 0} | "
                    "AI: ${data['aiMessages'] ?? 0}",
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}