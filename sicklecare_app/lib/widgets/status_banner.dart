import 'package:flutter/material.dart';

/// A compact, accessible status message for preview, loading, and error states.
class StatusBanner extends StatelessWidget {
  final StatusBannerTone tone;
  final String title;
  final String? message;
  final Widget? action;

  const StatusBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spec = switch (tone) {
      StatusBannerTone.info => (
          Icons.info_outline,
          cs.primary,
          cs.primaryContainer,
        ),
      StatusBannerTone.success => (
          Icons.check_circle_outline,
          Colors.green.shade700,
          Colors.green.shade50,
        ),
      StatusBannerTone.warning => (
          Icons.warning_amber_rounded,
          Colors.orange.shade800,
          Colors.orange.shade50,
        ),
      StatusBannerTone.error => (
          Icons.error_outline,
          cs.error,
          cs.errorContainer,
        ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: spec.$3,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: spec.$2.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(spec.$1, color: spec.$2, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: spec.$2, fontWeight: FontWeight.w700),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 3),
                    Text(message!, style: TextStyle(color: cs.onSurface)),
                  ],
                  if (action != null) ...[const SizedBox(height: 8), action!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum StatusBannerTone { info, success, warning, error }
