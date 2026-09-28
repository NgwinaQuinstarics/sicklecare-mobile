import 'package:flutter/material.dart';

import '../../models/doctor_profile.dart';
import '../../widgets/section_card.dart';

/// A compact, consistently coloured representation of a clinician's
/// verification state. The shared model stays the source of truth; this
/// widget only decides how that state is presented.
class DoctorStatusPill extends StatelessWidget {
  const DoctorStatusPill({
    super.key,
    required this.status,
    this.compact = false,
  });

  final DoctorVerificationStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final presentation = _DoctorStatusPresentation.of(context, status);
    return Semantics(
      label: 'Verification status: ${presentation.label}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: presentation.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: presentation.color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              presentation.icon,
              size: compact ? 15 : 16,
              color: presentation.color,
            ),
            const SizedBox(width: 5),
            Text(
              presentation.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: presentation.color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable contextual notice used where a verification state needs a more
/// explanatory treatment than [DoctorStatusPill].
class DoctorStatusBanner extends StatelessWidget {
  const DoctorStatusBanner({
    super.key,
    required this.status,
    this.title,
    this.message,
    this.onTap,
  });

  final DoctorVerificationStatus status;
  final String? title;
  final String? message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final presentation = _DoctorStatusPresentation.of(context, status);
    final resolvedTitle = title ?? presentation.bannerTitle;
    final resolvedMessage = message ?? presentation.bannerMessage;

    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resolvedTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    DoctorStatusPill(status: status, compact: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  resolvedMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

/// The initial-based doctor avatar used throughout the clinician experience.
class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({
    super.key,
    required this.name,
    this.radius = 26,
    this.showAvailability = false,
    this.isAvailable = true,
  });

  final String name;
  final double radius;
  final bool showAvailability;
  final bool isAvailable;

  String get _initials {
    final words = name
        .replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'DR';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label:
          '$name${showAvailability ? (isAvailable ? ', available' : ', unavailable') : ''}',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: cs.primary.withValues(alpha: 0.14),
            foregroundColor: cs.primary,
            child: Text(
              _initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (showAvailability)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: radius * 0.52,
                height: radius * 0.52,
                decoration: BoxDecoration(
                  color: isAvailable ? const Color(0xFF198754) : cs.outline,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DoctorSectionHeader extends StatelessWidget {
  const DoctorSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class DoctorMetricCard extends StatelessWidget {
  const DoctorMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.helper,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? helper;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.primary;
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(
              helper!,
              style: TextStyle(color: accent, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}

class DoctorDetailRow extends StatelessWidget {
  const DoctorDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.showChevron = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _DoctorStatusPresentation {
  const _DoctorStatusPresentation({
    required this.label,
    required this.bannerTitle,
    required this.bannerMessage,
    required this.icon,
    required this.color,
  });

  final String label;
  final String bannerTitle;
  final String bannerMessage;
  final IconData icon;
  final Color color;

  factory _DoctorStatusPresentation.of(
    BuildContext context,
    DoctorVerificationStatus status,
  ) {
    final error = Theme.of(context).colorScheme.error;
    return switch (status) {
      DoctorVerificationStatus.approved => const _DoctorStatusPresentation(
          label: 'Verified',
          bannerTitle: 'Your professional profile is verified',
          bannerMessage:
              'Your credentials are current and your clinician workspace is active.',
          icon: Icons.verified_rounded,
          color: Color(0xFF198754),
        ),
      DoctorVerificationStatus.pending => const _DoctorStatusPresentation(
          label: 'Under review',
          bannerTitle: 'Verification is in progress',
          bannerMessage:
              'You can complete your profile while the review team checks your credentials.',
          icon: Icons.hourglass_top_rounded,
          color: Color(0xFFB26A00),
        ),
      DoctorVerificationStatus.rejected => _DoctorStatusPresentation(
          label: 'Action needed',
          bannerTitle: 'Your credential submission needs attention',
          bannerMessage:
              'Review the feedback, update the requested document, and submit it again.',
          icon: Icons.error_outline_rounded,
          color: error,
        ),
    };
  }
}
