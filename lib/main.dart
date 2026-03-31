import 'package:flutter/material.dart';
//import 'login.dart';
import 'splash_screen.dart';

void main() {
  runApp(const SickleCareApp());
}

class SickleCareApp extends StatelessWidget {
  const SickleCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SickleCare',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const SplashScreen(),
    );
  }
}