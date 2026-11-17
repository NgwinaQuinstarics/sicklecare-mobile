import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

/// A presentation-only schedule for the clinician workspace.
///
/// It deliberately uses fictitious session labels rather than patient data.
/// A scheduling repository can replace [_previewSessions] after the appointment
/// and privacy contracts are agreed, without changing this UI flow.
class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  static const _days = <_ScheduleDay>[
    _ScheduleDay(label: 'Mon', date: '12'),
    _ScheduleDay(label: 'Tue', date: '13'),
    _ScheduleDay(label: 'Wed', date: '14'),
    _ScheduleDay(label: 'Thu', date: '15'),
    _ScheduleDay(label: 'Fri', date: '16'),
  ];

  static const _previewSessions = <_PreviewSession>[
    _PreviewSession(
      id: 'session-1',
      dayIndex: 0,
      time: '09:00',
      title: 'New consultation',
      duration: '30 min',
      detail: 'Initial sickle-cell care discussion',
      status: _SessionStatus.confirmed,
    ),
    _PreviewSession(
      id: 'session-2',
      dayIndex: 0,
      time: '11:30',
      title: 'Care-plan follow-up',
      duration: '20 min',
      detail: 'Review support plan and next steps',
      status: _SessionStatus.needsReview,
    ),
    _PreviewSession(
      id: 'session-3',
      dayIndex: 0,
      time: '15:00',
      title: 'Clinical review',
      duration: '30 min',
      detail: 'Routine clinician review',
      status: _SessionStatus.confirmed,
    ),
    _PreviewSession(
      id: 'session-4',
      dayIndex: 1,
      time: '10:15',
      title: 'Medication check-in',
      duration: '15 min',
      detail: 'Medication reminder discussion',
      status: _SessionStatus.confirmed,
    ),
    _PreviewSession(
      id: 'session-5',
      dayIndex: 1,
      time: '14:00',
      title: 'Care coordination',
      duration: '25 min',
      detail: 'Coordinate a facility referral',
      status: _SessionStatus.needsReview,
    ),
    _PreviewSession(
      id: 'session-6',
      dayIndex: 2,
      time: '09:30',
      title: 'Care-plan follow-up',
      duration: '20 min',
      detail: 'Review goals and support needs',
      status: _SessionStatus.confirmed,
    ),
    _PreviewSession(
      id: 'session-7',
      dayIndex: 2,
      time: '13:45',
      title: 'Clinical review',
      duration: '30 min',
      detail: 'Review recent self-management notes',
      status: _SessionStatus.confirmed,
    ),
    _PreviewSession(
      id: 'session-8',
      dayIndex: 4,
      time: '10:00',
      title: 'Follow-up consultation',
      duration: '20 min',
      detail: 'Planned check-in',
      status: _SessionStatus.confirmed,
    ),
  ];

  var _selectedDay = 0;
  var _filter = _ScheduleFilter.all;
  final _completedSessionIds = <String>{};

  List<_PreviewSession> get _sessionsForDay {
    return _previewSessions.where((session) {
      if (session.dayIndex != _selectedDay) return false;
      return switch (_filter) {
        _ScheduleFilter.all => true,
        _ScheduleFilter.scheduled => session.status == _SessionStatus.confirmed,
        _ScheduleFilter.needsReview =>
          session.status == _SessionStatus.needsReview,
      };
    }).toList();
  }

  int get _daySessionCount => _previewSessions
      .where((session) => session.dayIndex == _selectedDay)
      .length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final sessions = _sessionsForDay;
    final day = _days[_selectedDay];

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: ListView(
              key: const Key('doctor-schedule-list'),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
              children: [
                Text(
                  'Your clinical schedule',
                  style:
                      tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review the preview sessions planned for this workweek.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                _PreviewNotice(color: cs.primary),
                const SizedBox(height: 18),
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final selected = index == _selectedDay;
                      final item = _days[index];
                      return Semantics(
                        selected: selected,
                        button: true,
                        label: '${item.label} ${item.date}',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _selectedDay = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 60,
                            decoration: BoxDecoration(
                              color: selected
                                  ? cs.primary
                                  : cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: selected
                                        ? cs.onPrimary
                                        : cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.date,
                                  style: tt.titleMedium?.copyWith(
                                    color:
                                        selected ? cs.onPrimary : cs.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final filter in _ScheduleFilter.values)
                      ChoiceChip(
                        label: Text(filter.label),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${day.label} ${day.date}',
                            style: tt.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _daySessionCount == 0
                                ? 'No sessions are planned'
                                : '$_daySessionCount sessions planned',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.calendar_today_outlined,
                        color: cs.onSurfaceVariant, size: 22),
                  ],
                ),
                const SizedBox(height: 12),
                if (sessions.isEmpty)
                  _ScheduleEmptyState(
                    hasFilteredSessions: _daySessionCount > 0,
                    onClearFilter: () =>
                        setState(() => _filter = _ScheduleFilter.all),
                  )
                else
                  ...sessions.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionCard(
                        session: session,
                        isComplete: _completedSessionIds.contains(session.id),
                        onTap: () => _showSessionDetails(session),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSessionDetails(_PreviewSession session) async {
    final isComplete = _completedSessionIds.contains(session.id);
    final shouldComplete = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SessionDetailsSheet(
        session: session,
        isComplete: isComplete,
      ),
    );
    if (!mounted || shouldComplete != true || isComplete) return;
    setState(() => _completedSessionIds.add(session.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session marked complete for this UI preview.'),
      ),
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Schedule data is a local UI preview. It does not contain patient data or send appointment updates.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState({
    required this.hasFilteredSessions,
    required this.onClearFilter,
  });

  final bool hasFilteredSessions;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          EmptyState(
            icon: hasFilteredSessions
                ? Icons.filter_alt_off_outlined
                : Icons.event_available_outlined,
            title: hasFilteredSessions
                ? 'No sessions match this filter'
                : 'No sessions on this day',
            subtitle: hasFilteredSessions
                ? 'Try another filter to view the remaining sessions.'
                : 'Use the open time for care-plan reviews or preparation.',
          ),
          if (hasFilteredSessions)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: OutlinedButton.icon(
                onPressed: onClearFilter,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Show all sessions'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isComplete,
    required this.onTap,
  });

  final _PreviewSession session;
  final bool isComplete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = isComplete ? _SessionStatus.completed : session.status;
    final presentation = _StatusPresentation.of(context, status);
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
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
                  color: presentation.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(presentation.icon, color: presentation.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SessionMeta(
                icon: Icons.schedule_outlined,
                label: '${session.time} · ${session.duration}',
              ),
              _SessionStatusPill(presentation: presentation),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionMeta extends StatelessWidget {
  const _SessionMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 5,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(icon, size: 17, color: cs.onSurfaceVariant),
        Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _SessionStatusPill extends StatelessWidget {
  const _SessionStatusPill({required this.presentation});

  final _StatusPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: presentation.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(presentation.icon, size: 15, color: presentation.color),
          Text(
            presentation.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: presentation.color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SessionDetailsSheet extends StatelessWidget {
  const _SessionDetailsSheet({
    required this.session,
    required this.isComplete,
  });

  final _PreviewSession session;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final presentation = _StatusPresentation.of(
      context,
      isComplete ? _SessionStatus.completed : session.status,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              session.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(session.detail, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 18),
            _DetailsRow(
              icon: Icons.schedule_outlined,
              label: 'Time',
              value: '${session.time} · ${session.duration}',
            ),
            _DetailsRow(
              icon: presentation.icon,
              label: 'Status',
              value: presentation.label,
              color: presentation.color,
            ),
            const SizedBox(height: 10),
            Text(
              'This local preview does not identify a patient, change a care record, or send notifications.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            if (isComplete)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Session complete'),
              )
            else
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark complete in preview'),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  const _DetailsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleDay {
  const _ScheduleDay({required this.label, required this.date});

  final String label;
  final String date;
}

class _PreviewSession {
  const _PreviewSession({
    required this.id,
    required this.dayIndex,
    required this.time,
    required this.title,
    required this.duration,
    required this.detail,
    required this.status,
  });

  final String id;
  final int dayIndex;
  final String time;
  final String title;
  final String duration;
  final String detail;
  final _SessionStatus status;
}

enum _ScheduleFilter {
  all('All sessions'),
  scheduled('Scheduled'),
  needsReview('Needs review');

  const _ScheduleFilter(this.label);

  final String label;
}

enum _SessionStatus { confirmed, needsReview, completed }

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  factory _StatusPresentation.of(BuildContext context, _SessionStatus status) {
    return switch (status) {
      _SessionStatus.confirmed => const _StatusPresentation(
          label: 'Scheduled',
          icon: Icons.event_available_outlined,
          color: Color(0xFF4966C5),
        ),
      _SessionStatus.needsReview => const _StatusPresentation(
          label: 'Needs review',
          icon: Icons.fact_check_outlined,
          color: Color(0xFFB26A00),
        ),
      _SessionStatus.completed => const _StatusPresentation(
          label: 'Complete',
          icon: Icons.check_circle_outline,
          color: Color(0xFF198754),
        ),
    };
  }
}
