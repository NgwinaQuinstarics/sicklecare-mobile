import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/doctor_profile.dart';
import '../../providers/care_ui_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';
import 'doctor_ui_components.dart';

/// Explains the UI-only professional verification journey.
///
/// Verification outcomes are intentionally supplied by the presentation layer;
/// this screen does not read or write a backend review record.
class DoctorVerificationStatusScreen extends StatelessWidget {
  const DoctorVerificationStatusScreen({
    super.key,
    required this.status,
    this.credentials = const [],
    this.onSubmitCredentials,
  });

  final DoctorVerificationStatus status;
  final List<DoctorCredential> credentials;
  final VoidCallback? onSubmitCredentials;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final previewProfile = context.watch<CareUiProvider>().doctorProfile;
    final currentStatus = previewProfile?.verificationStatus ?? status;
    final currentCredentials = previewProfile?.credentials ?? credentials;
    final copy = _VerificationCopy.forStatus(currentStatus);
    final completed = currentStatus == DoctorVerificationStatus.approved;
    final needsAction = currentStatus == DoctorVerificationStatus.rejected;

    return Scaffold(
      appBar: AppBar(title: const Text('Professional verification')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary,
                        Color.lerp(cs.primary, Colors.black, 0.25)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(copy.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        copy.heroTitle,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        copy.heroMessage,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DoctorStatusPill(status: currentStatus),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                StatusBanner(
                  tone: needsAction
                      ? StatusBannerTone.error
                      : completed
                          ? StatusBannerTone.success
                          : StatusBannerTone.info,
                  title: copy.bannerTitle,
                  message: copy.bannerMessage,
                ),
                const SizedBox(height: 24),
                Text(
                  'What happens next',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                _VerificationStep(
                  number: 1,
                  title: 'Professional details',
                  detail:
                      'Your specialty, facility and availability are captured.',
                  state: _StepState.complete,
                ),
                _VerificationStep(
                  number: 2,
                  title: 'Credentials submitted',
                  detail: currentCredentials.isEmpty
                      ? 'Add a licence or qualification for review.'
                      : '${currentCredentials.length} document${currentCredentials.length == 1 ? '' : 's'} ready for review.',
                  state: currentCredentials.isEmpty
                      ? _StepState.current
                      : currentStatus == DoctorVerificationStatus.rejected
                          ? _StepState.needsAction
                          : _StepState.complete,
                ),
                _VerificationStep(
                  number: 3,
                  title: 'Review outcome',
                  detail: completed
                      ? 'Your professional profile can be shown as verified.'
                      : needsAction
                          ? 'Update the requested information and submit again.'
                          : 'A review team will confirm your professional details.',
                  state: completed
                      ? _StepState.complete
                      : needsAction
                          ? _StepState.needsAction
                          : _StepState.pending,
                  isLast: true,
                ),
                const SizedBox(height: 18),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview-only workflow',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'This status UI uses temporary in-memory data. No licence, credential, or verification outcome is sent to a server from this screen.',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!completed) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onSubmitCredentials ??
                        () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Open the credentials area to add a document.'),
                              ),
                            ),
                    icon: Icon(needsAction
                        ? Icons.edit_document
                        : Icons.upload_file_outlined),
                    label: Text(
                        needsAction ? 'Update credentials' : 'Add credentials'),
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

enum _StepState { complete, current, pending, needsAction }

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({
    required this.number,
    required this.title,
    required this.detail,
    required this.state,
    this.isLast = false,
  });

  final int number;
  final String title;
  final String detail;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final presentation = switch (state) {
      _StepState.complete => (Icons.check_rounded, const Color(0xFF198754)),
      _StepState.current => (Icons.edit_outlined, cs.primary),
      _StepState.pending => (Icons.more_horiz_rounded, cs.outline),
      _StepState.needsAction => (Icons.priority_high_rounded, cs.error),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: presentation.$2.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(presentation.$1, size: 18, color: presentation.$2),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: cs.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number. $title',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCopy {
  const _VerificationCopy({
    required this.icon,
    required this.heroTitle,
    required this.heroMessage,
    required this.bannerTitle,
    required this.bannerMessage,
  });

  final IconData icon;
  final String heroTitle;
  final String heroMessage;
  final String bannerTitle;
  final String bannerMessage;

  factory _VerificationCopy.forStatus(DoctorVerificationStatus status) {
    return switch (status) {
      DoctorVerificationStatus.approved => const _VerificationCopy(
          icon: Icons.verified_rounded,
          heroTitle: 'Your clinician profile is verified',
          heroMessage:
              'Your professional details are ready to appear with a verified status.',
          bannerTitle: 'Verification complete',
          bannerMessage:
              'Keep professional credentials current when your requirements change.',
        ),
      DoctorVerificationStatus.pending => const _VerificationCopy(
          icon: Icons.hourglass_top_rounded,
          heroTitle: 'Your verification is in progress',
          heroMessage:
              'Complete your professional profile while credentials are queued for review.',
          bannerTitle: 'Awaiting review',
          bannerMessage:
              'You can continue preparing your workspace. Review timing will be defined with the care team.',
        ),
      DoctorVerificationStatus.rejected => const _VerificationCopy(
          icon: Icons.edit_document,
          heroTitle: 'Your submission needs an update',
          heroMessage:
              'Review the requested information and provide an updated credential.',
          bannerTitle: 'Action required',
          bannerMessage:
              'Nothing is changed automatically. Re-submit only after reviewing the requested details.',
        ),
    };
  }
}
