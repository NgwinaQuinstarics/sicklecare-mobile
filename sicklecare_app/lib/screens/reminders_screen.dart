import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
import '../services/alarm_service.dart';
import '../utils/date_utils.dart';
import '../widgets/section_card.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _openReminderSheet(
    BuildContext context, {
    Reminder? reminder,
  }) async {
    final l = context.l10n;
    final provider = context.read<ReminderProvider>();
    final isEditing = reminder != null;
    final titleCtl = TextEditingController(text: reminder?.title ?? '');
    final bodyCtl = TextEditingController(text: reminder?.body ?? '');
    TimeOfDay time = reminder == null
        ? TimeOfDay.now()
        : TimeOfDay.fromDateTime(reminder.time);
    bool daily = reminder?.repeatDaily ?? true;

    try {
      final result = await showModalBottomSheet<Reminder>(
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
                  Text(
                    isEditing
                        ? l.tr('Edit alarm', "Modifier l'alarme")
                        : l.newReminder,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
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
                        final t = await showTimePicker(
                            context: ctx, initialTime: time);
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
                    onPressed: () {
                      final title = titleCtl.text.trim();
                      if (title.isEmpty) return;

                      final now = DateTime.now();
                      final r = Reminder(
                        id: reminder?.id ??
                            now.microsecondsSinceEpoch.toString(),
                        title: title,
                        body: bodyCtl.text.trim(),
                        time: DateTime(now.year, now.month, now.day, time.hour,
                            time.minute),
                        repeatDaily: daily,
                        enabled: reminder?.enabled ?? true,
                      );

                      Navigator.of(ctx).pop(r);
                    },
                    child: Text(isEditing
                        ? l.tr('Save alarm', "Enregistrer l'alarme")
                        : l.addReminder),
                  ),
                ],
              ),
            );
          });
        },
      );
      if (result == null) return;
      if (isEditing) {
        await provider.update(result);
      } else {
        await provider.add(result);
      }
    } finally {
      titleCtl.dispose();
      bodyCtl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reminderProvider = context.watch<ReminderProvider>();
    final items = reminderProvider.items;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.remindersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReminderSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l.newLabel),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
        children: [
          _HydrationReminderCard(provider: reminderProvider),
          const SizedBox(height: 18),
          _ReminderHealthCard(
            customAlarmCount: items.where((r) => r.enabled).length,
            hydrationEnabled: reminderProvider.hydrationReminderEnabled,
          ),
          const SizedBox(height: 18),
          _ReminderAuditCard(provider: reminderProvider),
          const SizedBox(height: 18),
          Text(
            l.tr('Custom alarms', 'Alarmes personnalisées'),
            style: tt.titleMedium,
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notifications_outlined, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.noReminders,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(l.noRemindersSub,
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...items.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    child: Row(
                      children: [
                        Icon(Icons.alarm, color: cs.primary),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: r.enabled,
                              onChanged: (v) => context
                                  .read<ReminderProvider>()
                                  .toggle(r.id, v),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: l.tr('Edit alarm', "Modifier l'alarme"),
                              onPressed: () =>
                                  _openReminderSheet(context, reminder: r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip:
                                  l.tr('Delete alarm', "Supprimer l'alarme"),
                              onPressed: () =>
                                  context.read<ReminderProvider>().remove(r.id),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _ReminderAuditCard extends StatelessWidget {
  final ReminderProvider provider;
  const _ReminderAuditCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final logs = provider.auditLog.take(4).toList();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.tr('Reminder audit', 'Audit des rappels'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.read<ReminderProvider>().repairSchedules(),
                icon: const Icon(Icons.build_circle_outlined),
                label: Text(l.tr('Repair', 'Réparer')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.tr(
              'If Android delays alarms, repair schedules and allow alarms in phone settings.',
              'Si Android retarde les alarmes, répare les programmes et autorise les alarmes.',
            ),
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Text(
              l.tr('No alarm activity yet.', 'Aucune activité pour le moment.'),
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ...logs.map((entry) {
              final parts = entry.split('|');
              final message =
                  parts.length > 1 ? parts.sublist(1).join('|') : entry;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(message)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ReminderHealthCard extends StatefulWidget {
  final int customAlarmCount;
  final bool hydrationEnabled;

  const _ReminderHealthCard({
    required this.customAlarmCount,
    required this.hydrationEnabled,
  });

  @override
  State<_ReminderHealthCard> createState() => _ReminderHealthCardState();
}

class _ReminderHealthCardState extends State<_ReminderHealthCard> {
  late Future<AlarmHealthStatus> _future =
      AlarmService.instance.getHealthStatus();

  @override
  void didUpdateWidget(covariant _ReminderHealthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customAlarmCount != widget.customAlarmCount ||
        oldWidget.hydrationEnabled != widget.hydrationEnabled) {
      _refresh();
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = AlarmService.instance.getHealthStatus();
    });
  }

  Future<void> _requestPermissions() async {
    await AlarmService.instance.requestAlarmPermissions();
    _refresh();
  }

  void _showBatteryGuide() {
    final l = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tr('Battery protection', 'Protection batterie')),
        content: Text(l.tr(
          'For the most reliable alarms, open your phone Battery settings for SickleCare and choose Unrestricted / Do not optimize. Also keep notifications and exact alarms allowed.',
          'Pour des alarmes plus fiables, ouvre les réglages Batterie de SickleCare et choisis Non restreint / Ne pas optimiser. Garde aussi les notifications et alarmes exactes autorisées.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.tr('Got it', 'Compris')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<AlarmHealthStatus>(
      future: _future,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final healthy = status?.healthy ?? false;
        final tone = healthy ? Colors.green : cs.primary;

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    healthy
                        ? Icons.verified_outlined
                        : Icons.health_and_safety_outlined,
                    color: tone,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.tr('Reminder health', 'Santé des rappels'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: l.retry,
                    onPressed: loading ? null : _refresh,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _healthSummary(l, status, loading),
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.battery_alert_outlined,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.tr(
                        'If alarms are late, disable battery optimization for SickleCare.',
                        'Si les alarmes sont en retard, désactive l’optimisation batterie pour SickleCare.',
                      ),
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _requestPermissions,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(l.tr('Fix permissions', 'Corriger')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        AlarmService.instance.openNotificationSettings(),
                    icon: const Icon(Icons.tune_outlined),
                    label: Text(l.tr('Notifications', 'Notifications')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => AlarmService.instance.openAlarmSettings(),
                    icon: const Icon(Icons.alarm_on_outlined),
                    label: Text(l.tr('Alarm access', 'Accès alarmes')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showBatteryGuide,
                    icon: const Icon(Icons.battery_saver_outlined),
                    label: Text(l.tr('Battery', 'Batterie')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _healthSummary(L10n l, AlarmHealthStatus? status, bool loading) {
    if (loading || status == null) {
      return l.tr(
          'Checking scheduled alarms...', 'Vérification des alarmes...');
    }
    if (!status.notificationsAllowed) {
      return l.tr(
        'Notifications are blocked. Alarms cannot ring until they are allowed.',
        'Les notifications sont bloquées. Les alarmes ne peuvent pas sonner.',
      );
    }
    if (!status.allRequiredPermissionsGranted) {
      return l.tr(
        'Exact alarm or full-screen permission needs attention.',
        "L'autorisation alarme exacte ou plein écran doit être corrigée.",
      );
    }
    return l.tr(
      '${status.scheduledCustomAlarms} custom and ${status.scheduledHydrationAlarms} hydration alarms scheduled.',
      '${status.scheduledCustomAlarms} alarmes personnalisées et ${status.scheduledHydrationAlarms} rappels d’eau programmés.',
    );
  }
}

class _HydrationReminderCard extends StatelessWidget {
  final ReminderProvider provider;
  const _HydrationReminderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final enabled = provider.hydrationReminderEnabled;
    final selected = provider.hydrationIntervalMinutes ?? 60;
    final startTime = provider.hydrationStartTime;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.water_drop_outlined, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        l.tr('Automatic water reminder',
                            "Rappel d'eau automatique"),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      l.tr(
                        'SickleCare will remind you to drink water at the interval you choose.',
                        "SickleCare te rappelle de boire de l'eau selon l'intervalle choisi.",
                      ),
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (v) => context
                    .read<ReminderProvider>()
                    .setHydrationInterval(v ? selected : null),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.tr(
                    'First reminder: ${startTime.format(context)}',
                    'Premier rappel : ${startTime.format(context)}',
                  ),
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (picked != null && context.mounted) {
                    await context
                        .read<ReminderProvider>()
                        .setHydrationStartTime(picked);
                  }
                },
                icon: const Icon(Icons.schedule),
                label: Text(l.pick),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _intervalChip(context, 30, selected, enabled),
              _intervalChip(context, 60, selected, enabled),
              _intervalChip(context, 120, selected, enabled),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.tr(
                      'Active: ${_label(l, selected)}.',
                      'Actif : ${_label(l, selected)}.',
                    ),
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _intervalChip(
    BuildContext context,
    int minutes,
    int selected,
    bool enabled,
  ) {
    final l = context.l10n;
    return ChoiceChip(
      label: Text(_label(l, minutes)),
      selected: selected == minutes,
      onSelected: (v) {
        if (v) {
          context.read<ReminderProvider>().setHydrationInterval(minutes);
        }
      },
    );
  }

  String _label(L10n l, int minutes) {
    switch (minutes) {
      case 30:
        return l.tr('Every 30 min', 'Chaque 30 min');
      case 60:
        return l.tr('Every 1 hour', 'Chaque 1 h');
      case 120:
        return l.tr('Every 2 hours', 'Chaque 2 h');
      default:
        return l.tr('Every $minutes min', 'Chaque $minutes min');
    }
  }
}
