import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/health_tracking.dart';
import '../../providers/care_ui_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';
import 'emergency_information_screen.dart';

/// A non-diagnostic pain-crisis journal that stores entries in memory only.
class CrisisTrackingScreen extends StatelessWidget {
  const CrisisTrackingScreen({super.key});

  Future<void> _logCrisis(BuildContext context) async {
    final crisis = await showModalBottomSheet<PainCrisis>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CrisisFormSheet(),
    );
    if (crisis == null || !context.mounted) return;
    final didSave = context.read<CareUiProvider>().addPainCrisis(crisis);
    if (didSave && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pain crisis logged in this UI preview.')),
      );
    }
  }

  Future<void> _logSymptoms(BuildContext context) async {
    final event = await showModalBottomSheet<HealthTimelineEvent>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SymptomFormSheet(),
    );
    if (event == null || !context.mounted) return;
    context.read<CareUiProvider>().addTimelineEvent(event);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptoms logged in this UI preview.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareUiProvider>();
    final crises = care.painCrises;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pain crisis tracker'),
        actions: [
          IconButton(
            tooltip: 'Log pain crisis',
            onPressed: () => _logCrisis(context),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logCrisis(context),
        icon: const Icon(Icons.add),
        label: const Text('Log crisis'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              key: const Key('crisis-tracker-list'),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                StatusBanner(
                  tone: StatusBannerTone.warning,
                  title: 'This is not an emergency assessment',
                  message:
                      'For severe pain, chest pain, breathing trouble, fever, weakness, or confusion, seek urgent medical care or call 112.',
                ),
                const SizedBox(height: 16),
                StatusBanner(
                  tone: StatusBannerTone.info,
                  title: 'Private UI preview',
                  message:
                      'Crisis logs in this screen are temporary mock entries and are not shared with a clinician.',
                ),
                const SizedBox(height: 14),
                SectionCard(
                  padding: const EdgeInsets.all(14),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.healing_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Track symptoms separately',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Record everyday changes without starting a pain-crisis entry.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _logSymptoms(context),
                          icon: const Icon(Icons.add_chart_outlined),
                          label: const Text('Log symptoms'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Recent crisis entries',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                if (crises.isEmpty)
                  const EmptyState(
                    icon: Icons.monitor_heart_outlined,
                    title: 'No crisis entries yet',
                    subtitle:
                        'Log a preview entry to see how the care journal will look.',
                  )
                else
                  for (final crisis in crises) ...[
                    _CrisisCard(crisis: crisis),
                    const SizedBox(height: 10),
                  ],
                if (care.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  StatusBanner(
                    tone: StatusBannerTone.error,
                    title: 'Crisis entry not saved',
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

class _CrisisCard extends StatelessWidget {
  const _CrisisCard({required this.crisis});

  final PainCrisis crisis;

  @override
  Widget build(BuildContext context) {
    final care = context.read<CareUiProvider>();
    final cs = Theme.of(context).colorScheme;
    final intensityColor = _intensityColor(cs, crisis.intensity);
    final started = _formatDateTime(crisis.startedAt);
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
                  color: intensityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(Icons.monitor_heart_outlined, color: intensityColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crisis.isOngoing ? 'Ongoing pain crisis' : 'Pain crisis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(started, style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              _IntensityPill(
                  intensity: crisis.intensity, color: intensityColor),
            ],
          ),
          const SizedBox(height: 12),
          if (crisis.symptoms.isNotEmpty)
            _CrisisRow(label: 'Symptoms', value: crisis.symptoms.join(' · ')),
          if (crisis.affectedAreas.isNotEmpty)
            _CrisisRow(label: 'Areas', value: crisis.affectedAreas.join(' · ')),
          if (crisis.actionTaken.isNotEmpty)
            _CrisisRow(label: 'Care action', value: crisis.actionTaken),
          if (crisis.notes.isNotEmpty)
            _CrisisRow(label: 'Notes', value: crisis.notes),
          if (crisis.requiresMedicalAttention) ...[
            const SizedBox(height: 8),
            StatusBanner(
              tone: StatusBannerTone.warning,
              title: 'Medical attention flagged',
              message:
                  'This marker is only a journal entry; seek professional care if symptoms are serious or worsening.',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EmergencyInformationScreen(),
                  ),
                ),
                icon: const Icon(Icons.emergency_outlined),
                label: const Text(
                  'View emergency information',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          if (crisis.isOngoing) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                care.endPainCrisis(crisis.id, DateTime.now());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Crisis marked as ended in preview.')),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as ended'),
            ),
          ],
        ],
      ),
    );
  }

  Color _intensityColor(ColorScheme cs, int intensity) {
    if (intensity >= 8) return cs.error;
    if (intensity >= 5) return Colors.orange.shade800;
    return cs.primary;
  }
}

