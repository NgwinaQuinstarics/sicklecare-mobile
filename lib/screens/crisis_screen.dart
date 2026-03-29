import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class CrisisScreen extends StatefulWidget {
  const CrisisScreen({super.key});
  @override
  State<CrisisScreen> createState() => _CrisisScreenState();
}

class _CrisisScreenState extends State<CrisisScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _call(String phone, String name) async {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF2A0A12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Call $name?',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: Colors.white)),
              content: Text(phone, style: GoogleFonts.dmSans(color: Colors.white70)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.white54))),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                  child: Text('Call Now',
                      style: TextStyle(
                          color: AppColors.rose, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ],
            ));
  }

  void _dismiss() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Cancel Crisis Mode?", style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
              content: Text('Only dismiss if you no longer need emergency help.',
                  style: GoogleFonts.dmSans()),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay in Crisis Mode')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text("I'm okay"),
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crisisBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(children: [
            // PULSING ICON
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Stack(alignment: Alignment.center, children: [
                Container(
                  width: 120 + (_pulse.value * 10),
                  height: 120 + (_pulse.value * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.rose, width: 2),
                  ),
                ),
                Container(
                  width: 100 + (_pulse.value * 6),
                  height: 100 + (_pulse.value * 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.rose, width: 2),
                  ),
                ),
                const Text('🚨', style: TextStyle(fontSize: 52)),
              ]),
            ),
            const SizedBox(height: 20),

            Text('Crisis Mode Active',
                style: GoogleFonts.nunito(
                    fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Stay calm. Follow the steps below and call for help.',
                style:
                    GoogleFonts.dmSans(fontSize: 14, color: Colors.white60, height: 1.4),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),

            // STEPS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white),
              ),
              child: Column(
                children: [
                  ...[
                    'Move to a warm place immediately',
                    'Drink 2+ glasses of water now',
                    'Take prescribed pain medication',
                    'Rest — avoid tight clothing',
                    'Call your doctor if pain is 7+/10',
                  ].asMap().entries.map((e) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: e.key < 4
                            ? BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.white)))
                            : null,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                                color: AppColors.rose, shape: BoxShape.circle),
                            child: Center(
                                child: Text('${e.key + 1}',
                                    style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                            e.value,
                            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, height: 1.5),
                          )),
                        ]),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CALL BUTTONS
            GestureDetector(
              onTap: () => _call('+237699000000', 'Laquintinie Hospital'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.rose, blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Text('🚑 Call Hospital Emergency',
                        style: GoogleFonts.nunito(
                            fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('Laquintinie Hospital',
                        style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white60)),
                  ],
                ),
              ),
            ),

            GestureDetector(
              onTap: () => _call('+237600000001', 'Dr. Emmanuel Osei'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration:
                    BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text('📞 Call Doctor',
                        style: GoogleFonts.nunito(
                            fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('Dr. Emmanuel Osei',
                        style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white60)),
                  ],
                ),
              ),
            ),

            // LOCATION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white),
              ),
              child: Center(
                  child: Text('📍 Share My Location',
                      style: GoogleFonts.nunito(
                          fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white70))),
            ),

            // DISMISS
            GestureDetector(
              onTap: _dismiss,
              child: Text("I'm okay — Cancel Crisis Mode",
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: Colors.white38, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ),
          ]),
        ),
      ),
    );
  }
}