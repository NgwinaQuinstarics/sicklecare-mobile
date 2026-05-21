import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color background = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,

        title: const Text(
          "Terms & Conditions",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= HEADER =================
            Center(
              child: Column(
                children: [

                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Image.asset(
                      "assets/logo.png",
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "SickleCare Terms & Conditions",
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Last Updated: May 2026",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// ================= INTRODUCTION =================
            _section(
              title: "1. Introduction",
              content:
                  "Welcome to SickleCare. By using this application, you agree to comply with these Terms and Conditions. Please read them carefully before using the app.",
            ),

            /// ================= MEDICAL DISCLAIMER =================
            _section(
              title: "2. Medical Disclaimer",
              content:
                  "SickleCare is designed for educational and health-support purposes only. The app does not replace professional medical advice, diagnosis, or treatment. Always consult qualified healthcare professionals regarding medical conditions or emergencies.",
            ),

            /// ================= USER RESPONSIBILITIES =================
            _section(
              title: "3. User Responsibilities",
              content:
                  "Users are responsible for providing accurate information and using the app responsibly. Misuse of the platform, harmful behavior, or false medical data may result in restricted access.",
            ),

            /// ================= ACCOUNT SECURITY =================
            _section(
              title: "4. Account Security",
              content:
                  "You are responsible for maintaining the confidentiality of your login credentials. SickleCare is not liable for unauthorized access caused by negligence in securing your account.",
            ),

            /// ================= PRIVACY =================
            _section(
              title: "5. Privacy & Data",
              content:
                  "Your personal information is securely stored and protected. We do not sell user data to third parties. Health-related information is only used to improve app functionality and user experience.",
            ),

            /// ================= EMERGENCY =================
            _section(
              title: "6. Emergency Situations",
              content:
                  "SickleCare is not an emergency response service. In life-threatening situations, contact local emergency services or visit the nearest hospital immediately.",
            ),

            /// ================= LIMITATION =================
            _section(
              title: "7. Limitation of Liability",
              content:
                  "The developers of SickleCare are not responsible for damages, injuries, or losses resulting from misuse of the application or reliance on app-generated information.",
            ),

            /// ================= UPDATES =================
            _section(
              title: "8. Updates to Terms",
              content:
                  "We may update these Terms & Conditions periodically. Continued use of the app after updates means you accept the revised terms.",
            ),

            /// ================= CONTACT =================
            _section(
              title: "9. Contact Information",
              content:
                  "For questions regarding these Terms & Conditions, please contact the SickleCare support team through the Feedback section of the application.",
            ),

            const SizedBox(height: 30),

            /// ================= FOOTER =================
            Center(
              child: Column(
                children: const [

                  Divider(),

                  SizedBox(height: 15),

                  Text(
                    "Thank you for using SickleCare 💙",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "Your health and safety matter.",
                    style: TextStyle(
                      color: Colors.grey,
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

  /// ================= REUSABLE SECTION =================
  Widget _section({
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            content,
            style: const TextStyle(
              height: 1.7,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}