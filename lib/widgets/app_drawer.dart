import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/home_screen.dart';
import '../screens/hydration_nutrition_screen.dart';
import '../screens/tracker_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/history_screen.dart';
import '../screens/support_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/profile_screen.dart';
import '../login.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Solid Palette - No Opacity
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color deepNavy = Color(0xFF0D47A1);
  static const Color softGrey = Color(0xFFF1F5F9);
  static const Color textMain = Color(0xFF1E293B);
  static const Color alertRed = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // CUSTOM REFINED HEADER
          _buildHeader(user?.email ?? "User Account"),

          // NAVIGATION LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              children: [
                _drawerLabel("CORE NAVIGATION"),
                _item(context, "Dashboard", Icons.grid_view_rounded, const HomeScreen()),
                _item(context, "Health Tracker", Icons.favorite_rounded, const HydrationNutritionScreen()),
                _item(context, "Vitals Monitoring", Icons.monitor_heart_rounded, const TrackerScreen()),
                
                const SizedBox(height: 20),
                _drawerLabel("WELLNESS TOOLS"),
                _item(context, "Medication & Water", Icons.notification_important_rounded, const RemindersScreen()),
                _item(context, "Climate Outlook", Icons.wb_sunny_rounded, const WeatherScreen()),
                _item(context, "Community Support", Icons.diversity_3_rounded, const SupportScreen()),
                
                const SizedBox(height: 20),
                _drawerLabel("ACCOUNT"),
                _item(context, "Analytics History", Icons.analytics_rounded, const HistoryScreen()),
                _item(context, "Personal Profile", Icons.person_pin_rounded, const ProfileScreen()),
              ],
            ),
          ),

          // BOTTOM ACTIONS SECTION
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.shield_rounded, color: primaryBlue, size: 35),
          ),
          const SizedBox(height: 15),
          const Text(
            "SICKLECARE",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              fontSize: 18,
            ),
          ),
          Text(
            email,
            style: const TextStyle(color: Color(0xFFBBDEFB), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _drawerLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String title, IconData icon, Widget screen) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: primaryBlue, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: textMain,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: softGrey,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _actionTile(
            context,
            "Sign Out",
            Icons.logout_rounded,
            deepNavy,
            () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 10),
          _actionTile(
            context,
            "Close Account",
            Icons.delete_forever_rounded,
            alertRed,
            () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Permanent Deletion"),
        content: const Text("All your health data will be erased. This cannot be undone."),
        actions: [
          TextButton(
            child: const Text("Stay", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: alertRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Delete Everything", style: TextStyle(color: Colors.white)),
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Security: Please re-login to verify your identity.")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}