import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/health_tracking.dart';
import '../../providers/care_ui_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';

/// Consolidated UI timeline for mock health, medication and hydration events.
class HealthTimelineScreen extends StatefulWidget {
  const HealthTimelineScreen({super.key});

  @override
  State<HealthTimelineScreen> createState() => _HealthTimelineScreenState();
}

class _HealthTimelineScreenState extends State<HealthTimelineScreen> {
  HealthTimelineEventType? _filter;

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareUiProvider>();
    final events = care.timeline
        .where((event) => _filter == null || event.type == _filter)
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Health timeline')),
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
                  title: 'Timeline preview',
                  message:
                      'This is a local visual history. The app will need an agreed health-data and consent model before connecting events to a clinical record.',
                ),
                const SizedBox(height: 20),
                Text(
                  'Filter events',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _filter == null,
                          onSelected: (_) => setState(() => _filter = null),
                        ),
                      ),
                      for (final type in HealthTimelineEventType.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type.label),
                            selected: _filter == type,
                            onSelected: (selected) => setState(
                                () => _filter = selected ? type : null),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (events.isEmpty)
                  EmptyState(
                    icon: Icons.timeline_outlined,
                    title: 'No ${_filter?.label.toLowerCase() ?? ''} events yet'
                        .trim(),
                    subtitle:
                        'Log hydration, medicines or a crisis preview to build the timeline.',
                  )
                else
                  _Timeline(events: events),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<HealthTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < events.length; index++)
          _TimelineItem(
            event: events[index],
            isLast: index == events.length - 1,
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.event, required this.isLast});

  final HealthTimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visual = _visualFor(event.type, cs);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: visual.$2.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visual.$1, size: 18, color: visual.$2),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: cs.outlineVariant,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SectionCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (event.severity != null)
                          _SeverityChip(severity: event.severity!),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTimestamp(event.occurredAt),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(event.description,
                          style: const TextStyle(height: 1.35)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _visualFor(HealthTimelineEventType type, ColorScheme cs) {
    return switch (type) {
      HealthTimelineEventType.symptom => (
          Icons.healing_outlined,
          Colors.orange.shade800
        ),
      HealthTimelineEventType.crisis => (
          Icons.monitor_heart_outlined,
          cs.error
        ),
      HealthTimelineEventType.medication => (
          Icons.medication_outlined,
          cs.primary
        ),
      HealthTimelineEventType.hydration => (
          Icons.water_drop_outlined,
          Colors.blue.shade700
        ),
      HealthTimelineEventType.appointment => (
          Icons.calendar_month_outlined,
          Colors.green.shade700
        ),
      HealthTimelineEventType.note => (
          Icons.note_alt_outlined,
          cs.onSurfaceVariant
        ),
    };
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.severity});

  final int severity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = severity >= 8
        ? cs.error
        : severity >= 5
            ? Colors.orange.shade800
            : cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$severity / 10',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String _formatTimestamp(DateTime value) {
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
  return '${months[value.month - 1]} ${value.day} · $hour:$minute';
}
