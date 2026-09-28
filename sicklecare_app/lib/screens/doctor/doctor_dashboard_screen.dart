import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/doctor_profile.dart';
import '../../providers/care_ui_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';
import 'credential_submission_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_ui_components.dart';
import 'doctor_verification_status_screen.dart';

/// A clinician home workspace designed to work with temporary presentation
/// data. Integrators can pass the current profile values or wire its actions
/// to a provider without changing the screen layout.
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({
    super.key,
    this.doctorName = 'Dr. Amara Nfor',
    this.specialty = 'Haematology',
    this.facilityName = 'Buea Regional Hospital',
    this.verificationStatus = DoctorVerificationStatus.pending,
    this.onOpenAppointments,
  });

  final String doctorName;
  final String specialty;
  final String facilityName;
  final DoctorVerificationStatus verificationStatus;
  final VoidCallback? onOpenAppointments;

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const _dates = ['12', '13', '14', '15', '16'];

  bool _isAvailable = true;
  bool _isRefreshing = false;
  bool _showEmptySchedule = false;
  int _selectedDay = 0;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _openAppointments() {
    final callback = widget.onOpenAppointments;
    if (callback != null) {
      callback();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Appointment management will appear here when connected.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final previewProfile = context.watch<CareUiProvider>().doctorProfile;
    final doctorName = previewProfile?.fullName ?? widget.doctorName;
    final specialty = previewProfile?.specialty ?? widget.specialty;
    final facilityName = previewProfile?.facilityName ?? widget.facilityName;
    final verificationStatus =
        previewProfile?.verificationStatus ?? widget.verificationStatus;
    final credentials =
        previewProfile?.credentials ?? const <DoctorCredential>[];
    final isAvailable = previewProfile?.isAvailable ?? _isAvailable;
    final hour = TimeOfDay.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final nameWithoutTitle = doctorName
        .replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '')
        .trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Care workspace'),
        actions: [
          IconButton(
            tooltip: 'Verification status',
            icon: Badge(
              isLabelVisible:
                  verificationStatus != DoctorVerificationStatus.approved,
              smallSize: 8,
              child: const Icon(Icons.verified_user_outlined),
            ),
            onPressed: () => _openVerification(verificationStatus, credentials),
          ),
          IconButton(
            tooltip: 'Professional profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _openProfile(
              doctorName: doctorName,
              specialty: specialty,
              facilityName: facilityName,
              verificationStatus: verificationStatus,
              profile: previewProfile,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '$greeting${nameWithoutTitle.isEmpty ? '' : ', Dr. $nameWithoutTitle'}',
                                style: tt.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 3),
                            Text(
                              '$specialty · $facilityName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      DoctorAvatar(
                        name: doctorName,
                        showAvailability: true,
                        isAvailable: isAvailable,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const StatusBanner(
                    tone: StatusBannerTone.info,
                    title: 'Clinician workspace preview',
                    message:
                        'Profile, availability, credentials and verification are session-only UI data. No documents are uploaded or reviewed from this screen yet.',
                  ),
                  const SizedBox(height: 18),
                  DoctorStatusBanner(
                    status: verificationStatus,
                    onTap: () =>
                        _openVerification(verificationStatus, credentials),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    padding: const EdgeInsets.fromLTRB(15, 12, 10, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (isAvailable
                                    ? const Color(0xFF198754)
                                    : cs.outline)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isAvailable
                                ? Icons.toggle_on_outlined
                                : Icons.pause_circle_outline,
                            color: isAvailable
                                ? const Color(0xFF198754)
                                : cs.outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAvailable
                                    ? 'Accepting consultations'
                                    : 'Not accepting consultations',
                                style: tt.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAvailable
                                    ? 'Your current availability is visible in this UI preview.'
                                    : 'Turn this on when you are ready to receive requests.',
                                style: TextStyle(
                                    color: cs.onSurfaceVariant, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isAvailable,
                          onChanged: (value) {
                            setState(() => _isAvailable = value);
                            context
                                .read<CareUiProvider>()
                                .setDoctorAvailability(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'You are marked as available.'
                                      : 'You are marked as unavailable.',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  DoctorSectionHeader(
                    title: 'At a glance',
                    subtitle: 'A privacy-respecting snapshot of your workday.',
                    actionLabel: _isRefreshing ? 'Refreshing…' : 'Refresh',
                    onAction: _isRefreshing ? null : _refresh,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 700 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: columns == 4 ? 1.05 : 1.18,
                        children: [
                          DoctorMetricCard(
                            label: 'Today’s sessions',
                            value: '8',
                            helper: '2 remaining',
                            icon: Icons.calendar_today_outlined,
                            onTap: _openAppointments,
                          ),
                          const DoctorMetricCard(
                            label: 'Care-plan reviews',
                            value: '4',
                            helper: 'Due this week',
                            icon: Icons.fact_check_outlined,
                            color: Color(0xFF4966C5),
                          ),
                          const DoctorMetricCard(
                            label: 'Follow-ups',
                            value: '5',
                            helper: 'Next 7 days',
                            icon: Icons.favorite_outline_rounded,
                            color: Color(0xFFB26A00),
                          ),
                          DoctorMetricCard(
                            label: 'Profile score',
                            value: '86%',
                            helper: 'Add credentials',
                            icon: Icons.account_circle_outlined,
                            color: const Color(0xFF198754),
                            onTap: () => _openProfile(
                              doctorName: doctorName,
                              specialty: specialty,
                              facilityName: facilityName,
                              verificationStatus: verificationStatus,
                              profile: previewProfile,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: DoctorSectionHeader(
                          title: 'Today’s schedule',
                          subtitle: 'Use the calendar view for all sessions.',
                        ),
                      ),
                      IconButton(
                        tooltip: _showEmptySchedule
                            ? 'Show sample schedule'
                            : 'Preview empty state',
                        icon: Icon(
                          _showEmptySchedule
                              ? Icons.calendar_month_outlined
                              : Icons.filter_alt_outlined,
                        ),
                        onPressed: () {
                          setState(
                              () => _showEmptySchedule = !_showEmptySchedule);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _days.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final selected = _selectedDay == index;
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _selectedDay = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 56,
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
                                  _days[index],
                                  style: TextStyle(
                                    color: selected
                                        ? cs.onPrimary
                                        : cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _dates[index],
                                  style: tt.titleMedium?.copyWith(
                                    color:
                                        selected ? cs.onPrimary : cs.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showEmptySchedule
                        ? SectionCard(
                            key: const ValueKey('empty-schedule'),
                            child: const SizedBox(
                              height: 185,
                              child: EmptyState(
                                icon: Icons.event_available_outlined,
                                title: 'No sessions on this day',
                                subtitle:
                                    'Your open time can be used for care-plan reviews or preparation.',
                              ),
                            ),
                          )
                        : SectionCard(
                            key: const ValueKey('schedule'),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: const [
                                _ScheduleItem(
                                  time: '09:00',
                                  title: 'New consultation',
                                  detail: '30-minute appointment',
                                  color: Color(0xFF4966C5),
                                ),
                                Divider(height: 1),
                                _ScheduleItem(
                                  time: '11:30',
                                  title: 'Care-plan follow-up',
                                  detail: '20-minute appointment',
                                  color: Color(0xFF198754),
                                ),
                                Divider(height: 1),
                                _ScheduleItem(
                                  time: '15:00',
                                  title: 'Clinical review',
                                  detail: '30-minute appointment',
                                  color: Color(0xFFB26A00),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  const DoctorSectionHeader(
                    title: 'Professional profile',
                    subtitle: 'Keep your verification and credentials current.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardAction(
                          icon: Icons.account_circle_outlined,
                          title: 'View profile',
                          onTap: () => _openProfile(
                            doctorName: doctorName,
                            specialty: specialty,
                            facilityName: facilityName,
                            verificationStatus: verificationStatus,
                            profile: previewProfile,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardAction(
                          icon: Icons.upload_file_outlined,
                          title: 'Credentials',
                          onTap: () => _openCredentials(verificationStatus),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _openVerification(verificationStatus, credentials),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Review verification status'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openCredentials(DoctorVerificationStatus verificationStatus) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CredentialSubmissionScreen(
          verificationStatus: verificationStatus,
        ),
      ),
    );
  }

  void _openVerification(
    DoctorVerificationStatus verificationStatus,
    List<DoctorCredential> credentials,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorVerificationStatusScreen(
          status: verificationStatus,
          credentials: credentials,
          onSubmitCredentials: () => _openCredentials(verificationStatus),
        ),
      ),
    );
  }

  void _openProfile({
    required String doctorName,
    required String specialty,
    required String facilityName,
    required DoctorVerificationStatus verificationStatus,
    DoctorProfile? profile,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorProfessionalProfileScreen(
          fullName: doctorName,
          specialty: specialty,
          facilityName: facilityName,
          verificationStatus: verificationStatus,
          profile: profile,
        ),
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem({
    required this.time,
    required this.title,
    required this.detail,
    required this.color,
  });

  final String time;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
