import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../store/app_state.dart';
import '../widgets/sc_card.dart';
import '../widgets/sc_button.dart';

class HydrationScreen extends StatelessWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HydrationProvider>();
    final pct = (h.percentage * 100).round();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hydration 💧', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy)),
              Text('Stay hydrated, stay strong', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted)),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              child: Column(children: [

                // MAIN TRACKER
                ScCard(
                  child: Column(children: [
                    Text('TODAY\'S PROGRESS',
                      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800,
                        color: AppColors.muted, letterSpacing: 0.7)),
                    const SizedBox(height: 20),

                    Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      // Left: count
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${h.glasses}', style: GoogleFonts.nunito(fontSize: 52, fontWeight: FontWeight.w900, color: AppColors.teal, height: 1)),
                        Text('of ${h.goal} glasses', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(width: 24),

                      // Bottle
                      Stack(alignment: Alignment.center, children: [
                        Container(
                          width: 72, height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FEFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.teal, width: 3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                height: 120 * h.percentage,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                        ),
                        Text('$pct%', style: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.navy)),
                      ]),
                      const SizedBox(width: 24),

                      // Right: remaining
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Remaining', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                        Text('${h.goal - h.glasses}', style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.navy)),
                      ]),
                    ]),

                    const SizedBox(height: 20),

                    // GLASS BUTTONS
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(h.goal, (i) {
                        final filled = i < h.glasses;
                        return GestureDetector(
                          onTap: () => context.read<HydrationProvider>().setGlasses(i + 1),
                          child: Container(
                            width: 42, height: 50,
                            decoration: BoxDecoration(
                              color: filled ? AppColors.tealLight : AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: filled ? AppColors.teal : AppColors.border, width: 2),
                            ),
                            child: Center(child: Text(
                              filled ? '🥛' : '🫙', style: const TextStyle(fontSize: 22))),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    ScButton(
                      label: h.glasses >= h.goal ? '🎉 Goal Reached!' : '+ Log a Glass',
                      onPressed: h.glasses < h.goal ? () => context.read<HydrationProvider>().logGlass() : () {},
                      variant: BtnVariant.teal,
                    ),

                    if (h.glasses >= h.goal) ...[
                      const SizedBox(height: 10),
                      Text('Amazing! Daily goal reached. 🎉',
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.teal),
                        textAlign: TextAlign.center),
                    ],
                  ]),
                ),

                // WEEKLY STREAK
                ScCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('WEEKLY STREAK 🔥',
                      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800,
                        color: AppColors.muted, letterSpacing: 0.7)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (i) {
                        final s = h.weekStreak[i];
                        Color bg; String inner;
                        if (s == 1)      { bg = AppColors.teal; inner = '✓'; }
                        else if (s == 2) { bg = AppColors.blue; inner = '💧'; }
                        else             { bg = AppColors.border; inner = '–'; }
                        return Column(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                            child: Center(child: Text(inner, style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: s == 2 ? 16 : 14))),
                          ),
                          const SizedBox(height: 4),
                          Text(days[i], style: GoogleFonts.nunito(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w700)),
                        ]);
                      }),
                    ),
                    const SizedBox(height: 12),
                    Center(child: Text('🔥 14-day streak!',
                      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.amber))),
                  ]),
                ),

                // LOG HISTORY
                ScCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TODAY\'S LOG',
                      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800,
                        color: AppColors.muted, letterSpacing: 0.7)),
                    const SizedBox(height: 12),
                    ...['Glass 5 logged · 11:42 AM', 'Glass 4 logged · 10:15 AM',
                        'Glass 3 logged · 9:00 AM',  'Morning glasses (1–2) · 8:10 AM']
                      .asMap().entries.map((e) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: e.key < 3 ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
                        child: Row(children: [
                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(e.value.split(' · ')[0],
                            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.navy, fontWeight: FontWeight.w500))),
                          Text(e.value.split(' · ')[1], style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
                        ]),
                    )),
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
