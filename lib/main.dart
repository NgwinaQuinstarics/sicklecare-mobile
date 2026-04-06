import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'services/notification_service.dart';
import 'splash_screen.dart';
import 'signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize Notifications
  await NotificationService.init();

  runApp(const SickleCareApp());
}

class SickleCareApp extends StatelessWidget {
  const SickleCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SickleCare App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),

      // ✅ First screen
      home: const SplashScreen(),

      // ✅ Routes
      routes: {
        "/signup": (context) => const SignupScreen(),
      },
    );
  }
}