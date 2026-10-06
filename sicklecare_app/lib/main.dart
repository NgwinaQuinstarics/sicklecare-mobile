import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'l10n/strings.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tracker_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/locale_provider.dart';
import 'services/app_security_service.dart';
import 'services/alarm_service.dart';
import 'screens/splash_screen.dart';
import 'screens/alarm_screen.dart';
import 'auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 1: dotenv + Firebase can initialise in parallel.
  Future<void> loadEnv() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('dotenv load error: $e');
    }
  }

  Future<FirebaseApp?> initFirebase() async {
    try {
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase init error: $e');
      return null;
    }
  }

  await Future.wait([
    loadEnv(),
    initFirebase(),
  ]);

  await AppSecurityService.instance.init();

  // Phase 2: Hive init, then open all boxes in parallel.
  try {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox('app_cache'),
      Hive.openBox('tracker'),
      Hive.openBox('reminders'),
    ]);
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  // Phase 3: Alarm/notification service (depends on nothing above).
  try {
    await AlarmService.instance.init(requestPermissions: false);
  } catch (e) {
    debugPrint('AlarmService init error: $e');
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
          navigatorKey: AlarmService.navigatorKey,
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
          builder: (context, child) => _ReminderRecoveryHost(
            child: child ?? const SizedBox.shrink(),
          ),
          home: const SplashScreen(),
          routes: {
            '/auth': (_) => const AuthGate(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/alarm') {
              final title = settings.arguments as String? ?? 'SickleCare Alarm';
              return MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => AlarmScreen(title: title),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}

class _ReminderRecoveryHost extends StatefulWidget {
  final Widget child;
  const _ReminderRecoveryHost({required this.child});

  @override
  State<_ReminderRecoveryHost> createState() => _ReminderRecoveryHostState();
}

class _ReminderRecoveryHostState extends State<_ReminderRecoveryHost>
    with WidgetsBindingObserver {
  bool _repairing = false;
  DateTime? _lastRepair;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _repairSilently());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _repairSilently();
    }
  }

  Future<void> _repairSilently() async {
    if (!mounted || _repairing) return;
    if (!Hive.isBoxOpen('reminders') ||
        !Hive.isBoxOpen('tracker') ||
        !Hive.isBoxOpen('app_cache')) {
      return;
    }
    final now = DateTime.now();
    final last = _lastRepair;
    if (last != null && now.difference(last) < const Duration(minutes: 5)) {
      return;
    }
    final reminderProvider = context.read<ReminderProvider>();
    final trackerProvider = context.read<TrackerProvider>();
    _repairing = true;
    try {
      await reminderProvider.repairSchedules(requestPermissions: false);
      await trackerProvider.syncPending();
      _lastRepair = now;
    } catch (e) {
      debugPrint('Silent recovery failed: $e');
    } finally {
      _repairing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
