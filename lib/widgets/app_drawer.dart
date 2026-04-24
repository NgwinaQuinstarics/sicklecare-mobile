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
  final String currentRoute;

  const AppDrawer({super.key, this.currentRoute = ""});

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color deepNavy = Color(0xFF0D47A1);
  static const Color softGrey = Color(0xFFF1F5F9);
  static const Color textMain = Color(0xFF1E293B);
  static const Color alertRed = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(user?.email ?? "User Account"),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _label("CORE NAVIGATION"),
                _item(context, "Dashboard", Icons.grid_view_rounded,
                    const HomeScreen(), "home"),

                _item(context, "Health Tracker", Icons.favorite_rounded,
                    const HydrationNutritionScreen(), "health"),

                _item(context, "Vitals Monitoring", Icons.monitor_heart_rounded,
                    const TrackerScreen(), "tracker"),

                const SizedBox(height: 20),

                _label("WELLNESS TOOLS"),
                _item(context, "Medication & Water",
                    Icons.notifications_active_rounded,
                    const RemindersScreen(), "reminders"),

                _item(context, "Climate Outlook", Icons.wb_sunny_rounded,
                    const WeatherScreen(), "weather"),

                _item(context, "Community Support", Icons.support_agent,
                    const SupportScreen(), "support"),

                const SizedBox(height: 20),

                _label("ACCOUNT"),
                _item(context, "Analytics History", Icons.analytics_rounded,
                    const HistoryScreen(), "history"),

                _item(context, "Personal Profile", Icons.person_rounded,
                    const ProfileScreen(), "profile"),
              ],
            ),
          ),

          _bottomActions(context),
        ],
      ),
    );
  }

  /// 🔷 HEADER
  Widget _buildHeader(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, deepNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.favorite, color: primaryBlue, size: 30),
          ),
          const SizedBox(height: 15),
          const Text(
            "SICKLECARE",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 10),
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

  /// 🔷 NAV ITEM (WITH ACTIVE STATE)
  Widget _item(BuildContext context, String title, IconData icon,
      Widget screen, String route) {
    final isActive = currentRoute == route;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isActive ? primaryBlue : Colors.grey[700], size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? primaryBlue : textMain,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pop(context);

          if (!isActive) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => screen),
            );
          }
        },
      ),
    );
  }

  /// 🔻 BOTTOM ACTIONS
  Widget _bottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: softGrey,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
            Icons.delete_forever,
            alertRed,
            () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// ⚠️ DELETE CONFIRMATION
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Permanent Deletion"),
        content: const Text(
            "All your health data will be erased permanently."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: alertRed,
            ),
            child: const Text("Delete"),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              try {
                await user?.delete();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text("Please re-login before deleting account")),
                );
              }
            },
          )
        ],
      ),
    );
  }
}