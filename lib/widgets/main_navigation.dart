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
  late int currentIndex;

  final List<Widget> screens = const [
    HomeScreen(),
    HydrationNutritionScreen(),
    HistoryScreen(),
    RemindersScreen(),
    TrackerScreen(), // ✅ REPLACED PROFILE WITH TRACKER
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;
  }

  void onTap(int index) {
    if (index == currentIndex) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screens[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: const Color(0xFF1E40AF),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop),
          label: "Health",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: "History",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: "Reminders",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor_heart),
          label: "Tracker",
        ),
      ],
    );
  }
}