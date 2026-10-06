import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../l10n/strings.dart';
import '../auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthGate(),
          transitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(cs.surface, cs.primary, 0.10)!,
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              ZoomIn(
                duration: const Duration(milliseconds: 420),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset('assets/logo.png',
                      width: 116,
                      height: 116,
                      cacheWidth: 320,
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 22),
              FadeInUp(
                duration: const Duration(milliseconds: 420),
                child: Text('SickleCare',
                    style: text.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              FadeInUp(
                delay: const Duration(milliseconds: 90),
                duration: const Duration(milliseconds: 420),
                child: Text(context.l10n.appTagline,
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
              const SizedBox(height: 34),
              FadeIn(
                delay: const Duration(milliseconds: 180),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: cs.primary),
                ),
              ),
              const Spacer(),
              FadeIn(
                delay: const Duration(milliseconds: 260),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 18),
                  child: Text(
                    context.l10n.disclaimer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 11, height: 1.4),
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
