import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color background = Color(0xFFF8FAFC);

  String appVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    loadAppInfo();
  }

  /// ================= LOAD APP VERSION =================
  Future<void> loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();

    setState(() {
      appVersion = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        title: const Text(
          "About SickleCare",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            /// ================= LOGO =================
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 25),

            /// ================= APP NAME =================
            const Text(
              'SickleCare',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Version $appVersion',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 30),

            /// ================= ABOUT =================
            _buildCard(
              title: 'About the App',
              icon: Icons.info_outline,

              child: const Text(
                'SickleCare is a digital health companion designed to help people living with sickle cell disease manage their daily health, monitor symptoms, access support resources, and stay informed about weather conditions that may affect their health.',
                style: TextStyle(
                  height: 1.6,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ================= FEATURES =================
            _buildCard(
              title: 'Main Features',
              icon: Icons.health_and_safety_outlined,

              child: Column(
                children: const [

                  _FeatureTile(
                    text: 'Health profile management',
                  ),

                  _FeatureTile(
                    text: 'Emergency support access',
                  ),

                  _FeatureTile(
                    text: 'Weather monitoring',
                  ),

                  _FeatureTile(
                    text: 'Medication reminders',
                  ),

                  _FeatureTile(
                    text: 'Secure patient authentication',
                  ),

                  _FeatureTile(
                    text: 'Feedback and support system',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ================= SECURITY =================
            _buildCard(
              title: 'Security & Privacy',
              icon: Icons.lock_outline,

              child: const Text(
                'SickleCare values user privacy and protects sensitive medical information using secure Firebase authentication and cloud storage technologies.',
                style: TextStyle(
                  height: 1.6,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ================= DEVELOPER INFO =================
            _buildCard(
              title: 'Developer Information',
              icon: Icons.code,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [

                  Text(
                    'Developed for educational and healthcare support purposes.',
                    style: TextStyle(height: 1.6),
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Country: Cameroon',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Made with ❤️ for the sickle cell community',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= REUSABLE CARD =================
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Icon(icon, color: primaryBlue),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          child,
        ],
      ),
    );
  }
}

/// ================= FEATURE TILE =================
class _FeatureTile extends StatelessWidget {
  final String text;

  const _FeatureTile({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        children: [

          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}