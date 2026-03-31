import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Weather? _weather;
  bool _loading = true;
  String? _advice;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() => _loading = true);

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final service = WeatherService();
    final weather = await service.getWeather(position.latitude, position.longitude);

    String advice = '';
    if (weather != null) {
      if (weather.temp < 18) {
        advice = 'It\'s cold 🥶, wear warm clothes!';
      } else if (weather.temp > 30) {
        advice = 'It\'s hot 🔥, stay hydrated!';
      } else {
        advice = 'Weather is nice 🌤️, have a great day!';
      }
    }

    setState(() {
      _weather = weather;
      _advice = advice;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Weather'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _weather == null
              ? const Center(child: Text('Failed to fetch weather'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weather!.city,
                        style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_weather!.temp.toStringAsFixed(1)}°C',
                        style: GoogleFonts.nunito(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _weather!.description,
                        style: GoogleFonts.dmSans(
                            fontSize: 20, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _advice ?? '',
                          style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}