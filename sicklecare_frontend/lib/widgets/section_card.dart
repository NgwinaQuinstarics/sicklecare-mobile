import 'package:flutter/material.dart';

/// Reusable rounded surface used across the app.
///
/// Backward-compatible: existing call sites that only pass [child] (and
/// optionally [padding]) keep working. New optional params add an [onTap]
/// ripple and an optional [gradient] background for hero cards.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(20);

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null
            ? (Theme.of(context).cardTheme.color ?? cs.surfaceContainer)
            : null,
        gradient: gradient,
        borderRadius: radius,
        border: gradient == null
            ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.7))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: card),
    );
  }
}
