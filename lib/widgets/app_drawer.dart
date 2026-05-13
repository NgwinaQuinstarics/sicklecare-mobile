import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/support_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/profile_screen.dart';
import '../login.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color danger = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: background,
      child: SafeArea(
        child: Column(
          children: [

            /// ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue,
                    Color(0xFF2563EB),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.favorite,
                      color: primaryBlue,
                      size: 34,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "SickleCare",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    user?.email ?? "Patient Account",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            /// ================= MENU =================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  _sectionTitle("TOOLS"),

                  _drawerTile(
                    context,
                    icon: Icons.cloud_outlined,
                    title: "Weather Forecast",
                    subtitle: "Monitor climate conditions",
                    color: Colors.blueGrey,
                    page: const WeatherScreen(),
                  ),

                  _drawerTile(
                    context,
                    icon: Icons.support_agent,
                    title: "Support Center",
                    subtitle: "Community & help resources",
                    color: Colors.teal,
                    page: const SupportScreen(),
                  ),

                  const SizedBox(height: 20),

                  _sectionTitle("ACCOUNT"),

                  /// ================= PROFILE (NEW) =================
                  _drawerTile(
                    context,
                    icon: Icons.person,
                    title: "Profile",
                    subtitle: "Manage your personal health data",
                    color: Colors.indigo,
                    page: const ProfileScreen(),
                  ),

                  const SizedBox(height: 10),

                  /// ================= LOGOUT =================
                  _actionTile(
                    context,
                    icon: Icons.logout_rounded,
                    title: "Sign Out",
                    color: primaryBlue,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();

                      if (!context.mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),

                  /// ================= DELETE ACCOUNT =================
                  _actionTile(
                    context,
                    icon: Icons.delete_forever_rounded,
                    title: "Delete Account",
                    color: danger,
                    onTap: () => _showDeleteDialog(context),
                  ),
                ],
              ),
            ),

            /// ================= FOOTER =================
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  Divider(),
                  SizedBox(height: 10),
                  Text(
                    "SickleCare v1.0",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Your daily health companion 💙",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= SECTION TITLE =================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 12, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// ================= NAV TILE =================
  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget page,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  /// ================= ACTION TILE =================
  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// ================= DELETE DIALOG =================
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Delete Account"),
        content: const Text(
          "This action permanently removes your account and health records.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: danger,
            ),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.delete();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Please login again before deleting account.",
                    ),
                  ),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}