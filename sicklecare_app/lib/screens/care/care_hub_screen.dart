import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/care_ui_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';
import '../facilities/facilities_screen.dart';
import 'crisis_tracking_screen.dart';
import 'emergency_information_screen.dart';
import 'health_timeline_screen.dart';
import 'medication_hydration_screen.dart';
import 'warrior_health_profile_screen.dart';

/// Entry point for the richer warrior experience. All information is supplied
/// by [CareUiProvider]'s mock adapter until the data contract is approved.
class CareHubScreen extends StatelessWidget {
  const CareHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareUiProvider>();
    if (care.isLoading && !care.hasLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!care.hasLoaded && care.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My care')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatusBanner(
              tone: StatusBannerTone.error,
              title: 'Care preview unavailable',
              message: care.errorMessage,
              action: TextButton.icon(
                onPressed: care.retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ),
          ),
        ),
      );
    }

    final profile = care.warriorProfile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final progress = care.hydrationProgress.clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(title: const Text('My care')),
      body: RefreshIndicator(
        onRefresh: () => care.load(force: true),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                StatusBanner(
                  tone: StatusBannerTone.info,
                  title: 'Care-plan preview',
                  message:
                      'The information on these screens is temporary mock data for UI review. It is not clinical advice or a saved health record.',
                ),
                const SizedBox(height: 16),
                _CareHero(
                  name: profile.displayName,
                  hydrationMl: care.hydrationTodayMl,
                  hydrationGoalMl: care.hydrationGoalMl,
                  progress: progress,
                  crisisCount: care.painCrises.length,
                ),
                const SizedBox(height: 24),
                Text(
                  'My health tools',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                _CareLink(
                  icon: Icons.badge_outlined,
                  title: 'Health profile',
                  subtitle: 'Genotype, care team, triggers and notes',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          WarriorHealthProfileScreen(profile: profile),
                    ),
                  ),
                ),
                _CareLink(
                  icon: Icons.monitor_heart_outlined,
                  title: 'Pain crisis tracker',
                  subtitle: 'Log symptoms, severity and care actions',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const CrisisTrackingScreen()),
                  ),
                ),
                _CareLink(
                  icon: Icons.medication_outlined,
                  title: 'Medicines & hydration',
                  subtitle: 'Reminder preview, doses and hydration progress',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MedicationHydrationScreen(),
                    ),
                  ),
                ),
                _CareLink(
                  icon: Icons.timeline_outlined,
                  title: 'Health timeline',
                  subtitle: 'Review your mock care events in one place',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const HealthTimelineScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Urgent care & support',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                _CareLink(
                  icon: Icons.emergency_outlined,
                  title: 'Emergency information',
                  subtitle: 'A clear emergency card and trusted contact',
                  accent: Theme.of(context).colorScheme.error,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmergencyInformationScreen(),
                    ),
                  ),
                ),
                _CareLink(
                  icon: Icons.local_hospital_outlined,
                  title: 'Find a healthcare facility',
                  subtitle: 'Search, filter and inspect nearby-care previews',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FacilitiesScreen(
                        facilities: care.facilities,
                        onRefresh: () => care.load(force: true),
                        onFacilitySelected: care.selectFacility,
                        locationLabel: 'Douala · preview area',
                      ),
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
}

class _CareHero extends StatelessWidget {
  const _CareHero({
    required this.name,
    required this.hydrationMl,
    required this.hydrationGoalMl,
    required this.progress,
    required this.crisisCount,
  });

  final String name;
  final int hydrationMl;
  final int hydrationGoalMl;
  final double progress;
  final int crisisCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.24)!],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A clearer care view, $name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(hydrationMl / 1000).toStringAsFixed(1)} L of ${(hydrationGoalMl / 1000).toStringAsFixed(1)} L hydration goal',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 4),
                Text(
                  '$crisisCount recent crisis ${crisisCount == 1 ? 'entry' : 'entries'} in this preview',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareLink extends StatelessWidget {
  const _CareLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = accent ?? cs.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
