import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';
import 'store/app_state.dart';
import 'splash_screen.dart';
//import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.navy,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const SickleCareApp());
}

class SickleCareApp extends StatelessWidget {
  const SickleCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => HydrationProvider()),
      ],
      child: MaterialApp(
        title: 'SickleCare',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.dmSansTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.navy),
            titleTextStyle: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(), // Show splash first
      ),
    );
  }
}