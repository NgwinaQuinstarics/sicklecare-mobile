import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  try {
    await _initializeFirebase();
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error\n$stackTrace');
    runApp(FirebaseStartupErrorApp(onRetry: _retryStartup));
    return;
  }

  await _initializeLocalServices();
  runApp(const SickleCareApp());
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> _initializeLocalServices() async {
  await AppSecurityService.instance.init();

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
}

Future<void> _retryStartup() async {
  await _initializeFirebase();
  await _initializeLocalServices();
  runApp(const SickleCareApp());
}

class FirebaseStartupErrorApp extends StatefulWidget {
  const FirebaseStartupErrorApp({required this.onRetry, super.key});

  final Future<void> Function() onRetry;

  @override
  State<FirebaseStartupErrorApp> createState() =>
      _FirebaseStartupErrorAppState();
}

class _FirebaseStartupErrorAppState extends State<FirebaseStartupErrorApp> {
  bool _retrying = false;
  String? _errorMessage;

  Future<void> _retry() async {
    setState(() {
      _retrying = true;
      _errorMessage = null;
    });

    try {
      await widget.onRetry();
    } catch (error, stackTrace) {
      debugPrint('Firebase startup retry failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Connection still unavailable. Check your internet connection and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SickleCare',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/appicon.jpeg',
                      width: 88,
                      height: 88,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SickleCare could not connect',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your account and health data need a secure Firebase connection. Check your internet connection and try again.',
                      textAlign: TextAlign.center,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _retrying ? null : _retry,
                      child: _retrying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Retry connection'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
