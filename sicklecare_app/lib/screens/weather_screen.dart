import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/strings.dart';
import '../services/weather_service.dart';
import '../widgets/section_card.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherSnapshot? _snap;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final s = await WeatherService.current();
    if (!mounted) return;
    setState(() {
      _snap = s;
      _loading = false;
      _failed = s == null;
    });
  }

  String _advice(WeatherSnapshot s, L10n l) {
    if (s.tempC < 12) return l.adviceCold;
    if (s.tempC > 32) return l.adviceHot;
    if (s.humidity < 30) return l.adviceDry;
    return l.adviceNormal;
  }

  IconData _icon(String summary) {
    final s = summary.toLowerCase();
    if (s.contains('clear')) return Icons.wb_sunny_outlined;
    if (s.contains('cloud') || s.contains('overcast')) {
      return Icons.wb_cloudy_outlined;
    }
    if (s.contains('rain') || s.contains('shower')) return Icons.grain;
    if (s.contains('snow')) return Icons.ac_unit;
    if (s.contains('fog')) return Icons.foggy;
    if (s.contains('thunder')) return Icons.thunderstorm_outlined;
    return Icons.cloud_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.weatherTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
              ? _ErrorView(
                  message: l.weatherError,
                  retryLabel: l.retry,
                  settingsLabel: l.openAppSettings,
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      SectionCard(
                        padding: const EdgeInsets.all(22),
                        gradient: LinearGradient(
                          colors: [
                            cs.primary,
                            Color.lerp(cs.primary, Colors.black, 0.25)!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_snap!.tempC.toStringAsFixed(0)}°C',
                                      style: tt.displayMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                                  Text(l.weatherSummary(_snap!.summary),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ],
                              ),
                            ),
                            Icon(_icon(_snap!.summary),
                                size: 64, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                                icon: Icons.water_drop_outlined,
                                label: l.humidity,
                                value:
                                    '${_snap!.humidity.toStringAsFixed(0)}%'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Metric(
                                icon: Icons.air,
                                label: l.wind,
                                value:
                                    '${_snap!.windKph.toStringAsFixed(0)} km/h'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.tips_and_updates_outlined,
                                color: cs.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.todaysTip, style: tt.titleMedium),
                                  const SizedBox(height: 6),
                                  Text(_advice(_snap!, l)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Metric(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(height: 10),
          Text(value,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String retryLabel;
  final String settingsLabel;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.message,
    required this.retryLabel,
    required this.settingsLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 56, color: cs.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Geolocator.openAppSettings(),
              child: Text(settingsLabel),
            ),
          ],
        ),
      ),
    );
  }
}
