import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/support_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/profile_screen.dart';

import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/terms_screen.dart';
import '../screens/settings/feedback_screen.dart';
import '../screens/settings/about_screen.dart';

import '../login.dart';

class AppDrawer extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const AppDrawer({
    super.key,
    this.onThemeChanged,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool isDarkMode = false;

  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color danger = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  /// ================= LOAD THEME =================
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  /// ================= SAVE THEME =================
  Future<void> toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('darkMode', value);

    setState(() {
      isDarkMode = value;
    });

    widget.onThemeChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final background =
        isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final cardColor =
        isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    final textColor =
        isDarkMode ? Colors.white : Colors.black87;

    final subtitleColor =
        isDarkMode ? Colors.white70 : Colors.black54;

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

                  /// LOGO
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Image.asset(
                      "assets/logo.png",
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 16),

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

                  /// ================= APPEARANCE =================
                  _sectionTitle(
                    "APPEARANCE",
                    isDarkMode,
                  ),

                  Card(
                    elevation: 0,
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: SwitchListTile(
                      value: isDarkMode,

                      onChanged: toggleTheme,

                      secondary: CircleAvatar(
                        backgroundColor:
                            Colors.deepPurple.withValues(alpha: 0.12),

                        child: Icon(
                          isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Colors.deepPurple,
                        ),
                      ),

                      title: Text(
                        "Dark Mode",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      subtitle: Text(
                        "Persistent theme mode",
                        style: TextStyle(
                          color: subtitleColor,
                        ),
                      ),

                      activeThumbColor: primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// ================= TOOLS =================
                  _sectionTitle(
                    "TOOLS",
                    isDarkMode,
                  ),

                  /// WEATHER
                  _drawerTile(
                    context,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    icon: Icons.cloud_outlined,
                    title: "Weather Forecast",
                    subtitle: "Monitor climate conditions",
                    color: Colors.blueGrey,
                    page: const WeatherScreen(),
                  ),

                  /// SUPPORT
                  _drawerTile(
                    context,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    icon: Icons.support_agent,
                    title: "Support Center",
                    subtitle: "Community & emergency help",
                    color: Colors.teal,
                    page: const SupportScreen(),
                  ),

                  const SizedBox(height: 20),

                  /// ================= ACCOUNT =================
                  _sectionTitle(
                    "ACCOUNT",
                    isDarkMode,
                  ),

                  /// PROFILE
                  _drawerTile(
                    context,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    icon: Icons.person_outline,
                    title: "Profile",
                    subtitle: "Manage personal health data",
                    color: Colors.indigo,
                    page: const ProfileScreen(),
                  ),

                  const SizedBox(height: 20),

                  /// ================= LEGAL =================
                  _sectionTitle(
                    "LEGAL & SUPPORT",
                    isDarkMode,
                  ),

                  /// FEEDBACK
                  _drawerTile(
                    context,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    icon: Icons.feedback_outlined,
                    title: "Send Feedback",
                    subtitle: "Help us improve the app",
                    color: Colors.orange,
                    page: const FeedbackScreen(),
                  ),

                  /// PRIVACY POLICY
                  _drawerTile(
                    context,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    icon: Icons.privacy_tip_outlined,
                    title: "Privacy Policy",
                    subtitle: "How your data is protected",
                    color: Colors.green,
                    page: const PrivacyPolicyScreen(),
                  ),

                  /// TERMS
                  _drawerTile(
                    context,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    icon: Icons.description_outlined,
                    title: "Terms & Conditions",
                    subtitle: "Read app usage policies",
                    color: Colors.deepPurple,
                    page: const TermsScreen(),
                  ),

                  /// ABOUT
                  _drawerTile(
                    context,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    icon: Icons.info_outline,
                    title: "About App",
                    subtitle: "App information & developer",
                    color: Colors.cyan,
                    page: const AboutScreen(),
                  ),

                  const SizedBox(height: 20),

                  /// ================= ACCOUNT ACTIONS =================
                  _sectionTitle(
                    "ACCOUNT ACTIONS",
                    isDarkMode,
                  ),

                  /// LOGOUT
                  _actionTile(
                    context,
                    cardColor: cardColor,
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

                  /// DELETE ACCOUNT
                  _actionTile(
                    context,
                    cardColor: cardColor,
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
                children: [

                  Divider(
                    color: isDarkMode
                        ? Colors.white24
                        : Colors.grey.shade300,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "SickleCare v1.0.0",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Your daily health companion 💙",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Developed for sickle cell support & awareness",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 10,
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
  Widget _sectionTitle(
    String title,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 10,
        bottom: 12,
        top: 10,
      ),

      child: Text(
        title,

        style: TextStyle(
          color:
              isDarkMode ? Colors.white54 : Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// ================= NAVIGATION TILE =================
  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget page,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Card(
      elevation: 0,
      color: cardColor,
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
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),

        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),

        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: subtitleColor,
          ),
        ),

        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: subtitleColor,
        ),

        onTap: () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
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
    required Color cardColor,
  }) {
    return Card(
      elevation: 0,
      color: cardColor,
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
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),

        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
        ),

        onTap: onTap,
      ),
    );
  }

  /// ================= DELETE ACCOUNT DIALOG =================
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