import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../l10n/strings.dart';
import '../data/cameroon_menus.dart';
import '../widgets/section_card.dart';

class HydrationNutritionScreen extends StatefulWidget {
  const HydrationNutritionScreen({super.key});
  @override
  State<HydrationNutritionScreen> createState() =>
      _HydrationNutritionScreenState();
}

class _HydrationNutritionScreenState extends State<HydrationNutritionScreen> {
  Box get _box => Hive.box('app_cache');

  static final _epoch = DateTime.utc(2024, 1, 1);
  int get _weekIndex =>
      DateTime.now().toUtc().difference(_epoch).inDays ~/ 7;

  String _key(int day) => 'menu_${_weekIndex}_$day';

  Map<String, String> _menuFor(int dayIdx, bool fr) {
    final ov = _box.get(_key(dayIdx));
    if (ov is Map) {
      return {
        'b': (ov['b'] ?? '').toString(),
        'l': (ov['l'] ?? '').toString(),
        'd': (ov['d'] ?? '').toString(),
        's': (ov['s'] ?? '').toString(),
      };
    }
    final base =
        kCameroonMenus[(_weekIndex * 7 + dayIdx) % kCameroonMenus.length];
    return {
      'b': base.breakfast.t(fr),
      'l': base.lunch.t(fr),
      'd': base.dinner.t(fr),
      's': base.snack.t(fr),
    };
  }

  Future<void> _edit(int dayIdx, String dayLabel) async {
    final l = context.l10n;
    final m = _menuFor(dayIdx, l.fr);
    final b = TextEditingController(text: m['b']);
    final lu = TextEditingController(text: m['l']);
    final d = TextEditingController(text: m['d']);
    final s = TextEditingController(text: m['s']);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${l.editDayMenu} · $dayLabel',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
                controller: b,
                decoration: InputDecoration(labelText: l.breakfast)),
            const SizedBox(height: 10),
            TextField(
                controller: lu,
                decoration: InputDecoration(labelText: l.lunch)),
            const SizedBox(height: 10),
            TextField(
                controller: d,
                decoration: InputDecoration(labelText: l.dinner)),
            const SizedBox(height: 10),
            TextField(
                controller: s,
                decoration: InputDecoration(labelText: l.snack)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                _box.put(_key(dayIdx), {
                  'b': b.text.trim(),
                  'l': lu.text.trim(),
                  'd': d.text.trim(),
                  's': s.text.trim(),
                });
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.menuSaved)));
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  void _resetWeek() {
    for (var i = 0; i < 7; i++) {
      _box.delete(_key(i));
    }
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.menuReset)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return Scaffold(
      appBar: AppBar(title: Text(l.hydrationNutritionTitle)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.weekMenu, style: tt.titleMedium),
                    Text(l.weekOf(l.formatDayDate(monday)),
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12.5)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _resetWeek,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(l.resetWeekMenu),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(7, (i) {
            final dayDate = monday.add(Duration(days: i));
            final dayLabel = l.dayName(dayDate.weekday);
            final m = _menuFor(i, l.fr);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SectionCard(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primary.withValues(alpha: 0.12),
                      child: Text('${dayDate.day}',
                          style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                    title: Text(dayLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(m['l']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    children: [
                      _meal(cs, Icons.free_breakfast_outlined, l.breakfast,
                          m['b']!),
                      _meal(cs, Icons.lunch_dining_outlined, l.lunch, m['l']!),
                      _meal(cs, Icons.dinner_dining_outlined, l.dinner,
                          m['d']!),
                      _meal(cs, Icons.bakery_dining_outlined, l.snack, m['s']!),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _edit(i, dayLabel),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(l.editMenu),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          _tips(l.hydrationGoals, l.hydrationGoalsItems),
          const SizedBox(height: 12),
          _tips(l.foodsHelp, l.foodsHelpItems),
          const SizedBox(height: 12),
          _tips(l.avoid, l.avoidItems),
        ],
      ),
    );
  }

  Widget _meal(ColorScheme cs, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: '$label : ',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: value.isEmpty ? '—' : value),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _tips(String title, List<String> items) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          ...items.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(t),
              )),
        ],
      ),
    );
  }
}
