import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ScCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Border? border;
  final double radius;

  const ScCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.border,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue,
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
