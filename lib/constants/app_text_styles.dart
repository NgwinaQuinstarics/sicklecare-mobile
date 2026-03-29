import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.nunito(
    fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.navy,
  );
  static TextStyle heading2 = GoogleFonts.nunito(
    fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy,
  );
  static TextStyle heading3 = GoogleFonts.nunito(
    fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.navy,
  );
  static TextStyle title = GoogleFonts.nunito(
    fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy,
  );
  static TextStyle body = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textLight,
  );
  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted,
  );
  static TextStyle label = GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy,
  );
  static TextStyle button = GoogleFonts.nunito(
    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
  );
  static TextStyle heroScore = GoogleFonts.nunito(
    fontSize: 44, fontWeight: FontWeight.w900, color: const Color(0xFF4DFFD4),
  );
  static TextStyle bigNumber = GoogleFonts.nunito(
    fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.navy,
  );
}
