import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/home_screen.dart';
import '../screens/hydration_nutrition_screen.dart';
import '../screens/tracker_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/history_screen.dart';
import '../screens/support_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/profile_screen.dart';
import '../login.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [

          UserAccountsDrawerHeader(
            accountEmail: Text(user?.email ?? ""),
            accountName: const Text("SickleCare"),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1565C0),
                  Color(0xFF26A69A),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              children: [

                _item(context, "Home", Icons.home, const HomeScreen()),
                _item(context, "Health", Icons.favorite, const HydrationNutritionScreen()),
                _item(context, "Tracker", Icons.monitor_heart, const TrackerScreen()),
                _item(context, "Reminders", Icons.alarm, const RemindersScreen()),
                _item(context, "Goals", Icons.flag, const GoalsScreen()),
                _item(context, "Weather", Icons.cloud, const WeatherScreen()),
                _item(context, "Support", Icons.support_agent, const SupportScreen()),
                _item(context, "Analytics", Icons.show_chart, const HistoryScreen()),
                _item(context, "Profile", Icons.person, const ProfileScreen()),

                const Divider(),

                // LOGOUT
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();

                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),

                // DELETE ACCOUNT
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Delete Account"),
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String title, IconData icon, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1565C0)),
      title: Text(title),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("This action is permanent. Continue?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              try {
                await user?.delete();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please re-login before deleting account"),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}