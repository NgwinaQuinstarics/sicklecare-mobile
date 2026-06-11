import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder.dart';
import '../utils/date_utils.dart';
import '../widgets/section_card.dart';
import '../widgets/empty_state.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final l = context.l10n;
    final titleCtl = TextEditingController();
    final bodyCtl = TextEditingController();
    TimeOfDay time = TimeOfDay.now();
    bool daily = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.newReminder,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                    controller: titleCtl,
                    decoration: InputDecoration(labelText: l.title)),
                const SizedBox(height: 10),
                TextField(
                    controller: bodyCtl,
                    decoration: InputDecoration(labelText: l.note)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Text(l.timeLabel(time.format(ctx)))),
                  TextButton(
                    onPressed: () async {
                      final t =
                          await showTimePicker(context: ctx, initialTime: time);
                      if (t != null) setState(() => time = t);
                    },
                    child: Text(l.pick),
                  ),
                ]),
                SwitchListTile(
                  value: daily,
                  onChanged: (v) => setState(() => daily = v),
                  title: Text(l.repeatDaily),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    if (titleCtl.text.trim().isEmpty) return;
                    final now = DateTime.now();
                    final r = Reminder(
                      id: now.millisecondsSinceEpoch.toString(),
                      title: titleCtl.text.trim(),
                      body: bodyCtl.text.trim(),
                      time: DateTime(
                          now.year, now.month, now.day, time.hour, time.minute),
                      repeatDaily: daily,
                    );
                    await context.read<ReminderProvider>().add(r);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(l.addReminder),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = context.watch<ReminderProvider>().items;
    return Scaffold(
      appBar: AppBar(title: Text(l.remindersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: Text(l.newLabel),
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.notifications_outlined,
              title: l.noReminders,
              subtitle: l.noRemindersSub,
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: items
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SectionCard(
                          child: Row(
                            children: [
                              Icon(Icons.alarm,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        '${fmtTime(r.time)}${r.repeatDaily ? " · ${l.daily}" : ""}'),
                                    if (r.body.isNotEmpty) Text(r.body),
                                  ],
                                ),
                              ),
                              Switch(
                                value: r.enabled,
                                onChanged: (v) => context
                                    .read<ReminderProvider>()
                                    .toggle(r.id, v),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => context
                                    .read<ReminderProvider>()
                                    .remove(r.id),
                              )
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}
