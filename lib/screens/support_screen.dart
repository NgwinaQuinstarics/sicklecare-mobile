import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../widgets/sc_card.dart';
import 'crisis_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _steps = [
    {'num': '1', 'title': 'Stay calm & find warmth',   'body': 'Move to a warm place. Cold temperatures trigger vaso-occlusive episodes.'},
    {'num': '2', 'title': 'Hydrate immediately',        'body': 'Drink 2+ glasses of water now. Dehydration worsens sickling badly.'},
    {'num': '3', 'title': 'Take prescribed pain meds',  'body': 'As directed by your hematologist. Do not exceed prescribed dosage.'},
    {'num': '4', 'title': 'Rest in a safe position',    'body': 'Lie down and elevate legs if joint pain. Avoid tight clothing.'},
    {'num': '5', 'title': 'Call emergency if severe',   'body': 'Pain 7+/10 or lasting 30+ minutes? Call your doctor or nearest hospital.'},
  ];

  static const _contacts = [
    {'emoji': '👨‍⚕️', 'name': 'Dr. Emmanuel Osei',  'role': 'Hematologist · Laquintinie Hospital', 'phone': '+237600000001', 'urgent': false},
    {'emoji': '👩',  'name': 'Mama Grace',           'role': 'Primary caregiver',                   'phone': '+237600000002', 'urgent': false},
    {'emoji': '🏥',  'name': 'Laquintinie Hospital', 'role': '3.2 km · Emergency dept.',            'phone': '+237699000000', 'urgent': true},
  ];

  void _call(BuildContext context, String phone, String name) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Call $name?', style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
      content: Text(phone, style: GoogleFonts.dmSans()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            final uri = Uri.parse('tel:$phone');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          },
          child: Text('Call Now', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w800)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Support & Crisis', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy)),
              Text('Emergency resources', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // BIG CRISIS BTN
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrisisScreen())),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(22),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.rose, borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: AppColors.rose.withOpacity(0.4), blurRadius: 16, offset: const Offset(0,8))],
                    ),
                    child: Column(children: [
                      const Text('🚨', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 8),
                      Text('Activate Crisis Mode', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('Tap immediately during a pain episode',
                        style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white70)),
                    ]),
                  ),
                ),

                Text('What To Do During a Crisis',
                  style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.navy)),
                const SizedBox(height: 12),

                ..._steps.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.roseLight, borderRadius: BorderRadius.circular(16)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 30, height: 30, decoration: const BoxDecoration(color: AppColors.rose, shape: BoxShape.circle),
                      child: Center(child: Text(s['num']!, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['title']!, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      const SizedBox(height: 3),
                      Text(s['body']!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textLight, height: 1.4)),
                    ])),
                  ]),
                )),

                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Emergency Contacts', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.navy)),
                  Text('+ Add', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.blue, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),

                ..._contacts.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.blue, blurRadius: 8, offset: const Offset(0,3))],
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44, decoration: const BoxDecoration(color: AppColors.blueLight, shape: BoxShape.circle),
                      child: Center(child: Text(c['emoji'] as String, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['name'] as String, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      Text(c['role'] as String, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
                    ])),
                    GestureDetector(
                      onTap: () => _call(context, c['phone'] as String, c['name'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: (c['urgent'] as bool) ? AppColors.roseLight : AppColors.greenLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (c['urgent'] as bool) ? '🚑 Now' : '📞 Call',
                          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700,
                            color: (c['urgent'] as bool) ? const Color(0xFFBE185D) : const Color(0xFF15803D)),
                        ),
                      ),
                    ),
                  ]),
                )),

                ScCard(
                  color: AppColors.blueLight,
                  border: const Border(left: BorderSide(color: AppColors.blue, width: 3)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('🗺️', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text('Find Nearby Hospitals', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.navy)),
                    const SizedBox(height: 5),
                    Text('Location-based hospital search coming soon. Save your nearest hospital in Emergency Contacts above.',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted, height: 1.5)),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
