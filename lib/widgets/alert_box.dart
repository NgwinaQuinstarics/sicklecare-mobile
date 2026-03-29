import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum AlertVariant { warning, info, danger, success }

class AlertBox extends StatelessWidget {
  final AlertVariant variant;
  final String emoji;
  final String title;
  final String message;

  const AlertBox({
    super.key,
    this.variant = AlertVariant.warning,
    required this.emoji,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cfg['bg'] as Color,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: cfg['border'] as Color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800,
                    color: cfg['text'] as Color)),
                const SizedBox(height: 3),
                Text(message,
                  style: GoogleFonts.dmSans(fontSize: 12, color: cfg['text'] as Color,
                    height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _cfg() => switch (variant) {
    AlertVariant.warning => {'bg': AppColors.amberLight, 'border': AppColors.amber,  'text': const Color(0xFF92400E)},
    AlertVariant.info    => {'bg': AppColors.blueLight,  'border': AppColors.blue,   'text': AppColors.navyMid},
    AlertVariant.danger  => {'bg': AppColors.roseLight,  'border': AppColors.rose,   'text': const Color(0xFFBE185D)},
    AlertVariant.success => {'bg': AppColors.greenLight, 'border': AppColors.green,  'text': const Color(0xFF15803D)},
  };
}
