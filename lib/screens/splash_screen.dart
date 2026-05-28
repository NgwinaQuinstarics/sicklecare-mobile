import 'dart:async';
import 'package:flutter/material.dart';
import '../auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> disclaimerFade;

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color deepBlue    = Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );

    scaleAnimation = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );

    // Disclaimer fades in slightly later than the logo
    disclaimerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    controller.forward();

    Timer(
      const Duration(seconds: 6),
      () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, deepBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // ── Main content — logo + tagline ──────────────────────────────
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            // Logo
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 25,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            const SizedBox(height: 36),

                            const Text(
                              'Care • Support • Empowerment',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Your Daily Health Companion',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 52),

                            // Loading indicator
                            const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Disclaimer — fades in at bottom ───────────────────────────
              FadeTransition(
                opacity: disclaimerFade,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF), // 10% white
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0x33FFFFFF), // 20% white
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFFCC80), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Medical Disclaimer',
                            style: TextStyle(
                              color: Color(0xFFFFCC80),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SickleCare is an informational and  support app. '
                        'It does not provide medical diagnosis, or treatment. '
                        'Always consult a qualified healthcare professional for medical decisions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SickleCare Cameroon · v1.0',
                        style: TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}