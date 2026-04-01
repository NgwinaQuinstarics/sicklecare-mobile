import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  WeatherService weatherService = WeatherService();
  double? latitude;
  double? longitude;
  Map<String, dynamic>? weatherData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getLocationAndWeather();
  }

  Future<void> getLocationAndWeather() async {
    setState(() => isLoading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    latitude = position.latitude;
    longitude = position.longitude;

    weatherData = await weatherService.getWeather(latitude!, longitude!);

    // Convert temp to double safely
    if (weatherData != null && weatherData!['temp'] is int) {
      weatherData!['temp'] = (weatherData!['temp'] as int).toDouble();
    }

    setState(() => isLoading = false);
  }

  String getWeatherMessage(double temp) {
    if (temp < 10) return 'Brrr… Stay warm! 🧣';
    if (temp < 20) return 'It\'s a bit chilly. Wear a jacket! 🧥';
    if (temp < 30) return 'Nice weather today! 🌤️';
    return 'It\'s hot! Stay cool! ☀️';
  }

  String getWeatherIcon(String iconCode) {
    return 'http://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: getLocationAndWeather,
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(getWeatherIcon(weatherData!['icon'])),
                  const SizedBox(height: 20),
                  Text(
                    '${(weatherData!['temp'] as double).toStringAsFixed(1)}°C',
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    weatherData!['description'].toString(),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    getWeatherMessage(weatherData!['temp'] as double),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}