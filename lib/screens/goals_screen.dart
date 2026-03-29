import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/goal_model.dart';
import '../store/app_state.dart';
import '../widgets/sc_card.dart';
import '../widgets/sc_button.dart';
import '../widgets/sc_input.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  static const _catColor = {
    'hydration': AppColors.teal,   'medication': AppColors.blue,
    'exercise':  AppColors.purple, 'sleep': AppColors.amber,
    'nutrition': AppColors.green,
  };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GoalProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Health Goals 🎯', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy)),
                Text('${store.completed} of ${store.all.length} completed',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
              ]),
              GestureDetector(
                onTap: () => _showAddGoal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(12)),
                  child: Text('＋ Add', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              child: Column(children: [

                // WEEKLY HERO
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(22),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.navy, borderRadius: BorderRadius.circular(22)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('WEEKLY COMPLETION', style: GoogleFonts.nunito(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: Colors.white60, letterSpacing: 0.6)),
                    Text('${(store.weeklyPct * 100).round()}%',
                      style: GoogleFonts.nunito(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: store.weeklyPct, minHeight: 8,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF4DFFD4)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Keep it up! Consistency prevents crises.',
                      style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white54)),
                  ]),
                ),

                Text('Active Goals',
                  style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.navy)),
                const SizedBox(height: 12),

                ScCard(
                  child: Column(children: store.all.asMap().entries.map((e) {
                    final goal = e.value;
                    final color = _catColor[goal.category] ?? AppColors.blue;
                    return Column(children: [
                      _GoalRow(goal: goal, color: color),
                      if (e.key < store.all.length - 1)
                        const Divider(color: AppColors.border, height: 20),
                    ]);
                  }).toList()),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _showAddGoal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 36),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('New Health Goal', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy)),
          const SizedBox(height: 18),
          ScInput(label: 'Goal Description', placeholder: 'e.g. Drink 10 glasses/day', controller: titleCtrl),
          ScInput(label: 'Target Value', placeholder: 'e.g. 10', controller: targetCtrl, keyboardType: TextInputType.number),
          ScButton(
            label: 'Create Goal',
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              context.read<GoalProvider>().add(GoalModel(
                id: DateTime.now().millisecondsSinceEpoch,
                title: titleCtrl.text.trim(),
                category: 'hydration',
                targetValue: double.tryParse(targetCtrl.text) ?? 1,
                currentValue: 0, unit: 'times', frequency: 'daily',
              ));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          ScButton(label: 'Cancel', onPressed: () => Navigator.pop(context), variant: BtnVariant.ghost),
        ]),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final GoalModel goal;
  final Color color;
  const _GoalRow({required this.goal, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (goal.percentage * 100).round();
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Text(goal.categoryEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(goal.title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy)),
        ]),
        Text('$pct%', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: goal.percentage, minHeight: 10,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
      const SizedBox(height: 5),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${goal.currentValue.toInt()} / ${goal.targetValue.toInt()} ${goal.unit}',
          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.muted)),
        Text(goal.frequency, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.muted)),
      ]),
    ]);
  }
}
