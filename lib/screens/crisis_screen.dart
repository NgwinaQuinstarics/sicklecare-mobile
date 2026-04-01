import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key});

  // Emergency contacts (Cameroon example)
  final String hotlineNumber = 'tel:+237 671319479';
  final String chatUrl = 'https://example.com/chat';
  final String resourcesUrl = 'https://example.com/resources';

  // Launch URL / phone
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  // Educational content (will later come from Firebase)
  final String educationalContent = '''
• Stay hydrated – drink plenty of water daily.
• Avoid extreme temperatures (very cold or very hot).
• Get enough rest and avoid overexertion.
• Take medications exactly as prescribed.
• Manage stress through calm activities like music, reading, or prayer.
''';

  final String adviceContent = '''
• You are not alone in this journey.
• Listen to your body and rest when needed.
• Seek medical help early if symptoms worsen.
• Stay consistent with your care routine.
• Talk to someone you trust when you feel overwhelmed.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crisis Support'),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            // ===== HEADER =====
            const Text(
              'Immediate Help',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            const Text(
              'If you are experiencing a crisis, support is available. Please reach out immediately using any option below.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // ===== BUTTONS =====
            ElevatedButton.icon(
              onPressed: () => _launchURL(hotlineNumber),
              icon: const Icon(Icons.phone),
              label: const Text('Call Hotline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => _launchURL(chatUrl),
              icon: const Icon(Icons.chat),
              label: const Text('Chat Online'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => _launchURL(resourcesUrl),
              icon: const Icon(Icons.book),
              label: const Text('View Resources'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 30),

            // ===== EDUCATIONAL SECTION =====
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.school, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Health Education',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      educationalContent,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== ADVICE SECTION =====
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text(
                          'Advice for Warriors 💪',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      adviceContent,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== FOOTER =====
            const Text(
              'This app provides support but does not replace professional medical care. Always consult a healthcare provider as soon as possible.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}