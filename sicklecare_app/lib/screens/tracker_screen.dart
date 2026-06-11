import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../providers/tracker_provider.dart';
import '../models/tracker_entry.dart';
import '../widgets/section_card.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  double _pain = 2;
  int _hydration = 500;
  String _mood = '🙂';
  final _notes = TextEditingController();

  Future<void> _save() async {
    final l = context.l10n;
    final e = TrackerEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      painLevel: _pain.round(),
      hydrationMl: _hydration,
      mood: _mood,
      notes: _notes.text.trim(),
    );
    await context.read<TrackerProvider>().add(e);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.savedEntry)),
    );
    _notes.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.trackerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.painLevel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Slider(
                  value: _pain,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: _pain.round().toString(),
                  onChanged: (v) => setState(() => _pain = v),
                ),
                Text(l.level(_pain.round())),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.water,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [250, 500, 750, 1000, 1500, 2000]
                      .map((v) => ChoiceChip(
                            label: Text('$v ml'),
                            selected: _hydration == v,
                            onSelected: (_) => setState(() => _hydration = v),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.mood,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: ['😀', '🙂', '😐', '😕', '😣']
                      .map((m) => ChoiceChip(
                            label: Text(m, style: const TextStyle(fontSize: 20)),
                            selected: _mood == m,
                            onSelected: (_) => setState(() => _mood = m),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: TextField(
              controller: _notes,
              decoration: InputDecoration(
                labelText: l.notes,
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: _save, child: Text(l.saveEntry)),
        ],
      ),
    );
  }
}
