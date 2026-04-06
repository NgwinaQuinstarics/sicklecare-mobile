import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/home_screen.dart';
import '../screens/hydration_nutrition_screen.dart';
import '../screens/tracker_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/support_screen.dart';
import '../screens/history_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountEmail: Text(user?.email ?? ""),
            accountName: const Text("SickleCare User"),
            decoration: const BoxDecoration(color: Colors.redAccent),
          ),

          _item(context, "Home", Icons.home, const HomeScreen()),
          _item(context, "Health", Icons.favorite, const HydrationNutritionScreen()),
          _item(context, "Tracker", Icons.warning, const TrackerScreen()),
          _item(context, "Reminders", Icons.alarm, const RemindersScreen()),
          _item(context, "Goals", Icons.flag, const GoalsScreen()),
          _item(context, "Support", Icons.people, const SupportScreen()),
          _item(context, "Analytics", Icons.show_chart, const HistoryScreen()),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String title, IconData icon, Widget screen) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }
}