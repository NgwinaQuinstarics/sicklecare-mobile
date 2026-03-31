// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // OpenWeatherMap API key
  final String apiKey = 'dd211ba3e0176d8198fce34c96413e3c';

  /// Fetch weather data from OpenWeatherMap
  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    final Uri url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch weather data');
    }
  }
}