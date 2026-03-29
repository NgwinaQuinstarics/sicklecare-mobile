import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum BtnVariant { primary, teal, danger, ghost, secondary }

class ScButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final BtnVariant variant;
  final bool loading;
  final String? icon;

  const ScButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BtnVariant.primary,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cfg['bg'],
          foregroundColor: cfg['fg'],
          elevation: cfg['elev'],
          shadowColor: (cfg['bg'] as Color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: cfg['border'] != null
              ? BorderSide(color: cfg['border'] as Color, width: 2)
              : BorderSide.none,
        ),
        child: loading
            ? SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: cfg['fg'] as Color, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Text(icon!, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8)],
                  Text(label, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: cfg['fg'] as Color)),
                ],
              ),
      ),
    );
  }

  Map<String, dynamic> _cfg() => switch (variant) {
    BtnVariant.primary   => {'bg': AppColors.blue,  'fg': Colors.white, 'elev': 6.0, 'border': null},
    BtnVariant.teal      => {'bg': AppColors.teal,  'fg': Colors.white, 'elev': 5.0, 'border': null},
    BtnVariant.danger    => {'bg': AppColors.rose,  'fg': Colors.white, 'elev': 6.0, 'border': null},
    BtnVariant.secondary => {'bg': AppColors.blueLight, 'fg': AppColors.blue, 'elev': 0.0, 'border': AppColors.blue},
    BtnVariant.ghost     => {'bg': Colors.transparent, 'fg': AppColors.muted, 'elev': 0.0, 'border': AppColors.border},
  };
}
