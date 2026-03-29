import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../widgets/sc_card.dart';
import '../widgets/sc_button.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});
  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  int _tab = 0;
  final _tabs = ['🩸 Period', '⚡ Pain', '🌡 Symptoms'];

  // Calendar data for March 2026
  // type: 0=normal, 1=period, 2=predicted, 3=fertile, 4=today
  final _calTypes = [0,0,1,1,1,1,1, 0,0,0,0,0,3,3, 3,3,3,0,0,0,0, 0,0,4,2,2,2,2, 2,0,0];

  int _painLevel = 5;
  final _selectedLocs = <String>{};
  final _locations = ['Chest','Back','Joints','Abdomen','Head','Legs','Arms'];

  final _painLogs = [
    {'level': 6, 'loc': 'Chest, Joints', 'note': 'Shortness of breath', 'date': 'Yesterday', 'color': AppColors.rose},
    {'level': 3, 'loc': 'Back',           'note': 'Mild discomfort',     'date': 'Mar 21',    'color': AppColors.amber},
    {'level': 0, 'loc': '—',              'note': 'Feeling great!',       'date': 'Mar 19',    'color': AppColors.green},
  ];

  final _symptoms = [
    {'emoji': '😰', 'label': 'Fatigue / Tiredness',         'checked': true},
    {'emoji': '🤕', 'label': 'Bone or joint pain',          'checked': true},
    {'emoji': '😮‍💨','label': 'Shortness of breath',         'checked': false},
    {'emoji': '🤢', 'label': 'Nausea',                      'checked': false},
    {'emoji': '🌡️', 'label': 'Fever',                       'checked': false},
    {'emoji': '👁️', 'label': 'Yellowing of eyes (jaundice)','checked': true},
  ];

  Color _dayColor(int type) => switch (type) {
    1 => AppColors.rose,
    2 => AppColors.roseLight,
    3 => AppColors.greenLight,
    4 => AppColors.blue,
    _ => AppColors.background,
  };
  Color _dayText(int type) => (type == 1 || type == 4) ? Colors.white : AppColors.navy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Health Tracker', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy)),
              Text('Period + Health Logs', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final active = i == _tab;
                    return GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? AppColors.blue : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? AppColors.blue : AppColors.border, width: 2),
                        ),
                        child: Text(_tabs[i], style: GoogleFonts.nunito(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppColors.muted)),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              child: _tab == 0 ? _buildPeriod() : _tab == 1 ? _buildPain(context) : _buildSymptoms(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPeriod() {
    final headers = ['S','M','T','W','T','F','S'];
    return ScCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('March 2026', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.navy)),
          Row(children: [
            _NavBtn('‹'), const SizedBox(width: 6), _NavBtn('›'),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(children: headers.map((h) => Expanded(
          child: Center(child: Text(h, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted))))).toList()),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 0),
          itemCount: 31,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: _dayColor(_calTypes[i]),
                borderRadius: BorderRadius.circular(10),
                border: _calTypes[i] == 2
                    ? Border.all(color: AppColors.rose, width: 1.5, style: BorderStyle.solid)
                    : null,
              ),
              child: Center(child: Text('${i + 1}',
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: _dayText(_calTypes[i])))),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 14, children: [
          _Legend(AppColors.rose,      'Period'),
          _Legend(AppColors.roseLight, 'Predicted'),
          _Legend(AppColors.greenLight,'Fertile'),
        ]),
      ]),
    );
  }

  Widget _buildPain(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Pain Log', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.navy)),
        GestureDetector(
          onTap: () => _showLogPain(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(10)),
            child: Text('+ Log Pain', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      ScCard(
        child: Column(children: _painLogs.asMap().entries.map((e) {
          final log = e.value;
          final color = log['color'] as Color;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: e.key < _painLogs.length - 1
                  ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${log['level']}', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1)),
                  Text('/10', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.muted)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${log['loc']}', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy)),
                Text('${log['note']}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted, height: 1.4)),
              ])),
              Text('${log['date']}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
            ]),
          );
        }).toList()),
      ),
    ]);
  }

  Widget _buildSymptoms() {
    return ScCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SCD SYMPTOMS', style: GoogleFonts.nunito(
          fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.7)),
        const SizedBox(height: 14),
        ..._symptoms.map((s) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Text(s['emoji'] as String, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(s['label'] as String,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.navy, fontWeight: FontWeight.w500))),
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: (s['checked'] as bool) ? AppColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (s['checked'] as bool) ? AppColors.green : AppColors.border, width: 2),
              ),
              child: (s['checked'] as bool)
                  ? const Center(child: Text('✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)))
                  : null,
            ),
          ]),
        )),
      ]),
    );
  }

  void _showLogPain(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 36),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Log Pain Episode', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy)),
            const SizedBox(height: 18),
            Text('Pain Level: $_painLevel/10', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyMid)),
            Slider(
              value: _painLevel.toDouble(),
              min: 0, max: 10, divisions: 10,
              activeColor: AppColors.rose,
              onChanged: (v) => setSheet(() => _painLevel = v.round()),
            ),
            Text('Location(s)', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navyMid)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: _locations.map((loc) {
              final sel = _selectedLocs.contains(loc);
              return GestureDetector(
                onTap: () => setSheet(() => sel ? _selectedLocs.remove(loc) : _selectedLocs.add(loc)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.rose : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppColors.rose : AppColors.border, width: 2),
                  ),
                  child: Text(loc, style: GoogleFonts.nunito(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.muted)),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            ScButton(label: 'Save Pain Log', onPressed: () => Navigator.pop(context)),
            const SizedBox(height: 8),
            ScButton(label: 'Cancel', onPressed: () => Navigator.pop(context), variant: BtnVariant.ghost),
          ]),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  const _NavBtn(this.label);
  @override
  Widget build(BuildContext context) => Container(
    width: 30, height: 30,
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
    child: Center(child: Text(label, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy))),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 5),
    Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600)),
  ]);
}
