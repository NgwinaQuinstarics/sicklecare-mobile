import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/hydration_nutrition_screen.dart';
import '../screens/history_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/tracker_screen.dart';

class MainNavigation extends StatefulWidget {
  final int currentIndex;

  const MainNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  // ── Screen builders — called fresh each time, no const issues ──────────────
  static final _screens = <WidgetBuilder>[
    (_) => const HomeScreen(),
    (_) => const HydrationNutritionScreen(),
    (_) => const HistoryScreen(),
    (_) => const RemindersScreen(),
    (_) => const TrackerScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;

    // Instant tab switch — no slide animation (feels like native bottom nav)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _screens[index](context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTap,
      selectedItemColor: const Color(0xFF1E40AF),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 11,
      ),
      elevation: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop_outlined),
          activeIcon: Icon(Icons.water_drop_rounded),
          label: 'Health',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart_rounded),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications_rounded),
          label: 'Reminders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor_heart_outlined),
          activeIcon: Icon(Icons.monitor_heart_rounded),
          label: 'Tracker',
        ),
      ],
    );
  }
}