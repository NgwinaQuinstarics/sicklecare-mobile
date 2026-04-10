import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../widgets/app_drawer.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final String apiKey = "dd211ba3e0176d8198fce34c96413e3c";

  String city = "";
  double temp = 0;
  String condition = "";
  String icon = "";

  List hourlyTemps = [];
  List dailyTemps = [];

  bool isLoading = false;

  // 🇨🇲 FULL CAMEROON LIST
  final List<String> locations = [
    // Regions capitals
    "Douala",
    "Yaounde",
    "Bamenda",
    "Buea",
    "Garoua",
    "Maroua",
    "Ngaoundere",
    "Ebolowa",
    "Bertoua",
    "Bafoussam",

    // towns
    "Limbe",
    "Kribi",
    "Kumba",
    "Dschang",
    "Foumban",
    "Tiko",
    "Sangmelima",
    "Meiganga",
    "Mokolo",
  ];

  String selectedCity = "Douala";

  @override
  void initState() {
    super.initState();
    fetchWeather(selectedCity);
  }

  // 🌍 FETCH FULL DATA (current + forecast)
  Future<void> fetchWeather(String location) async {
    setState(() => isLoading = true);

    try {
      // CURRENT
      final currentUrl =
          "https://api.openweathermap.org/data/2.5/weather?q=$location,CM&appid=$apiKey&units=metric";

      final forecastUrl =
          "https://api.openweathermap.org/data/2.5/forecast?q=$location,CM&appid=$apiKey&units=metric";

      final currentRes = await http.get(Uri.parse(currentUrl));
      final forecastRes = await http.get(Uri.parse(forecastUrl));

      if (currentRes.statusCode == 200 &&
          forecastRes.statusCode == 200) {
        final current = jsonDecode(currentRes.body);
        final forecast = jsonDecode(forecastRes.body);

        // HOURLY (next 8 = ~24h)
        List hourly = forecast['list'].take(8).toList();

        // DAILY (every 8 = 24h)
        List daily = [];
        for (int i = 0; i < forecast['list'].length; i += 8) {
          daily.add(forecast['list'][i]);
        }

        setState(() {
          city = current['name'];
          temp = (current['main']['temp'] as num).toDouble();
          condition = current['weather'][0]['main'];
          icon = current['weather'][0]['icon'];

          hourlyTemps =
              hourly.map((e) => (e['main']['temp'] as num).toDouble()).toList();

          dailyTemps =
              daily.map((e) => (e['main']['temp'] as num).toDouble()).toList();
        });
      } else {
        showMessage("Error loading weather");
      }
    } catch (e) {
      showMessage("Network error");
    }

    setState(() => isLoading = false);
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // 🎨 GRADIENT
  LinearGradient gradient() {
    if (condition.toLowerCase().contains("rain")) {
      return const LinearGradient(
          colors: [Colors.blueGrey, Colors.black]);
    }
    return const LinearGradient(
        colors: [Colors.blue, Colors.deepPurple]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: gradient()),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [

                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Weather",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),

                    DropdownButton<String>(
                      value: selectedCity,
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      items: locations.map((loc) {
                        return DropdownMenuItem(
                          value: loc,
                          child: Text(loc),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedCity = value);
                          fetchWeather(value);
                        }
                      },
                    )
                  ],
                ),

                const SizedBox(height: 30),

                if (isLoading)
                  const Center(child: CircularProgressIndicator()),

                if (!isLoading && city.isNotEmpty) ...[

                  // CURRENT
                  Text(city,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 26)),

                  Row(
                    children: [
                      Image.network(
                          "https://openweathermap.org/img/wn/$icon@2x.png"),
                      Text("${temp.toStringAsFixed(1)}°C",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 40))
                    ],
                  ),

                  Text(condition,
                      style: const TextStyle(color: Colors.white70)),

                  const SizedBox(height: 20),

                  // 📊 HOURLY GRAPH
                  const Text("Hourly",
                      style:
                          TextStyle(color: Colors.white, fontSize: 18)),

                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              hourlyTemps.length,
                              (i) => FlSpot(i.toDouble(), hourlyTemps[i]),
                            ),
                            isCurved: true,
                            dotData: FlDotData(show: true),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 📅 7 DAY FORECAST
                  const Text("7-Day Forecast",
                      style:
                          TextStyle(color: Colors.white, fontSize: 18)),

                  const SizedBox(height: 10),

                  ...List.generate(dailyTemps.length, (i) {
                    return Card(
                      child: ListTile(
                        title: Text("Day ${i + 1}"),
                        trailing: Text(
                            "${dailyTemps[i].toStringAsFixed(1)}°C"),
                      ),
                    );
                  })
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}