import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../services/alarm_service.dart';

/// Full-screen alarm UI that displays when a persistent alarm is ringing.
///
/// Shows a pulsing alarm icon, the reminder title, and a prominent
/// "Stop Alarm" button. The screen stays visible until the user taps stop.
class AlarmScreen extends StatefulWidget {
  final String title;
  const AlarmScreen({super.key, required this.title});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shakeController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _shakeAnimation;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();

    // Keep the screen awake while the alarm is ringing.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Pulse animation for the alarm icon background.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shake animation for the alarm icon.
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat(reverse: true);

    _shakeAnimation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    if (_stopping) return; // Prevent double-tap
    _stopping = true;

    // Stop animations first to detach listeners before any tree changes.
    _pulseController.stop();
    _shakeController.stop();

    // Dismiss all active alarm notifications.
    await AlarmService.instance.dismissActiveAlarm();
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false, // Prevent back button from dismissing without stopping.
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A0A0A),
                Color(0xFF2D0F0F),
                Color(0xFF1A0A0A),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ---- Pulsing alarm icon ----
                _PulsingAlarmIcon(
                  pulseAnimation: _pulseAnimation,
                  shakeAnimation: _shakeAnimation,
                  iconSize: size.width * 0.38,
                ),

                const SizedBox(height: 40),

                // ---- "Alarm ringing!" label ----
                Text(
                  l.alarmRinging,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF6B6B),
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // ---- Reminder title ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        l.alarmFor,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ---- Pulsing ring indicator ----
                _PulsingRing(animation: _pulseAnimation),

                const SizedBox(height: 32),

                // ---- STOP ALARM button ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _stopAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: 8,
                        shadowColor:
                            const Color(0xFFFF4444).withValues(alpha: 0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.alarm_off, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            l.stopAlarm,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ---- Hint text ----
                Text(
                  l.medicationTime,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animation widgets — extend AnimatedWidget directly to avoid any
// AnimatedBuilder lifecycle issues.
// ---------------------------------------------------------------------------

/// Combines pulse (scale) + shake (rotate) into a single animated icon.
class _PulsingAlarmIcon extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final Animation<double> shakeAnimation;
  final double iconSize;

  const _PulsingAlarmIcon({
    required this.pulseAnimation,
    required this.shakeAnimation,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return _ScaleAnimatedWidget(
      animation: pulseAnimation,
      child: _RotateAnimatedWidget(
        animation: shakeAnimation,
        child: Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFFFF4444),
                Color(0xFFCC1111),
                Color(0xFF880000),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4444).withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFFFF0000).withValues(alpha: 0.3),
                blurRadius: 80,
                spreadRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.alarm,
            size: 72,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// AnimatedWidget that applies a scale transform.
class _ScaleAnimatedWidget extends AnimatedWidget {
  final Widget child;
  const _ScaleAnimatedWidget({
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    return Transform.scale(scale: anim.value, child: child);
  }
}

/// AnimatedWidget that applies a rotation transform (radians).
class _RotateAnimatedWidget extends AnimatedWidget {
  final Widget child;
  const _RotateAnimatedWidget({
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    return Transform.rotate(angle: anim.value, child: child);
  }
}

/// A subtle pulsing ring decoration behind the stop button area.
class _PulsingRing extends AnimatedWidget {
  const _PulsingRing({required Animation<double> animation})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    final opacity = (anim.value - 0.85) / 0.3; // 0..1
    return Container(
      width: 120 * anim.value,
      height: 120 * anim.value,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFF4444)
              .withValues(alpha: opacity.clamp(0.0, 0.4)),
          width: 2,
        ),
      ),
    );
  }
}
