import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color background = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          "Privacy Policy",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= LOGO =================
            Center(
              child: Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(15),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Image.asset(
                  "assets/logo.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// ================= TITLE =================
            const Text(
              "SickleCare Privacy Policy",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Last Updated: May 2026",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            /// ================= INTRO =================
            _section(
              title: "1. Introduction",
              content:
                  "SickleCare is committed to protecting your privacy and personal health information. "
                  "This Privacy Policy explains how we collect, use, store, and protect your information "
                  "when you use our mobile application.",
            ),

            /// ================= DATA COLLECTION =================
            _section(
              title: "2. Information We Collect",
              content:
                  "We may collect the following information:\n\n"
                  "• Full Name\n"
                  "• Email Address\n"
                  "• Health profile information\n"
                  "• Emergency contacts\n"
                  "• Medication reminders\n"
                  "• App usage statistics\n"
                  "• Device and crash analytics",
            ),

            /// ================= DATA USAGE =================
            _section(
              title: "3. How We Use Your Information",
              content:
                  "Your information is used to:\n\n"
                  "• Provide health tracking features\n"
                  "• Improve user experience\n"
                  "• Send medication reminders\n"
                  "• Improve app performance\n"
                  "• Provide support services\n"
                  "• Maintain account security",
            ),

            /// ================= FIREBASE =================
            _section(
              title: "4. Data Storage & Security",
              content:
                  "Your data is securely stored using Firebase services. "
                  "We implement industry-standard security measures to protect your information "
                  "against unauthorized access, alteration, disclosure, or destruction.",
            ),

            /// ================= THIRD PARTY =================
            _section(
              title: "5. Third-Party Services",
              content:
                  "SickleCare may use trusted third-party services such as Firebase Authentication, "
                  "Cloud Firestore, Analytics, and Crash Reporting to improve reliability and security.",
            ),

            /// ================= USER RIGHTS =================
            _section(
              title: "6. Your Rights",
              content:
                  "You have the right to:\n\n"
                  "• Access your personal data\n"
                  "• Update your information\n"
                  "• Delete your account\n"
                  "• Request data removal\n"
                  "• Stop using the application at any time",
            ),

            /// ================= CHILDREN =================
            _section(
              title: "7. Children's Privacy",
              content:
                  "SickleCare does not knowingly collect personal information "
                  "from children without parental consent.",
            ),

            /// ================= CONTACT =================
            _section(
              title: "8. Contact Us",
              content:
                  "If you have any questions regarding this Privacy Policy, "
                  "please contact the SickleCare support team.",
            ),

            const SizedBox(height: 30),

            /// ================= FOOTER =================
            Center(
              child: Column(
                children: const [

                  Text(
                    "SickleCare v1.0",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    "Your health data matters 💙",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// ================= SECTION WIDGET =================
  Widget _section({
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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

          const SizedBox(height: 10),

          Text(
            content,
            style: TextStyle(
              height: 1.6,
              color: Colors.grey.shade800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}