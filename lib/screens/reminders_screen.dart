import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/reminder_model.dart';
import '../store/app_state.dart';
import '../widgets/sc_button.dart';
import '../widgets/sc_input.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _titleCtrl = TextEditingController();
  final _timeCtrl  = TextEditingController(text: '08:00');
  String _type     = 'medication';

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReminderSheet(
        titleCtrl: _titleCtrl,
        timeCtrl: _timeCtrl,
        type: _type,
        onTypeChanged: (t) => setState(() => _type = t),
        onSave: () {
          if (_titleCtrl.text.trim().isEmpty) return;
          final store = context.read<ReminderProvider>();
          store.add(ReminderModel(
            id: DateTime.now().millisecondsSinceEpoch,
            title: _titleCtrl.text.trim(),
            type: _type,
            time: _timeCtrl.text,
            frequency: 'daily',
          ));
          _titleCtrl.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ReminderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Reminders', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy)),
                Text('Long-press to delete', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
              ]),
              GestureDetector(
                onTap: _showAddSheet,
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // AI suggestion
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(16),
                    border: const Border(left: BorderSide(color: AppColors.blue, width: 3)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('🤖', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('You often miss your 9 PM medication. Want a stronger alert?',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.navyMid, height: 1.4)),
                      const SizedBox(height: 8),
                      Text('Enable stronger notification →',
                        style: GoogleFonts.nunito(fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.w700)),
                    ])),
                  ]),
                ),

                if (store.morning.isNotEmpty) ...[
                  _SectionLabel('Morning'),
                  ...store.morning.map((r) => _ReminderTile(r: r)),
                ],
                if (store.afternoon.isNotEmpty) ...[
                  _SectionLabel('Afternoon'),
                  ...store.afternoon.map((r) => _ReminderTile(r: r)),
                ],
                if (store.evening.isNotEmpty) ...[
                  _SectionLabel('Evening'),
                  ...store.evening.map((r) => _ReminderTile(r: r)),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text.toUpperCase(),
      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800,
        color: AppColors.muted, letterSpacing: 0.8)),
  );
}

class _ReminderTile extends StatelessWidget {
  final ReminderModel r;
  const _ReminderTile({required this.r});

  static const _typeBg = {
    'medication': AppColors.blueLight, 'hydration': AppColors.tealLight,
    'food': AppColors.amberLight,      'exercise': AppColors.greenLight,
    'other': AppColors.purpleLight,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete reminder?', style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
            content: Text('Remove "${r.title}"?', style: GoogleFonts.dmSans()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  context.read<ReminderProvider>().remove(r.id);
                  Navigator.pop(context);
                },
                child: Text('Delete', style: TextStyle(color: AppColors.rose)),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.blue, blurRadius: 8, offset: const Offset(0,3))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _typeBg[r.type] ?? AppColors.blueLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(r.typeEmoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy)),
            Text('${r.time} · ${r.frequency}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
          ])),
          Switch(
            value: r.isActive,
            activeColor: AppColors.teal,
            onChanged: (v) => context.read<ReminderProvider>().toggle(r.id, v),
          ),
        ]),
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  final TextEditingController titleCtrl, timeCtrl;
  final String type;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onSave;

  const _AddReminderSheet({
    required this.titleCtrl, required this.timeCtrl,
    required this.type, required this.onTypeChanged, required this.onSave,
  });

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _types = [
    {'key': 'medication', 'emoji': '💊', 'label': 'Medication'},
    {'key': 'hydration',  'emoji': '💧', 'label': 'Hydration'},
    {'key': 'food',       'emoji': '🥗', 'label': 'Food'},
    {'key': 'exercise',   'emoji': '🏃', 'label': 'Exercise'},
  ];

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.type;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 36),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('Add Reminder', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy)),
        const SizedBox(height: 18),
        ScInput(label: 'Reminder Name', placeholder: 'e.g. Hydroxyurea 500mg', controller: widget.titleCtrl),
        Text('Type', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navyMid)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: _types.map((t) {
          final active = _selected == t['key'];
          return GestureDetector(
            onTap: () { setState(() => _selected = t['key']!); widget.onTypeChanged(t['key']!); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppColors.blue : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppColors.blue : AppColors.border, width: 2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(t['emoji']!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 5),
                Text(t['label']!, style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.muted)),
              ]),
            ),
          );
        }).toList()),
        const SizedBox(height: 16),
        ScInput(label: 'Time (HH:MM)', placeholder: '08:00', controller: widget.timeCtrl, keyboardType: TextInputType.datetime),
        ScButton(label: 'Save Reminder', onPressed: widget.onSave),
        const SizedBox(height: 8),
        ScButton(label: 'Cancel', onPressed: () => Navigator.pop(context), variant: BtnVariant.ghost),
      ]),
    );
  }
}
