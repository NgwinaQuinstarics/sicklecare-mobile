import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app language. `null` = follow the device language.
class LocaleProvider extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString('locale')) {
      case 'fr':
        _locale = const Locale('fr');
        break;
      case 'en':
        _locale = const Locale('en');
        break;
      default:
        _locale = null; // system
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? l) async {
    _locale = l;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', l?.languageCode ?? 'system');
  }
}
