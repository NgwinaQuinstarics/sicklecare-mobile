import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController messageController = TextEditingController();

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent successfully')),
    );

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Support"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // HEADER CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent,
                        size: 40, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Need Help?\nWe are here for you 24/7",
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // QUICK ACTIONS
              Text(
                "Quick Help",
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickCard(Icons.help_outline, "FAQs"),
                  _quickCard(Icons.local_hospital, "Emergency"),
                  _quickCard(Icons.chat, "Live Chat"),
                ],
              ),

              const SizedBox(height: 24),

              // CONTACT FORM
              Text(
                "Contact Support",
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),

              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Describe your issue...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: sendMessage,
                        icon: const Icon(Icons.send),
                        label: const Text("Send Message"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // CONTACT INFO
              Text(
                "Other Ways to Reach Us",
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),

              _contactTile(Icons.email, "support@sicklecare.com"),
              _contactTile(Icons.phone, "+237 6XX XXX XXX"),
              _contactTile(Icons.location_on, "Douala, Cameroon"),
            ],
          ),
        ),
      ),
    );
  }

  // QUICK CARD
  Widget _quickCard(IconData icon, String title) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blueAccent),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  // CONTACT TILE
  Widget _contactTile(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        text,
        style: GoogleFonts.dmSans(fontSize: 13),
      ),
    );
  }
}