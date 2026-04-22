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

  List<double> hourlyTemps = [];
  List<double> dailyTemps = [];

  bool isLoading = false;

  final List<String> locations = [
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

  Future<void> fetchWeather(String location) async {
    setState(() => isLoading = true);

    try {
      final currentUrl =
          "https://api.openweathermap.org/data/2.5/weather?q=$location,CM&appid=$apiKey&units=metric";

      final forecastUrl =
          "https://api.openweathermap.org/data/2.5/forecast?q=$location,CM&appid=$apiKey&units=metric";

      final currentRes = await http.get(Uri.parse(currentUrl));
      final forecastRes = await http.get(Uri.parse(forecastUrl));

      if (currentRes.statusCode == 200 && forecastRes.statusCode == 200) {
        final current = jsonDecode(currentRes.body);
        final forecast = jsonDecode(forecastRes.body);

        List hourly = forecast['list'].take(8).toList();

        List daily = [];
        for (int i = 0; i < forecast['list'].length; i += 8) {
          daily.add(forecast['list'][i]);
        }

        setState(() {
          city = current['name'];
          temp = (current['main']['temp'] as num).toDouble();
          condition = current['weather'][0]['main'];
          icon = current['weather'][0]['icon'];

          hourlyTemps = hourly
              .map((e) => (e['main']['temp'] as num).toDouble())
              .toList();

          dailyTemps = daily
              .map((e) => (e['main']['temp'] as num).toDouble())
              .toList();
        });
      } else {
        showMessage("Failed to load weather");
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

  LinearGradient gradient() {
    if (condition.toLowerCase().contains("rain")) {
      return const LinearGradient(
        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return const LinearGradient(
      colors: [Color(0xFFF4F7FA), Color(0xFFE2E8F0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text("Weather"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E40AF)),
      ),

      body: Container(
        decoration: BoxDecoration(gradient: gradient()),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // LOCATION SELECTOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Location",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DropdownButton<String>(
                      value: selectedCity,
                      underline: Container(),
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

                const SizedBox(height: 20),

                if (isLoading)
                  const Center(child: CircularProgressIndicator()),

                if (!isLoading && city.isNotEmpty) ...[
                  // WEATHER CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          city,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Image.network(
                          "https://openweathermap.org/img/wn/$icon@2x.png",
                        ),

                        Text(
                          "${temp.toStringAsFixed(1)}°C",
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),

                        Text(
                          condition,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "24h Temperature",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(show: false),
                        gridData: FlGridData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              hourlyTemps.length,
                              (i) => FlSpot(
                                  i.toDouble(), hourlyTemps[i]),
                            ),
                            isCurved: true,
                            barWidth: 3,
                            color: const Color(0xFF1E40AF),
                            dotData: FlDotData(show: false),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "7-Day Forecast",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...List.generate(dailyTemps.length, (i) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text("Day ${i + 1}"),
                        trailing: Text(
                          "${dailyTemps[i].toStringAsFixed(1)}°C",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}