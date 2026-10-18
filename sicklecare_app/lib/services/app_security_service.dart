import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppSecurityService {
  AppSecurityService._();
  static final instance = AppSecurityService._();

  Future<void> init() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttestWithDeviceCheckFallback,
      );
    } catch (e) {
      debugPrint('AppCheck init error: $e');
    }
  }
}
