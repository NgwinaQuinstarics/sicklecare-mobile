import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'l10n/strings.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tracker_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/locale_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Each init is isolated: if a plugin fails on a given device, the app still
  // reaches runApp() instead of crashing at startup.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('dotenv load skipped: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    await Hive.initFlutter();
    await Hive.openBox('app_cache');
    await Hive.openBox('tracker');
    await Hive.openBox('reminders');
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  try {
    tz.initializeTimeZones();
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  runApp(const SickleCareApp());
}

class SickleCareApp extends StatelessWidget {
  const SickleCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TrackerProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProv, localeProv, _) => MaterialApp(
          title: 'SickleCare',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProv.themeMode,
          locale: localeProv.locale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
          routes: {
            '/auth': (_) => const AuthGate(),
          },
        ),
      ),
    );
  }
}
