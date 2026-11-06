import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../providers/tracker_provider.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder.dart';
import '../services/care_plan_service.dart';
import '../utils/date_utils.dart';
import '../widgets/section_card.dart';
import 'hydration_nutrition_screen.dart';
import 'weather_screen.dart';
import 'support_screen.dart';
import 'settings/settings_screen.dart';
import 'admin/admin_screen.dart';

/// Home dashboard tab: greeting + today's snapshot (hydration, pain, next
/// reminder) + quick actions + secondary "explore" shortcuts.
class DashboardScreen extends StatelessWidget {
  final void Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  static int _minOfDay(DateTime t) => t.hour * 60 + t.minute;

  static Reminder? _nextReminder(List<Reminder> active, DateTime now) {
    if (active.isEmpty) return null;
    final nowMin = _minOfDay(now);
    for (final r in active) {
      if (_minOfDay(r.time) >= nowMin) return r;
    }
    return active.first;
  }

  static _RiskStatus _riskStatus({
    required int todayMl,
    required int? pain,
  }) {
    if ((pain ?? 0) >= 8) {
      return const _RiskStatus(
        label: 'High risk',
        labelFr: 'Risque élevé',
        body:
            'Severe pain logged. Watch for chest pain, fever or breathing trouble.',
        bodyFr:
            'Douleur sévère notée. Surveille douleur thoracique, fièvre ou respiration difficile.',
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFB42318),
      );
    }
    if ((pain ?? 0) >= 5 || todayMl < 1000) {
      return const _RiskStatus(
        label: 'Needs attention',
        labelFr: 'À surveiller',
        body: 'Hydrate, rest, keep warm and follow prescribed medication.',
        bodyFr:
            'Hydrate-toi, repose-toi, reste au chaud et suis ton traitement prescrit.',
        icon: Icons.health_and_safety_outlined,
        color: Color(0xFFB54708),
      );
    }
    return const _RiskStatus(
      label: 'Stable today',
      labelFr: 'Stable aujourd’hui',
      body: 'Keep your hydration and reminder routine going.',
      bodyFr: 'Continue ton hydratation et tes rappels.',
      icon: Icons.verified_outlined,
      color: Color(0xFF067647),
    );
  }

  static int _checkinStreak(List entries, DateTime now) {
    final days = <String>{};
    for (final e in entries) {
      final d = e.date as DateTime;
      days.add('${d.year}-${d.month}-${d.day}');
    }
    var streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    while (days.contains('${cursor.year}-${cursor.month}-${cursor.day}')) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = context.l10n;
    final auth = context.watch<AuthProvider>();
    final entries = context.watch<TrackerProvider>().entries;
    final reminderProvider = context.watch<ReminderProvider>();
    final reminders = reminderProvider.items;
    final emergencyContacts = CarePlanService.getEmergencyContacts();

    String? firstName;
    final pn = (auth.profile?['name'] as String?)?.trim();
    final dn = auth.user?.displayName?.trim();
    final em = auth.user?.email;
    if (pn != null && pn.isNotEmpty) {
      firstName = pn.split(' ').first;
    } else if (dn != null && dn.isNotEmpty) {
      firstName = dn.split(' ').first;
    } else if (em != null && em.contains('@')) {
      final p = em.split('@').first;
      if (p.isNotEmpty) {
        firstName = p[0].toUpperCase() + p.substring(1);
      }
    }

    final now = DateTime.now();
    bool sameDay(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;
    const goalMl = 3000;
    final todayMl = entries
        .where((e) => sameDay(e.date))
        .fold<int>(0, (s, e) => s + e.hydrationMl);
    final hydration = (todayMl / goalMl).clamp(0.0, 1.0);
    final lastPain = entries.isNotEmpty ? entries.first.painLevel : null;
    final risk = _riskStatus(todayMl: todayMl, pain: lastPain);
    final streak = _checkinStreak(entries, now);
    final hasGenotype =
        ((auth.profile?['genotype'] ?? '').toString().trim()).isNotEmpty;
    final activeCustomReminders = reminders.where((r) => r.enabled).length;
    final setupDone = [
      hasGenotype,
      reminderProvider.hydrationReminderEnabled,
      activeCustomReminders > 0,
      emergencyContacts.isNotEmpty,
    ].where((done) => done).length;

    final active = reminders.where((r) => r.enabled).toList()
      ..sort((a, b) => _minOfDay(a.time).compareTo(_minOfDay(b.time)));
    final next = _nextReminder(active, now);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          firstName == null
                              ? l.helloNoName
                              : l.hello(firstName),
                          style: tt.headlineSmall),
                      const SizedBox(height: 2),
                      Text(l.formatDayDate(now),
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (auth.isAdmin)
                  IconButton(
                    tooltip: l.adminTitle,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                  ),
                IconButton(
                  tooltip: l.settingsTitle,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      child: _HydrationCard(
                          progress: hydration, ml: todayMl, goalMl: goalMl)),
                  const SizedBox(width: 12),
                  Expanded(child: _PainCard(pain: lastPain)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _RiskCard(
              risk: risk,
              onCrisis: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SupportScreen(crisisMode: true),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CareSetupCard(
              completed: setupDone,
              hasGenotype: hasGenotype,
              hydrationReady: reminderProvider.hydrationReminderEnabled,
              alarmsReady: activeCustomReminders > 0,
              caregiverReady: emergencyContacts.isNotEmpty,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              onTap: () => onNavigate(3),
              child: Row(
                children: [
                  _IconBadge(icon: Icons.alarm, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.nextReminder,
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12.5)),
                        const SizedBox(height: 2),
                        Text(
                          next == null
                              ? l.noActiveReminder
                              : '${next.title} · ${fmtTime(next.time)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              gradient: LinearGradient(
                colors: [
                  cs.primary,
                  Color.lerp(cs.primary, Colors.black, 0.24)!
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.dailyCheckin,
                            style: tt.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(l.dailyCheckinSub,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12.5)),
                        const SizedBox(height: 6),
                        Text(
                          l.tr('$streak-day check-in streak',
                              '$streak jour(s) de suivi'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(l.quickActions, style: tt.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _ActionButton(
                        icon: Icons.add,
                        label: l.navCheckin,
                        onTap: () => onNavigate(2))),
                const SizedBox(width: 12),
                Expanded(
                    child: _ActionButton(
                        icon: Icons.emergency_outlined,
                        label: l.tr('Crisis mode', 'Mode crise'),
                        onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SupportScreen(crisisMode: true),
                              ),
                            ))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _ActionButton(
                        icon: Icons.smart_toy_outlined,
                        label: l.aiAssistant,
                        onTap: () => onNavigate(4))),
                const SizedBox(width: 12),
                Expanded(
                    child: _ActionButton(
                        icon: Icons.picture_as_pdf_outlined,
                        label: l.tr('Doctor report', 'Rapport médecin'),
                        onTap: () => onNavigate(1))),
              ],
            ),
            const SizedBox(height: 20),
            Text(l.explore, style: tt.titleMedium),
            const SizedBox(height: 12),
            _ExploreTile(
              icon: Icons.local_drink_outlined,
              title: l.hydrationDiet,
              subtitle: l.nutritionTips,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const HydrationNutritionScreen())),
            ),
            const SizedBox(height: 10),
            _ExploreTile(
              icon: Icons.wb_cloudy_outlined,
              title: l.weatherCare,
              subtitle: l.weatherTipsSub,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WeatherScreen())),
            ),
            const SizedBox(height: 10),
            _ExploreTile(
              icon: Icons.support_agent,
              title: l.supportEmergency,
              subtitle: l.contactEmergencySub,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupportScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareSetupCard extends StatelessWidget {
  final int completed;
  final bool hasGenotype;
  final bool hydrationReady;
  final bool alarmsReady;
  final bool caregiverReady;
  final VoidCallback onTap;

  const _CareSetupCard({
    required this.completed,
    required this.hasGenotype,
    required this.hydrationReady,
    required this.alarmsReady,
    required this.caregiverReady,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final progress = completed / 4;

    return SectionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                  icon: Icons.assignment_turned_in_outlined, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.tr('Care setup', 'Configuration des soins'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.tr('$completed of 4 ready', '$completed sur 4 prêts'),
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SetupChip(
                label: l.genotype,
                done: hasGenotype,
              ),
              _SetupChip(
                label: l.tr('Hydration', 'Hydratation'),
                done: hydrationReady,
              ),
              _SetupChip(
                label: l.tr('Alarms', 'Alarmes'),
                done: alarmsReady,
              ),
              _SetupChip(
                label: l.tr('Caregiver', 'Aidant'),
                done: caregiverReady,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupChip extends StatelessWidget {
  final String label;
  final bool done;

  const _SetupChip({
    required this.label,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 18,
        color: done ? cs.primary : cs.onSurfaceVariant,
      ),
      label: Text(label),
      side: BorderSide(color: cs.outlineVariant),
    );
  }
}

class _RiskStatus {
  final String label;
  final String labelFr;
  final String body;
  final String bodyFr;
  final IconData icon;
  final Color color;

  const _RiskStatus({
    required this.label,
    required this.labelFr,
    required this.body,
    required this.bodyFr,
    required this.icon,
    required this.color,
  });
}

class _RiskCard extends StatelessWidget {
  final _RiskStatus risk;
  final VoidCallback onCrisis;

  const _RiskCard({
    required this.risk,
    required this.onCrisis,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SectionCard(
      child: Row(
        children: [
          _IconBadge(icon: risk.icon, color: risk.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.tr(risk.label, risk.labelFr),
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  l.tr(risk.body, risk.bodyFr),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCrisis,
            child: Text(l.tr('Help', 'Aide')),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _HydrationCard extends StatelessWidget {
  final double progress;
  final int ml;
  final int goalMl;
  const _HydrationCard(
      {required this.progress, required this.ml, required this.goalMl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.water_drop_outlined, color: cs.primary, size: 20),
            const SizedBox(width: 6),
            Text(context.l10n.hydration,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          ]),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
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
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                  Text('${(progress * 100).round()}%',
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${(ml / 1000).toStringAsFixed(1)} / ${(goalMl / 1000).toStringAsFixed(0)} L',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PainCard extends StatelessWidget {
  final int? pain;
  const _PainCard({required this.pain});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = context.l10n;
    final p = pain;
    final emoji = p == null
        ? '🙂'
        : (p <= 2
            ? '😀'
            : p <= 4
                ? '🙂'
                : p <= 6
                    ? '😐'
                    : p <= 8
                        ? '😕'
                        : '😣');
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.healing_outlined, color: cs.primary, size: 20),
            const SizedBox(width: 6),
            Text(l.pain,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          ]),
          const SizedBox(height: 12),
          Center(child: Text(emoji, style: const TextStyle(fontSize: 42))),
          const SizedBox(height: 8),
          Center(
            child: Text(p == null ? '—' : '$p / 10',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(p == null ? l.notLoggedYet : l.lastReading,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ExploreTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _IconBadge(icon: icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
