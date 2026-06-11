import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'tracker_screen.dart';
import 'reminders_screen.dart';
import 'ai_chat_screen.dart';

/// Root authenticated shell: bottom navigation + persistent tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _go(int i) {
    if (i != _index) setState(() => _index = i);
  }

  late final List<Widget> _tabs = [
    DashboardScreen(onNavigate: _go),
    const HistoryScreen(),
    const TrackerScreen(),
    const RemindersScreen(),
    const AIChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l.navTracking,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: l.navCheckin,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications),
            label: l.navReminders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(Icons.smart_toy),
            label: l.navAssistant,
          ),
        ],
      ),
    );
  }
}