class _CrisisRow extends StatelessWidget {
  const _CrisisRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _IntensityPill extends StatelessWidget {
  const _IntensityPill({required this.intensity, required this.color});

  final int intensity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$intensity / 10',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _CrisisFormSheet extends StatefulWidget {
  const _CrisisFormSheet();

  @override
  State<_CrisisFormSheet> createState() => _CrisisFormSheetState();
}

class _CrisisFormSheetState extends State<_CrisisFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _symptoms = TextEditingController();
  final _areas = TextEditingController();
  final _notes = TextEditingController();
  final _action = TextEditingController();
  double _intensity = 5;
  bool _needsAttention = false;

  @override
  void dispose() {
    _symptoms.dispose();
    _areas.dispose();
    _notes.dispose();
    _action.dispose();
    super.dispose();
  }

  List<String> _split(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final symptoms = _split(_symptoms.text);
    final areas = _split(_areas.text);
    if (symptoms.isEmpty && areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one symptom or affected area.')),
      );
      return;
    }
    Navigator.pop(
      context,
      PainCrisis(
        id: 'preview-crisis-${DateTime.now().millisecondsSinceEpoch}',
        startedAt: DateTime.now(),
        intensity: _intensity.round(),
        symptoms: symptoms,
        affectedAreas: areas,
        notes: _notes.text.trim(),
        actionTaken: _action.text.trim(),
        requiresMedicalAttention: _needsAttention,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log pain crisis',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Use this as a self-management journal, not a medical diagnosis.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Text(
                'Pain intensity: ${_intensity.round()} / 10',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _intensity,
                min: 0,
                max: 10,
                divisions: 10,
                label: _intensity.round().toString(),
                onChanged: (value) => setState(() => _intensity = value),
              ),
              TextFormField(
                controller: _symptoms,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Symptoms',
                  hintText: 'e.g. fatigue, joint pain',
                  prefixIcon: Icon(Icons.healing_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areas,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Affected areas',
                  hintText: 'e.g. lower back, knees',
                  prefixIcon: Icon(Icons.accessibility_new_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _action,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Care action taken (optional)',
                  prefixIcon: Icon(Icons.self_improvement_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('I need medical attention'),
                subtitle: const Text(
                    'This adds a safety flag to the local preview entry.'),
                value: _needsAttention,
                onChanged: (value) => setState(() => _needsAttention = value),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save crisis preview'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymptomFormSheet extends StatefulWidget {
  const _SymptomFormSheet();

  @override
  State<_SymptomFormSheet> createState() => _SymptomFormSheetState();
}

class _SymptomFormSheetState extends State<_SymptomFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _symptoms = TextEditingController();
  final _notes = TextEditingController();
  double _severity = 4;

  @override
  void dispose() {
    _symptoms.dispose();
    _notes.dispose();
    super.dispose();
  }

  List<String> _splitSymptoms(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  String? _validateSymptoms(String? value) {
    if (_splitSymptoms(value ?? '').isEmpty) {
      return 'Add at least one symptom to continue.';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final symptoms = _splitSymptoms(_symptoms.text);
    final notes = _notes.text.trim();
    Navigator.pop(
      context,
      HealthTimelineEvent(
        id: 'symptom-${DateTime.now().millisecondsSinceEpoch}',
        occurredAt: DateTime.now(),
        type: HealthTimelineEventType.symptom,
        title: 'Symptom check-in',
        description: [
          symptoms.join(' · '),
          if (notes.isNotEmpty) 'Notes: $notes',
        ].join('\n'),
        severity: _severity.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          key: const Key('symptom-check-in-form'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log symptoms',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'This is a self-management note, not a diagnosis or an emergency assessment.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                key: const Key('symptom-input'),
                controller: _symptoms,
                validator: _validateSymptoms,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Symptoms',
                  hintText: 'e.g. fatigue, joint pain',
                  helperText: 'Separate more than one symptom with commas.',
                  prefixIcon: Icon(Icons.healing_outlined),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'How intense does it feel? ${_severity.round()} / 10',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Semantics(
                label: 'Symptom intensity',
                value: '${_severity.round()} out of 10',
                child: Slider(
                  value: _severity,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: _severity.round().toString(),
                  semanticFormatterCallback: (value) =>
                      '${value.round()} out of 10',
                  onChanged: (value) => setState(() => _severity = value),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('symptom-notes-input'),
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Anything else you want to remember?',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('save-symptoms-button'),
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save symptom check-in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${months[value.month - 1]} ${value.day}, ${value.year} · $hour:$minute';
}
