import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../models/health_tracking.dart';
import '../../providers/care_ui_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';
import 'health_timeline_screen.dart';

/// A presentation-only appointment request flow for the warrior experience.
///
/// Requests are kept only for the active UI session. They are intentionally
/// not bookings, availability checks, notifications, or clinical records.
class AppointmentRequestScreen extends StatefulWidget {
  const AppointmentRequestScreen({super.key});

  @override
  State<AppointmentRequestScreen> createState() =>
      _AppointmentRequestScreenState();
}

class _AppointmentRequestScreenState extends State<AppointmentRequestScreen> {
  final List<_AppointmentRequest> _requests = <_AppointmentRequest>[];

  Future<void> _openRequestForm() async {
    final draft = await showModalBottomSheet<_AppointmentDraft>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _AppointmentRequestForm(),
    );
    if (draft == null || !mounted) return;

    final createdAt = DateTime.now();
    final request = _AppointmentRequest(
      id: 'appointment-${createdAt.microsecondsSinceEpoch}',
      facility: draft.facility,
      careTeam: draft.careTeam,
      preferredTiming: draft.preferredTiming,
      note: draft.note,
      createdAt: createdAt,
    );
    setState(() => _requests.insert(0, request));
    context.read<CareUiProvider>().addTimelineEvent(
          HealthTimelineEvent(
            id: request.id,
            occurredAt: createdAt,
            type: HealthTimelineEventType.appointment,
            title: 'Appointment request saved in preview',
            description:
                '${request.facility} · ${request.preferredTiming} · Not sent to a care team.',
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment request saved in this preview session.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.tr('Appointments', 'Rendez-vous'))),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              key: const Key('appointment-request-list'),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                StatusBanner(
                  tone: StatusBannerTone.info,
                  title: l.tr(
                    'Appointment-request preview',
                    'Aperçu des demandes de rendez-vous',
                  ),
                  message: l.tr(
                    'Nothing entered here is sent, booked, or shared with a care team. A data and availability contract is still needed.',
                    'Rien de ce qui est saisi ici n’est envoyé, réservé ou partagé avec une équipe de soins. Un contrat de données et de disponibilité reste nécessaire.',
                  ),
                ),
                const SizedBox(height: 16),
                _AppointmentHero(
                  title: l.tr(
                    'Plan your next care conversation',
                    'Prépare ton prochain échange de soins',
                  ),
                  subtitle: l.tr(
                    'Create a local request preview, then use it to organise questions for your care team.',
                    'Crée un aperçu de demande local, puis utilise-le pour organiser tes questions pour l’équipe de soins.',
                  ),
                  requestCount: _requests.length,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('appointment-request-cta'),
                  onPressed: _openRequestForm,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _requests.isEmpty
                        ? l.tr(
                            'Request an appointment', 'Demander un rendez-vous')
                        : l.tr('Create another request',
                            'Créer une autre demande'),
                  ),
                ),
                const SizedBox(height: 24),
                if (_requests.isEmpty)
                  _AppointmentEmptyState(
                    title: l.tr(
                      'No appointment requests yet',
                      'Aucune demande de rendez-vous',
                    ),
                    subtitle: l.tr(
                      'When the data contract is approved, this area can show request, confirmation, and follow-up states.',
                      'Quand le contrat de données sera validé, cet espace pourra afficher les états de demande, de confirmation et de suivi.',
                    ),
                  )
                else ...[
                  Text(
                    l.tr('Your local request preview', 'Tes demandes locales'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  for (final request in _requests) ...[
                    _AppointmentRequestCard(request: request),
                    const SizedBox(height: 10),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HealthTimelineScreen(
                            initialFilter: HealthTimelineEventType.appointment,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.timeline_outlined),
                      label: Text(
                        l.tr('View in local timeline',
                            'Voir dans la chronologie locale'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                StatusBanner(
                  tone: StatusBannerTone.warning,
                  title: l.tr(
                    'Need urgent help?',
                    'Besoin d’une aide urgente ?',
                  ),
                  message: l.tr(
                    'Do not wait for an appointment request if you have urgent symptoms. Use the emergency information card instead.',
                    'N’attends pas une demande de rendez-vous en cas de symptôme urgent. Utilise plutôt la carte d’informations d’urgence.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentHero extends StatelessWidget {
  const _AppointmentHero({
    required this.title,
    required this.subtitle,
    required this.requestCount,
  });

  final String title;
  final String subtitle;
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cs.primary, Color.lerp(cs.primary, Colors.black, .26)!],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.event_available_outlined, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: .9)),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.tr(
              '$requestCount local ${requestCount == 1 ? 'request' : 'requests'}',
              '$requestCount demande${requestCount == 1 ? '' : 's'} locale${requestCount == 1 ? '' : 's'}',
            ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentEmptyState extends StatelessWidget {
  const _AppointmentEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today_outlined, color: cs.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AppointmentRequestCard extends StatelessWidget {
  const _AppointmentRequestCard({required this.request});

  final _AppointmentRequest request;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final status = request.status;
    return SectionCard(
      padding: const EdgeInsets.all(15),
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
                  color: status.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(status.icon, color: status.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  request.facility,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RequestDetail(
            icon: Icons.groups_2_outlined,
            text: request.careTeam,
          ),
          const SizedBox(height: 8),
          _RequestDetail(
            icon: Icons.schedule_outlined,
            text: request.preferredTiming,
          ),
          if (request.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            _RequestDetail(icon: Icons.notes_outlined, text: request.note),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusPill(status: status),
              Text(
                l.tr('Local preview only', 'Aperçu local uniquement'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final _AppointmentRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label(l),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: status.color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _AppointmentRequestForm extends StatefulWidget {
  const _AppointmentRequestForm();

  @override
  State<_AppointmentRequestForm> createState() =>
      _AppointmentRequestFormState();
}

class _AppointmentRequestFormState extends State<_AppointmentRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  String? _facility;
  String? _careTeam;
  String? _preferredTiming;
  bool _showTimingError = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _showTimingError = _preferredTiming == null);
    if (!valid || _preferredTiming == null) return;
    final l = context.l10n;
    Navigator.of(context).pop(
      _AppointmentDraft(
        facility: _facilityOptions
            .singleWhere((option) => option.id == _facility)
            .label(l),
        careTeam: _careTeamOptions
            .singleWhere((option) => option.id == _careTeam)
            .label(l),
        preferredTiming: _preferredTiming!,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, keyboard + 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l.tr('Request an appointment', 'Demander un rendez-vous'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  l.tr(
                    'Choose temporary preview options to review the request experience.',
                    'Choisis des options temporaires pour examiner l’expérience de demande.',
                  ),
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  key: const Key('appointment-facility-select'),
                  isExpanded: true,
                  initialValue: _facility,
                  decoration: InputDecoration(
                    labelText:
                        l.tr('Preferred facility', 'Établissement souhaité'),
                    prefixIcon: const Icon(Icons.local_hospital_outlined),
                  ),
                  items: _facilityOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option.id,
                          child: Text(option.label(l)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _facility = value),
                  validator: (value) => value == null
                      ? l.tr('Choose a facility.', 'Choisis un établissement.')
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: const Key('appointment-team-select'),
                  isExpanded: true,
                  initialValue: _careTeam,
                  decoration: InputDecoration(
                    labelText: l.tr(
                        'Preferred care team', 'Équipe de soins souhaitée'),
                    prefixIcon: const Icon(Icons.groups_2_outlined),
                  ),
                  items: _careTeamOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option.id,
                          child: Text(option.label(l)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _careTeam = value),
                  validator: (value) => value == null
                      ? l.tr(
                          'Choose a care team.', 'Choisis une équipe de soins.')
                      : null,
                ),
                const SizedBox(height: 18),
                Text(
                  l.tr('Preferred timing', 'Moment souhaité'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timingOptions
                      .map(
                        (option) => ChoiceChip(
                          key: Key('appointment-timing-${option.id}'),
                          label: Text(option.label(l)),
                          selected: _preferredTiming == option.label(l),
                          onSelected: (_) => setState(() {
                            _preferredTiming = option.label(l);
                            _showTimingError = false;
                          }),
                        ),
                      )
                      .toList(growable: false),
                ),
                if (_showTimingError) ...[
                  const SizedBox(height: 6),
                  Text(
                    l.tr('Choose a preferred timing.',
                        'Choisis un moment souhaité.'),
                    style: TextStyle(color: cs.error),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('appointment-note-field'),
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l.tr('Note (optional)', 'Note (facultative)'),
                    hintText: l.tr(
                      'Keep it general for this preview.',
                      'Reste général dans cet aperçu.',
                    ),
                    helperText: l.tr(
                      'Do not include sensitive information; nothing is sent.',
                      'N’ajoute pas d’information sensible ; rien n’est envoyé.',
                    ),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 52),
                      child: Icon(Icons.notes_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StatusBanner(
                  tone: StatusBannerTone.warning,
                  title: l.tr('Not a booking', 'Ce n’est pas une réservation'),
                  message: l.tr(
                    'Submitting only saves this request in the current UI preview session.',
                    'La soumission enregistre seulement cette demande dans la session d’aperçu actuelle.',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('appointment-request-submit'),
                  onPressed: _submit,
                  icon: const Icon(Icons.add_task_outlined),
                  label: Text(
                    l.tr('Save preview request',
                        'Enregistrer la demande d’aperçu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentDraft {
  const _AppointmentDraft({
    required this.facility,
    required this.careTeam,
    required this.preferredTiming,
    required this.note,
  });

  final String facility;
  final String careTeam;
  final String preferredTiming;
  final String note;
}

class _AppointmentRequest {
  const _AppointmentRequest({
    required this.id,
    required this.facility,
    required this.careTeam,
    required this.preferredTiming,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String facility;
  final String careTeam;
  final String preferredTiming;
  final String note;
  final DateTime createdAt;
  final _AppointmentRequestStatus status = _AppointmentRequestStatus.pending;
}

enum _AppointmentRequestStatus { pending, confirmed, declined }

extension on _AppointmentRequestStatus {
  Color get color => switch (this) {
        _AppointmentRequestStatus.pending => const Color(0xFFB54708),
        _AppointmentRequestStatus.confirmed => const Color(0xFF067647),
        _AppointmentRequestStatus.declined => const Color(0xFFB42318),
      };

  IconData get icon => switch (this) {
        _AppointmentRequestStatus.pending => Icons.hourglass_top_rounded,
        _AppointmentRequestStatus.confirmed => Icons.check_circle_outline,
        _AppointmentRequestStatus.declined => Icons.cancel_outlined,
      };

  String label(L10n l) => switch (this) {
        _AppointmentRequestStatus.pending =>
          l.tr('Pending · preview', 'En attente · aperçu'),
        _AppointmentRequestStatus.confirmed =>
          l.tr('Confirmed · preview', 'Confirmé · aperçu'),
        _AppointmentRequestStatus.declined =>
          l.tr('Declined · preview', 'Refusé · aperçu'),
      };
}

class _TimingOption {
  const _TimingOption(this.id, this.label);

  final String id;
  final String Function(L10n l) label;
}

class _PreviewOption {
  const _PreviewOption(this.id, this.label);

  final String id;
  final String Function(L10n l) label;
}

const _facilityOptions = <_PreviewOption>[
  _PreviewOption('preview-hospital', _previewHospitalLabel),
  _PreviewOption('preview-clinic', _previewClinicLabel),
  _PreviewOption('community-centre', _communityCentreLabel),
];

const _careTeamOptions = <_PreviewOption>[
  _PreviewOption('next-available', _nextAvailableTeamLabel),
  _PreviewOption('haematology', _haematologyTeamLabel),
  _PreviewOption('general-care', _generalCareTeamLabel),
];

const _timingOptions = <_TimingOption>[
  _TimingOption('next-available', _nextAvailableLabel),
  _TimingOption('this-week', _thisWeekLabel),
  _TimingOption('next-week', _nextWeekLabel),
];

String _nextAvailableLabel(L10n l) =>
    l.tr('Next available', 'Dès que possible');
String _thisWeekLabel(L10n l) => l.tr('This week', 'Cette semaine');
String _nextWeekLabel(L10n l) => l.tr('Next week', 'La semaine prochaine');
String _previewHospitalLabel(L10n l) =>
    l.tr('SickleCare Preview Hospital', 'Hôpital SickleCare — aperçu');
String _previewClinicLabel(L10n l) =>
    l.tr('SickleCare Preview Clinic', 'Clinique SickleCare — aperçu');
String _communityCentreLabel(L10n l) => l.tr('Community care centre (preview)',
    'Centre de soins communautaire (aperçu)');
String _nextAvailableTeamLabel(L10n l) => l.tr(
      'Care team · next available (preview)',
      'Équipe de soins · prochaine disponibilité (aperçu)',
    );
String _haematologyTeamLabel(L10n l) =>
    l.tr('Haematology team (preview)', 'Équipe d’hématologie (aperçu)');
String _generalCareTeamLabel(L10n l) =>
    l.tr('General care team (preview)', 'Équipe de soins généraux (aperçu)');
