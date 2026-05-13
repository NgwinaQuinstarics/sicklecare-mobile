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

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color deepBlue = Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ),
    );

    scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ),
    );

    controller.forward();

    // SPLASH SCREEN DELAY
    Timer(
      const Duration(seconds: 6),
      () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AuthWrapper(),
          ),
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
            colors: [
              primaryBlue,
              deepBlue,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: fadeAnimation,

              child: ScaleTransition(
                scale: scaleAnimation,

                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // ================= LOGO =================

                      Container(
                        width: 250,
                        height: 250,

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.20),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(22),

                          child: Image.asset(
                            "assets/logo.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
   
                      // ================= SUBTITLE =================

                      const Text(
                        "Care • Support • Empowerment",
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Your Daily Health Companion",
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 60),

                      // ================= LOADING =================

                      const SizedBox(
                        width: 38,
                        height: 38,

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
      ),
    );
  }
}