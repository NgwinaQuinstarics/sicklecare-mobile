import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_role.dart';
import '../../providers/care_ui_provider.dart';
import '../../signup.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';
import '../doctor/doctor_registration_screen.dart';

/// Selects a presentation path before onboarding. Warrior signup retains the
/// existing Firebase flow; clinician registration intentionally remains a
/// mock-only UI until the account and verification contracts are agreed.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _openWarriorSignup(BuildContext context) {
    context.read<CareUiProvider>().setActiveRole(AppRole.warrior);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  void _openDoctorRegistration(BuildContext context) {
    context.read<CareUiProvider>().setActiveRole(AppRole.doctor);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DoctorRegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your SickleCare path')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary,
                        Color.lerp(cs.primary, Colors.black, 0.23)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite_outline,
                          color: Colors.white, size: 34),
                      const SizedBox(height: 16),
                      Text(
                        'Care designed around your role',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose the path that best describes how you will use SickleCare.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StatusBanner(
                  tone: StatusBannerTone.info,
                  title: 'Clinician onboarding is a UI preview',
                  message:
                      'The warrior option uses the existing account flow. Doctor registration below is presentation-only and does not create or change a Firebase record yet.',
                ),
                const SizedBox(height: 22),
                _RoleOption(
                  icon: Icons.favorite_outline,
                  title: 'I am a sickle-cell warrior',
                  subtitle:
                      'Create a personal account to track health, reminders and care information.',
                  buttonLabel: 'Create warrior account',
                  accent: cs.primary,
                  onPressed: () => _openWarriorSignup(context),
                ),
                const SizedBox(height: 12),
                _RoleOption(
                  icon: Icons.medical_services_outlined,
                  title: 'I am a healthcare professional',
                  subtitle:
                      'Preview professional profile, credentials, verification and clinician workspace screens.',
                  buttonLabel: 'Preview clinician registration',
                  accent: const Color(0xFF1976A8),
                  onPressed: () => _openDoctorRegistration(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Already have an account? Return to sign in and use the role assigned to your account once role management is connected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.accent,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
