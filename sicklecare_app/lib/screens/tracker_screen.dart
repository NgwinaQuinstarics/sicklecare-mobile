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
    final pendingSync = context.watch<TrackerProvider>().pendingSyncCount;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.trackerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SectionCard(
            child: Row(
              children: [
                Icon(
                  pendingSync == 0
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_sync_outlined,
                  color: pendingSync == 0 ? cs.primary : cs.tertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.tr('Offline-first health log',
                            'Journal santé hors ligne'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pendingSync == 0
                            ? l.tr(
                                'Entries save on this phone first, then sync when internet is available.',
                                'Les entrées sont d’abord enregistrées sur ce téléphone, puis synchronisées quand internet est disponible.',
                              )
                            : l.tr(
                                '$pendingSync entries waiting for internet. Nothing is lost.',
                                '$pendingSync entrée(s) en attente d’internet. Rien n’est perdu.',
                              ),
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                if (pendingSync > 0)
                  IconButton(
                    tooltip: l.retry,
                    icon: const Icon(Icons.sync),
                    onPressed: () =>
                        context.read<TrackerProvider>().syncPending(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
                Text(l.tr('Water you drank', 'Eau bue'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  l.tr(
                    'Choose the amount in cups or bottles. The app saves it in ml for your history.',
                    "Choisis en verres ou bouteilles. L'app enregistre en ml pour ton historique.",
                  ),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 8.0;
                    final width = (constraints.maxWidth - gap) / 2;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: _waterOptions
                          .map((o) => SizedBox(
                                width: width,
                                child: _WaterOptionTile(
                                  option: o,
                                  selected: _hydration == o.ml,
                                  onTap: () =>
                                      setState(() => _hydration = o.ml),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: (_hydration / 3000).clamp(0.0, 1.0),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 8),
                Text(
                  l.tr(
                    '${_formatLitres(_hydration)} selected toward a 2.5-3 L daily goal.',
                    '${_formatLitres(_hydration)} choisi sur un objectif quotidien de 2,5-3 L.',
                  ),
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
                            label:
                                Text(m, style: const TextStyle(fontSize: 20)),
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

const _waterOptions = [
  _WaterOption(250, '1 cup', '250 ml'),
  _WaterOption(500, '2 cups', '500 ml'),
  _WaterOption(750, '3 cups', '750 ml'),
  _WaterOption(1000, '1 bottle', '1 L'),
  _WaterOption(1500, '1.5 bottles', '1.5 L'),
  _WaterOption(2000, '2 bottles', '2 L'),
  _WaterOption(3000, 'Daily goal', '3 L'),
];

class _WaterOption {
  final int ml;
  final String label;
  final String amount;
  const _WaterOption(this.ml, this.label, this.amount);
}

class _WaterOptionTile extends StatelessWidget {
  final _WaterOption option;
  final bool selected;
  final VoidCallback onTap;
  const _WaterOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.local_drink_outlined,
                color: selected ? cs.primary : cs.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(option.amount,
                        style: TextStyle(
                            color: selected
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                            fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatLitres(int ml) {
  if (ml < 1000) return '$ml ml';
  final litres = ml / 1000;
  return '${litres.toStringAsFixed(litres == litres.roundToDouble() ? 0 : 1)} L';
}
