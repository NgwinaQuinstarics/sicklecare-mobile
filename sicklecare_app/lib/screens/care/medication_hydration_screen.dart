import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/health_tracking.dart';
import '../../providers/care_ui_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';
import 'health_timeline_screen.dart';

/// Medication reminder and hydration UI backed only by the mock care provider.
class MedicationHydrationScreen extends StatelessWidget {
  const MedicationHydrationScreen({super.key});

  Future<void> _configureHydrationReminder(BuildContext context) async {
    final care = context.read<CareUiProvider>();
    final interval = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hydration reminder schedule',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how often this UI preview would remind you. This does not create a device notification.',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final hours in const [1, 2, 3, 4])
                      ChoiceChip(
                        key: Key('hydration-reminder-${hours}h'),
                        label: Text(_hydrationIntervalLabel(hours)),
                        selected: care.hydrationReminderIntervalHours == hours,
                        onSelected: (_) => Navigator.pop(sheetContext, hours),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (interval != null && context.mounted) {
      context
          .read<CareUiProvider>()
          .setHydrationReminderIntervalHours(interval);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hydration reminder set to ${_hydrationIntervalLabel(interval).toLowerCase()} in this preview.',
          ),
        ),
      );
    }
  }

  Future<void> _addMedication(BuildContext context) async {
    final name = TextEditingController();
    final dosage = TextEditingController();
    final schedule = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final medication = await showModalBottomSheet<MedicationPlan>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add medication preview',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'This creates a temporary card only. Follow a clinician’s prescription and care plan.',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Medication name',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a medication name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: dosage,
                  decoration: const InputDecoration(
                    labelText: 'Dose',
                    hintText: 'e.g. 500 mg',
                    prefixIcon: Icon(Icons.scale_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a dose.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: schedule,
                  decoration: const InputDecoration(
                    labelText: 'Schedule',
                    hintText: 'e.g. Every morning',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a schedule.'
                      : null,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    Navigator.pop(
                      sheetContext,
                      MedicationPlan(
                        id: 'preview-medication-${DateTime.now().millisecondsSinceEpoch}',
                        name: name.text.trim(),
                        dosage: dosage.text.trim(),
                        scheduleLabel: schedule.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Add medication'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    name.dispose();
    dosage.dispose();
    schedule.dispose();
    if (medication != null && context.mounted) {
      final didSave = context.read<CareUiProvider>().addMedication(medication);
      if (didSave) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication added to this UI preview.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareUiProvider>();
    final progress = care.hydrationProgress.clamp(0.0, 1.0).toDouble();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicines & hydration'),
        actions: [
          IconButton(
            tooltip: 'Add medication',
            onPressed: () => _addMedication(context),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                StatusBanner(
                  tone: StatusBannerTone.info,
                  title: 'Reminder preview',
                  message:
                      'Medication cards and completion actions are mock UI only. They do not replace prescriptions or send notifications from this new flow.',
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.water_drop_outlined,
                                color: cs.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today’s hydration',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${care.hydrationTodayMl} ml of ${care.hydrationGoalMl} ml goal',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final amount in const [250, 400, 500])
                            OutlinedButton.icon(
                              onPressed: () {
                                final didLog = care.logHydration(amount);
                                if (didLog) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '$amount ml added to the preview.'),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: Text('$amount ml'),
                            ),
                        ],
                      ),
                      const Divider(height: 28),
                      SwitchListTile.adaptive(
                        key: const Key('hydration-reminder-switch'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hydration reminder'),
                        subtitle: Text(
                          care.hydrationReminderEnabled
                              ? '${_hydrationIntervalLabel(care.hydrationReminderIntervalHours)} in this UI preview'
                              : 'Paused for this UI preview session',
                        ),
                        value: care.hydrationReminderEnabled,
                        onChanged: care.setHydrationReminderEnabled,
                      ),
                      if (care.hydrationReminderEnabled)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            key: const Key('hydration-reminder-interval'),
                            onPressed: () =>
                                _configureHydrationReminder(context),
                            icon: const Icon(Icons.schedule_outlined),
                            label: const Text('Change interval'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Medication plan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addMedication(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (care.activeMedications.isEmpty)
                  const EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'No medications in this preview',
                    subtitle:
                        'Add a temporary medication card to review this interaction.',
                  )
                else
                  for (final medication in care.activeMedications) ...[
                    _MedicationCard(medication: medication),
                    const SizedBox(height: 10),
                  ],
                if (care.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  StatusBanner(
                    tone: StatusBannerTone.error,
                    title: 'Could not update preview',
                    message: care.errorMessage,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _hydrationIntervalLabel(int hours) {
  return hours == 1 ? 'Every hour' : 'Every $hours hours';
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.medication});

  final MedicationPlan medication;

  @override
  Widget build(BuildContext context) {
    final care = context.read<CareUiProvider>();
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.medication_outlined, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${medication.dosage} · ${medication.scheduleLabel}',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove medication preview',
                onPressed: () => care.removeMedication(medication.id),
                icon: const Icon(Icons.close_outlined),
              ),
            ],
          ),
          if (medication.instructions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              medication.instructions,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
            ),
          ],
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reminder preview'),
            subtitle: Text(
              medication.reminderEnabled
                  ? 'Shown as enabled for this session'
                  : 'Shown as paused for this session',
            ),
            value: medication.reminderEnabled,
            onChanged: (_) => care.toggleMedicationReminder(medication.id),
          ),
          const SizedBox(height: 8),
          Text(
            'Dose status',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in MedicationDoseStatus.values)
                _DoseStatusButton(
                  key: Key('medication-dose-${medication.id}-${status.name}'),
                  status: status,
                  onPressed: () {
                    care.recordMedicationDose(medication.id, status);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('${status.label} recorded in this preview.'),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            key: Key('medication-history-${medication.id}'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const HealthTimelineScreen(
                  initialFilter: HealthTimelineEventType.medication,
                ),
              ),
            ),
            icon: const Icon(Icons.history_outlined),
            label: const Text('View history'),
          ),
        ],
      ),
    );
  }
}

class _DoseStatusButton extends StatelessWidget {
  const _DoseStatusButton({
    super.key,
    required this.status,
    required this.onPressed,
  });

  final MedicationDoseStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      MedicationDoseStatus.taken => Icons.check_circle_outline,
      MedicationDoseStatus.skipped => Icons.redo_outlined,
      MedicationDoseStatus.missed => Icons.schedule_outlined,
    };

    if (status == MedicationDoseStatus.taken) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(status.label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(status.label),
    );
  }
}
