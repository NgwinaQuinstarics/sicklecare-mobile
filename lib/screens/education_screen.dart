import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});
  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  String _filter = 'all';

  final _articles = [
    {'title': 'Understanding Sickle Cell Disease: A Complete Guide', 'excerpt': 'Everything you need to know about SCD genetics, symptoms, and management.', 'category': 'disease',       'min': 8,  'emoji': '🔬', 'bg': AppColors.blueLight,   'color': AppColors.blue},
    {'title': 'Iron-Rich Foods That Support Sickle Cell Health',      'excerpt': 'Diet plays a huge role. The best iron-rich foods for SCD patients.',               'category': 'nutrition',     'min': 5,  'emoji': '🥗', 'bg': AppColors.greenLight,  'color': AppColors.green},
    {'title': 'How to Manage a Vaso-Occlusive Crisis at Home',        'excerpt': 'Step-by-step guide for managing pain episodes safely at home.',                     'category': 'crisis',        'min': 6,  'emoji': '⚡', 'bg': AppColors.amberLight,  'color': AppColors.amber},
    {'title': 'Living Fully with SCD: Mental Wellness Strategies',    'excerpt': 'Chronic illness affects the mind. How to protect your mental health.',              'category': 'mental-health', 'min': 7,  'emoji': '🧠', 'bg': AppColors.purpleLight, 'color': AppColors.purple},
    {'title': 'Exercise Guidelines for People with Sickle Cell',      'excerpt': 'How to stay active safely without triggering a crisis.',                            'category': 'lifestyle',     'min': 4,  'emoji': '🌱', 'bg': AppColors.tealLight,   'color': AppColors.teal},
    {'title': 'Hydroxyurea: How It Works and What to Expect',         'excerpt': 'The most prescribed SCD medication explained clearly.',                             'category': 'disease',       'min': 6,  'emoji': '💊', 'bg': AppColors.blueLight,   'color': AppColors.blue},
    {'title': 'Why Hydration Is Critical for SCD Patients',           'excerpt': 'Water is literally life-saving for sickle cell patients. Here\'s why.',            'category': 'lifestyle',     'min': 3,  'emoji': '💧', 'bg': AppColors.tealLight,   'color': AppColors.teal},
  ];

  final _filters = [
    {'key': 'all',          'label': 'All'},
    {'key': 'disease',      'label': 'Disease'},
    {'key': 'nutrition',    'label': 'Nutrition'},
    {'key': 'lifestyle',    'label': 'Lifestyle'},
    {'key': 'crisis',       'label': 'Crisis'},
    {'key': 'mental-health','label': 'Mental Health'},
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _filter == 'all'
        ? _articles
        : _articles.where((a) => a['category'] == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Education 📚', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy)),
              Text('${_articles.length} articles available', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final active = f['key'] == _filter;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f['key']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppColors.blue : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? AppColors.blue : AppColors.border, width: 2),
                        ),
                        child: Text(f['label']!, style: GoogleFonts.nunito(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppColors.muted)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              itemCount: visible.length,
              itemBuilder: (_, i) {
                final a = visible[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card, borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: AppColors.blue, blurRadius: 10, offset: const Offset(0,4))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: a['bg'] as Color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Center(child: Text(a['emoji'] as String, style: const TextStyle(fontSize: 48))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: (a['color'] as Color),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (a['category'] as String).toUpperCase().replaceAll('-', ' '),
                            style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w800,
                              color: a['color'] as Color, letterSpacing: 0.6)),
                        ),
                        const SizedBox(height: 7),
                        Text(a['title'] as String,
                          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900,
                            color: AppColors.navy, height: 1.3)),
                        const SizedBox(height: 5),
                        Text(a['excerpt'] as String,
                          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted, height: 1.5),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text('📖 ${a['min']} min read',
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
                      ]),
                    ),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
