import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class ScInput extends StatefulWidget {
  final String label;
  final String placeholder;
  final String? icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? errorText;

  const ScInput({
    super.key,
    required this.label,
    required this.placeholder,
    this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.errorText,
  });

  @override
  State<ScInput> createState() => _ScInputState();
}

class _ScInputState extends State<ScInput> {
  bool _showPass = false;
  bool _focused  = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navyMid)),
        const SizedBox(height: 7),
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.isPassword && !_showPass,
            style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14),
              prefixIcon: widget.icon != null
                  ? Padding(padding: const EdgeInsets.all(12), child: Text(widget.icon!, style: const TextStyle(fontSize: 18)))
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Text(_showPass ? '🙈' : '👁', style: const TextStyle(fontSize: 16)),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    )
                  : null,
              filled: true,
              fillColor: _focused ? AppColors.card : AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.blue, width: 2),
              ),
              errorText: widget.errorText,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
