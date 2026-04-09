import 'package:flutter/material.dart';

import 'manage_faq_screen.dart';
import 'support_messages_screen.dart';
import 'user_analytics_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [

            _card(
              context,
              "Manage FAQs",
              Icons.question_answer,
              const ManageFaqScreen(),
            ),

            _card(
              context,
              "Support Chats",
              Icons.chat,
              const SupportMessagesScreen(),
            ),

            _card(
              context,
              "User Analytics",
              Icons.analytics,
              const UserAnalyticsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
      BuildContext context,
      String title,
      IconData icon,
      Widget screen,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}