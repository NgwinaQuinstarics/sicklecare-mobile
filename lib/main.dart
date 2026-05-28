import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'auth_wrapper.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// NOTIFICATIONS
  await NotificationService.init();
  await NotificationService.requestPermission();

  /// LOAD SAVED THEME
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('darkMode') ?? false;

  runApp(
    SickleCareApp(
      isDarkMode: isDarkMode,
    ),
  );
}

class SickleCareApp extends StatefulWidget {
  final bool isDarkMode;

  const SickleCareApp({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<SickleCareApp> createState() => _SickleCareAppState();
}

class _SickleCareAppState extends State<SickleCareApp> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  /// ================= CHANGE THEME =================
  Future<void> changeTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('darkMode', value);

    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      changeTheme: changeTheme,

      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        title: 'SickleCare',

        themeMode:
            isDarkMode ? ThemeMode.dark : ThemeMode.light,

        /// ================= LIGHT THEME =================
        theme: ThemeData(
          useMaterial3: true,

          brightness: Brightness.light,

          primaryColor: const Color(0xFF1565C0),

          scaffoldBackgroundColor: const Color(0xFFF4F7FA),

          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),

          cardColor: Colors.white,
        ),

        /// ================= DARK THEME =================
        darkTheme: ThemeData(
          useMaterial3: true,

          brightness: Brightness.dark,

          scaffoldBackgroundColor:
              const Color(0xFF0F172A),

          primaryColor: const Color(0xFF2563EB),

          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.dark,
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),

          cardColor: const Color(0xFF1E293B),
        ),

        home: const AuthWrapper(),
      ),
    );
  }
}

/// ================= GLOBAL THEME CONTROLLER =================
class ThemeController extends InheritedWidget {
  final Function(bool) changeTheme;

  const ThemeController({
    super.key,
    required this.changeTheme,
    required super.child,
  });

  static ThemeController of(BuildContext context) {
    final ThemeController? result =
        context.dependOnInheritedWidgetOfExactType<
            ThemeController>();

    assert(result != null, 'No ThemeController found');

    return result!;
  }

  @override
  bool updateShouldNotify(
    ThemeController oldWidget,
  ) {
    return true;
  }
}