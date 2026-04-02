import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _locationController = TextEditingController();
  String? _weatherDescription;
  double? _temperature;
  String? _advice;
  bool _loading = false;

  // Replace with your OpenWeatherMap API key
  final String apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';

  Future<void> fetchWeather(String city) async {
    setState(() {
      _loading = true;
    });

    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric');

    try {
      final response = await http.get(url);
      if (!mounted) return; // Prevent setState after dispose
      final data = json.decode(response.body);

      if (data['cod'] == 200) {
        double temp = data['main']['temp'];
        String desc = data['weather'][0]['description'];

        String advice;
        if (temp < 18) {
          advice = "It's cold. Stay warm and avoid getting chilled.";
        } else if (temp > 28) {
          advice = "It's hot. Stay hydrated and avoid heat stress.";
        } else {
          advice = "Weather is mild. Stay comfortable and hydrated.";
        }

        setState(() {
          _temperature = temp;
          _weatherDescription = desc;
          _advice = advice;
          _loading = false;
        });
      } else {
        setState(() {
          _weatherDescription = "City not found";
          _temperature = null;
          _advice = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherDescription = "Error fetching weather";
        _temperature = null;
        _advice = null;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather & Advice')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Enter your city',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final city = _locationController.text.trim();
                if (city.isNotEmpty) {
                  fetchWeather(city);
                }
              },
              child: const Text('Check Weather'),
            ),
            const SizedBox(height: 24),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading && _weatherDescription != null)
              Column(
                children: [
                  Text(
                    'Weather: $_weatherDescription',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Temperature: ${_temperature?.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Advice: $_advice',
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}