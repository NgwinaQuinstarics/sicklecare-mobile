import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherSnapshot {
  final double tempC;
  final double humidity;
  final double windKph;
  final String summary;

  WeatherSnapshot({
    required this.tempC,
    required this.humidity,
    required this.windKph,
    required this.summary,
  });
}

class WeatherService {
  /// Uses Open-Meteo (no API key required)
  static Future<WeatherSnapshot?> current() async {
    try {
      final pos = await _position();
      if (pos == null) return null;

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${pos.latitude}'
        '&longitude=${pos.longitude}'
        '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
      );

      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final j = jsonDecode(res.body);
      final c = j['current'];

      return WeatherSnapshot(
        tempC: (c['temperature_2m'] as num).toDouble(),
        humidity: (c['relative_humidity_2m'] as num).toDouble(),
        windKph: (c['wind_speed_10m'] as num).toDouble(),
        summary: _codeToText(c['weather_code'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  /// Safe location handler
  static Future<Position?> _position() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Weather code mapping
  static String _codeToText(int c) {
    if (c == 0) return 'Clear sky';
    if (c < 3) return 'Partly cloudy';
    if (c == 3) return 'Overcast';
    if (c >= 45 && c <= 48) return 'Fog';
    if (c >= 51 && c <= 67) return 'Rain';
    if (c >= 71 && c <= 77) return 'Snow';
    if (c >= 80 && c <= 82) return 'Showers';
    if (c >= 95) return 'Thunderstorm';
    return 'Weather';
  }
}