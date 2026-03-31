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
  final _timeCtrl = TextEditingController(text: '08:00');
  String _type = 'medication';

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

          context.read<ReminderProvider>().add(
                ReminderModel(
                  id: DateTime.now().millisecondsSinceEpoch,
                  title: _titleCtrl.text.trim(),
                  type: _type,
                  time: _timeCtrl.text,
                  frequency: 'daily',
                ),
              );

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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        onPressed: _showAddSheet,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminders',
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        'Long press to delete',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // LIST
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (store.morning.isNotEmpty) ...[
                    _section('Morning'),
                    ...store.morning.map((r) => _tile(r)),
                  ],
                  if (store.afternoon.isNotEmpty) ...[
                    _section('Afternoon'),
                    ...store.afternoon.map((r) => _tile(r)),
                  ],
                  if (store.evening.isNotEmpty) ...[
                    _section('Evening'),
                    ...store.evening.map((r) => _tile(r)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _tile(ReminderModel r) {
    IconData icon;

    switch (r.type) {
      case 'medication':
        icon = Icons.medication;
        break;
      case 'hydration':
        icon = Icons.water_drop;
        break;
      case 'food':
        icon = Icons.restaurant;
        break;
      case 'exercise':
        icon = Icons.fitness_center;
        break;
      default:
        icon = Icons.notifications;
    }

    return GestureDetector(
      onLongPress: () {
        context.read<ReminderProvider>().remove(r.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withAlpha(30), // FIXED (no withOpacity)
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.blueLight,
              child: Icon(icon, color: AppColors.blue),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${r.time} • ${r.frequency}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),

            // FIXED SWITCH
            Switch(
              value: r.isActive,
              activeThumbColor: AppColors.blue,
              onChanged: (v) {
                context.read<ReminderProvider>().toggle(r.id, v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  final TextEditingController titleCtrl;
  final TextEditingController timeCtrl;
  final String type;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onSave;

  const _AddReminderSheet({
    required this.titleCtrl,
    required this.timeCtrl,
    required this.type,
    required this.onTypeChanged,
    required this.onSave,
  });

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final types = ['medication', 'hydration', 'food', 'exercise'];
  late String selected;

  @override
  void initState() {
    super.initState();
    selected = widget.type;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add Reminder',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ScInput(
            label: 'Title',
            placeholder: 'Enter reminder',
            controller: widget.titleCtrl,
          ),

          const SizedBox(height: 10),

          ScInput(
            label: 'Time',
            placeholder: '08:00',
            controller: widget.timeCtrl,
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            children: types.map((t) {
              return ChoiceChip(
                label: Text(t),
                selected: selected == t,
                onSelected: (_) {
                  setState(() => selected = t);
                  widget.onTypeChanged(t);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          ScButton(label: 'Save', onPressed: widget.onSave),
          ScButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
            variant: BtnVariant.ghost,
          ),
        ],
      ),
    );
  }
}