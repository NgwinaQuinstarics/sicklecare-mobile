import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

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
  List<double> dailyTemps  = [];

  bool isLoading = false;

  final List<String> locations = [
    "Douala","Yaounde","Bamenda","Buea","Garoua","Maroua",
    "Ngaoundere","Ebolowa","Bertoua","Bafoussam","Limbe",
    "Kribi","Kumba","Dschang","Foumban","Tiko",
    "Sangmelima","Meiganga","Mokolo",
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
      final currentRes = await http.get(Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$location,CM&appid=$apiKey&units=metric",
      ));
      final forecastRes = await http.get(Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast?q=$location,CM&appid=$apiKey&units=metric",
      ));

      if (currentRes.statusCode == 200 && forecastRes.statusCode == 200) {
        final current  = jsonDecode(currentRes.body);
        final forecast = jsonDecode(forecastRes.body);

        final hourly = forecast['list'].take(8).toList();
        final daily  = <dynamic>[];
        for (int i = 0; i < forecast['list'].length; i += 8) {
          daily.add(forecast['list'][i]);
        }

        setState(() {
          city      = current['name'];
          temp      = (current['main']['temp'] as num).toDouble();
          condition = current['weather'][0]['main'];
          icon      = current['weather'][0]['icon'];
          hourlyTemps = hourly.map((e) => (e['main']['temp'] as num).toDouble()).toList();
          dailyTemps  = daily.map((e)  => (e['main']['temp'] as num).toDouble()).toList();
        });
      } else {
        _showMsg("Failed to load weather");
      }
    } catch (_) {
      _showMsg("Network error");
    }
    setState(() => isLoading = false);
  }

  void _showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool get _isRainy => condition.toLowerCase().contains("rain");
  bool get _isCloudy => condition.toLowerCase().contains("cloud");

  Color get _primaryColor => _isRainy
      ? const Color(0xFF1565C0)
      : _isCloudy
          ? const Color(0xFF455A64)
          : const Color(0xFFE53935);

  List<Color> get _bgGradient => _isRainy
      ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
      : _isCloudy
          ? [const Color(0xFF546E7A), const Color(0xFF78909C)]
          : [const Color(0xFFFFEBEE), const Color(0xFFE3F2FD)];

  String get _weatherEmoji {
    final c = condition.toLowerCase();
    if (c.contains('rain'))  return '🌧️';
    if (c.contains('cloud')) return '☁️';
    if (c.contains('snow'))  return '❄️';
    if (c.contains('storm')) return '⛈️';
    if (c.contains('fog') || c.contains('mist')) return '🌫️';
    return '☀️';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Weather Forecast',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildLocationSelector(),
                    const SizedBox(height: 20),
                    if (city.isNotEmpty) ...[
                      _buildMainCard(),
                      const SizedBox(height: 20),
                      _buildScdAlert(),
                      const SizedBox(height: 20),
                      _buildHourlyChart(),
                      const SizedBox(height: 20),
                      _buildDailyForecast(),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  // ── Location Selector ──────────────────────────────────────────────────────

  Widget _buildLocationSelector() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Color(0xFFE53935), size: 20),
            const SizedBox(width: 8),
            const Text('Location',
                style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            DropdownButton<String>(
              value: selectedCity,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF1E40AF)),
              style: const TextStyle(
                  color: Color(0xFF1E40AF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              items: locations
                  .map((loc) =>
                      DropdownMenuItem(value: loc, child: Text(loc)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => selectedCity = v);
                  fetchWeather(v);
                }
              },
            ),
          ],
        ),
      );

  // ── Main Weather Card ──────────────────────────────────────────────────────

  Widget _buildMainCard() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Text(city,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A237E))),
            const SizedBox(height: 6),
            Text(_weatherEmoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 4),
            Image.network(
              "https://openweathermap.org/img/wn/$icon@2x.png",
              width: 60, height: 60,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            Text(
              "${temp.toStringAsFixed(1)}°C",
              style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: _primaryColor),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(condition,
                  style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
          ],
        ),
      );

  // ── SCD Alert Banner ───────────────────────────────────────────────────────

  Widget _buildScdAlert() {
    String msg;
    Color bg;
    Color fg;
    IconData ico;

    if (temp < 18) {
      msg = '⚠️ Cold weather alert — SCD patients should stay warm and avoid exposure.';
      bg  = const Color(0xFFE3F2FD);
      fg  = const Color(0xFF1565C0);
      ico = Icons.ac_unit_rounded;
    } else if (temp > 35) {
      msg = '🌡️ High heat alert — drink extra water and rest in the shade.';
      bg  = const Color(0xFFFFEBEE);
      fg  = const Color(0xFFE53935);
      ico = Icons.thermostat_rounded;
    } else {
      msg = '✅ Temperature is comfortable. Stay hydrated and keep warm at night.';
      bg  = const Color(0xFFE8F5E9);
      fg  = const Color(0xFF2E7D32);
      ico = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(ico, color: fg, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: fg, fontSize: 13, height: 1.5,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Hourly Chart ───────────────────────────────────────────────────────────

  Widget _buildHourlyChart() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('24h Temperature',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A237E))),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: false),
                  gridData: FlGridData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        hourlyTemps.length,
                        (i) => FlSpot(i.toDouble(), hourlyTemps[i]),
                      ),
                      isCurved: true,
                      barWidth: 3,
                      color: _primaryColor,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _primaryColor.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  // ── Daily Forecast ─────────────────────────────────────────────────────────

  Widget _buildDailyForecast() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('7-Day Forecast',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A237E))),
            const SizedBox(height: 12),
            ...List.generate(dailyTemps.length, (i) {
              final t = dailyTemps[i];
              final dayColor = t < 18
                  ? const Color(0xFF1565C0)
                  : t > 35
                      ? const Color(0xFFE53935)
                      : const Color(0xFF2E7D32);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Color(0xFF1E40AF), size: 18),
                    const SizedBox(width: 12),
                    Text('Day ${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A237E),
                            fontSize: 14)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: dayColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${t.toStringAsFixed(1)}°C",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: dayColor,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
}