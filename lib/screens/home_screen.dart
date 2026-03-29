import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../store/app_state.dart';
import '../widgets/sc_card.dart';
import '../widgets/alert_box.dart';
import 'crisis_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hydration = context.watch<HydrationProvider>();
    final goals     = context.watch<GoalProvider>();
    final reminders = context.watch<ReminderProvider>();

    final now   = DateTime.now();
    final hour  = now.hour;
    final greet = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final today = '${_weekday(now.weekday)}, ${_month(now.month)} ${now.day}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$greet 👋', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy)),
                    Text(today, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted)),
                  ]),
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrisisScreen())),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: AppColors.roseLight, borderRadius: BorderRadius.circular(13)),
                        child: const Center(child: Text('🚨', style: TextStyle(fontSize: 20))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 42, height: 42,
                      decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                      child: Center(child: Text('AM',
                        style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
                    ),
                  ]),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // WEATHER ALERT
                    const AlertBox(
                      variant: AlertVariant.warning,
                      emoji: '🌧️',
                      title: 'Weather Alert',
                      message: 'Rain & temperature drop expected today. Stay warm and hydrated — cold triggers vaso-occlusive crises.',
                    ),

                    // HERO CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.blue, AppColors.blueMid],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Health Status', style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white70)),
                            Text('Amara', style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(children: [
                                Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF4DFFD4), shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('Stable · Low Risk', style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ]),
                          Column(children: [
                            Text('82', style: GoogleFonts.nunito(fontSize: 44, fontWeight: FontWeight.w900, color: const Color(0xFF4DFFD4), height: 1)),
                            Text('SCORE', style: GoogleFonts.nunito(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w700)),
                          ]),
                        ],
                      ),
                    ),

                    // STATS GRID
                    Row(children: [
                      _StatTile(emoji: '💧', value: '${hydration.glasses}/8', label: 'Glasses', color: AppColors.teal, bg: AppColors.tealLight, fill: hydration.percentage),
                      const SizedBox(width: 12),
                      _StatTile(emoji: '💊', value: '2/3', label: 'Meds', color: AppColors.blue, bg: AppColors.blueLight, fill: 0.66),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _StatTile(emoji: '🎯', value: '${goals.completed}/${goals.all.length}', label: 'Goals', color: AppColors.purple, bg: AppColors.purpleLight, fill: goals.weeklyPct),
                      const SizedBox(width: 12),
                      const _StatTile(emoji: '🔥', value: '14d', label: 'Streak', color: AppColors.amber, bg: AppColors.amberLight, fill: 0.7),
                    ]),
                    const SizedBox(height: 20),

                    // REMINDERS
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text("Today's Reminders", style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.navy)),
                      Text('See all', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 10),

                    ...reminders.all.take(3).map((r) => _ReminderRow(reminder: r)),

                    const SizedBox(height: 6),
                    Text('Daily Tip', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.navy)),
                    const SizedBox(height: 10),

                    ScCard(
                      color: AppColors.purpleLight,
                      border: const Border(left: BorderSide(color: AppColors.purple, width: 4)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('💡', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text('Stay Hydrated in Cold Weather', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.navy)),
                        const SizedBox(height: 5),
                        Text('Cold temperatures can trigger vaso-occlusive crises. Drink at least 8 glasses of water and wear warm layers.',
                          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textLight, height: 1.5)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekday(int d) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d - 1];
  String _month(int m)   => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _StatTile extends StatelessWidget {
  final String emoji, value, label;
  final Color color, bg;
  final double fill;

  const _StatTile({required this.emoji, required this.value, required this.label, required this.color, required this.bg, required this.fill});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color, blurRadius: 10, offset: const Offset(0,3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy, height: 1)),
          Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fill, minHeight: 5,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final dynamic reminder;
  const _ReminderRow({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final done = reminder.id == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.blue , offset: const Offset(0,3))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44, decoration: BoxDecoration(
            color: done ? AppColors.greenLight : AppColors.blueLight,
            borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(reminder.typeEmoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reminder.title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy)),
          Text('${reminder.time} · ${reminder.frequency}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: done ? AppColors.greenLight : AppColors.amberLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(done ? '✓ Done' : 'Pending',
            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700,
              color: done ? const Color(0xFF15803D) : const Color(0xFFB45309))),
        ),
      ]),
    );
  }
}
