// lib/screens/weather_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key}); 

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String adviceMessage = '';

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          setState(() {
            isLoading = false;
            adviceMessage = 'Location permission denied';
          });
          return;
        }
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Fetch weather data
      WeatherService service = WeatherService();
      final data = await service.getWeather(position.latitude, position.longitude);

      // Set advice based on temperature
      double temp = data['main']['temp'];
      if (temp <= 18) {
        adviceMessage = 'It’s cold! Stay warm and wear extra layers.';
      } else if (temp <= 25) {
        adviceMessage = 'Cool weather, dress comfortably.';
      } else {
        adviceMessage = 'It’s warm! Stay hydrated and wear light clothes.';
      }

      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        adviceMessage = 'Error fetching weather: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather in Cameroon'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weatherData == null
              ? Center(child: Text(adviceMessage))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${weatherData!['name']}', // City name
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${weatherData!['main']['temp'].toString()} °C',
                        style: const TextStyle(
                            fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${weatherData!['weather'][0]['description']}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        adviceMessage,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
    );
  }
}