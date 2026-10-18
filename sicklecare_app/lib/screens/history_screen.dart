import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../l10n/strings.dart';
import '../models/tracker_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/tracker_provider.dart';
import '../services/care_plan_service.dart';
import '../utils/date_utils.dart';
import '../widgets/section_card.dart';
import '../widgets/empty_state.dart';

const _waterColor = Color(0xFF38BDF8); // sky blue

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _moodLabel(String m, bool fr) {
    switch (m) {
      case '😀':
        return fr ? 'Très bien' : 'Great';
      case '🙂':
        return fr ? 'Bien' : 'Good';
      case '😐':
        return fr ? 'Moyen' : 'Okay';
      case '😕':
        return fr ? 'Bas' : 'Low';
      case '😣':
        return fr ? 'Difficile' : 'Hard';
      default:
        return '-';
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    List<TrackerEntry> entries,
    L10n l,
  ) async {
    final auth = context.read<AuthProvider>();
    final reminders = context.read<ReminderProvider>();
    final profile = auth.profile ?? const <String, dynamic>{};
    final contacts = CarePlanService.getEmergencyContacts();
    final name =
        ((profile['name'] ?? auth.user?.displayName) ?? '').toString().trim();
    final genotype = (profile['genotype'] ?? '').toString().trim();
    final phone = (profile['phone'] ?? '').toString().trim();
    final email = auth.user?.email ?? (profile['email'] ?? '').toString();
    final activeReminders =
        reminders.items.where((r) => r.enabled).toList(growable: false);
    final hydrationReminder = reminders.hydrationIntervalMinutes;

    final now = DateTime.now();
    final recent = entries
        .where((e) => now.difference(e.date).inDays <= 30)
        .toList(growable: false);
    final source = recent.isEmpty ? entries : recent;
    final avgPain = source.isEmpty
        ? 0.0
        : source.fold<double>(0, (sum, e) => sum + e.painLevel) / source.length;
    final highestPain = source.isEmpty
        ? 0
        : source.map((e) => e.painLevel).reduce((a, b) => a > b ? a : b);
    final avgHydration = source.isEmpty
        ? 0
        : (source.fold<int>(0, (sum, e) => sum + e.hydrationMl) / source.length)
            .round();
    final redFlags = <String>[
      if (highestPain >= 8) 'Pain reached $highestPain/10 in the last 30 days',
      if (avgHydration < 1500)
        'Average logged hydration is below 1.5 L per check-in',
      if (entries.isEmpty) 'No check-ins recorded yet',
    ];
    final doc = pw.Document();
    final rows = <List<String>>[
      for (final e in entries.take(45))
        [
          fmtDateTime(e.date),
          '${e.painLevel}/10',
          '${e.hydrationMl}',
          _moodLabel(e.mood, l.fr),
          e.notes,
        ],
    ];
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          pw.Text(
              l.fr ? 'Rapport medecin SickleCare' : 'SickleCare Doctor Report',
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            (l.fr ? 'Généré le ' : 'Generated on ') +
                fmtDateTime(DateTime.now()),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            l.fr
                ? 'Ce rapport resume les donnees saisies par le patient. Il ne remplace pas un avis medical.'
                : 'This report summarizes patient-entered data. It does not replace medical advice.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          _pdfSectionTitle(l.fr ? 'Patient' : 'Patient'),
          _pdfKeyValueTable([
            [l.name, name.isEmpty ? '-' : name],
            ['Email', email.isEmpty ? '-' : email],
            [l.genotype, genotype.isEmpty ? '-' : genotype],
            [l.phone, phone.isEmpty ? '-' : phone],
          ]),
          pw.SizedBox(height: 12),
          _pdfSectionTitle(l.fr ? 'Resume 30 jours' : '30-day summary'),
          _pdfKeyValueTable([
            [l.tr('Check-ins', 'Check-ins'), '${source.length}'],
            [
              l.tr('Average pain', 'Douleur moyenne'),
              '${avgPain.toStringAsFixed(1)}/10'
            ],
            [l.tr('Highest pain', 'Douleur maximale'), '$highestPain/10'],
            [
              l.tr('Average hydration', 'Hydratation moyenne'),
              '$avgHydration ml'
            ],
          ]),
          pw.SizedBox(height: 12),
          _pdfSectionTitle(l.tr('Safety notes', 'Notes de securite')),
          if (redFlags.isEmpty)
            pw.Text(l.tr('No red flag from logged data.',
                'Aucun signe d alerte dans les donnees enregistrees.'))
          else
            ...redFlags.map((flag) => pw.Bullet(text: flag)),
          pw.Bullet(
            text: l.tr(
              'Emergency red flags: chest pain, breathing trouble, high fever, confusion, one-sided weakness, or severe pain not improving.',
              'Signes d urgence: douleur thoracique, difficulte a respirer, forte fievre, confusion, faiblesse d un cote, ou douleur severe qui ne s ameliore pas.',
            ),
          ),
          pw.SizedBox(height: 16),
          _pdfSectionTitle(l.tr('Care plan', 'Plan de soin')),
          if (hydrationReminder != null)
            pw.Bullet(
              text: l.tr(
                'Hydration reminder: every $hydrationReminder minutes',
                'Rappel hydratation: toutes les $hydrationReminder minutes',
              ),
            ),
          if (activeReminders.isEmpty)
            pw.Text(l.tr('No active custom reminders.',
                'Aucun rappel personnalise actif.'))
          else
            ...activeReminders.take(8).map(
                  (r) => pw.Bullet(
                    text:
                        '${r.title} - ${fmtTime(r.time)}${r.repeatDaily ? ' daily' : ''}',
                  ),
                ),
          if (contacts.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(l.tr('Emergency contacts', 'Contacts d urgence'),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...contacts
                .map((c) => pw.Bullet(text: '${c.displayName}: ${c.detail}')),
          ],
          pw.SizedBox(height: 16),
          _pdfSectionTitle(l.tr('Recent check-ins', 'Check-ins recents')),
          pw.TableHelper.fromTextArray(
            headers: [
              'Date',
              l.pain,
              l.fr ? 'Eau (ml)' : 'Water (ml)',
              l.mood,
              l.notes,
            ],
            data: rows,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red400),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignments: {0: pw.Alignment.centerLeft},
            columnWidths: {4: const pw.FlexColumnWidth(2)},
          ),
        ],
      ),
    );
    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'sicklecare_doctor_report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final entries = context.watch<TrackerProvider>().entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: l.exportPdf,
              icon: const Icon(Icons.ios_share),
              onPressed: () => _exportPdf(context, entries, l),
            ),
        ],
      ),
      body: entries.isEmpty
          ? EmptyState(
              icon: Icons.timeline,
              title: l.noEntries,
              subtitle: l.noEntriesSub,
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.trends, style: tt.titleMedium),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _LegendDot(color: cs.primary, label: l.legendPain),
                          const SizedBox(width: 16),
                          _LegendDot(color: _waterColor, label: l.legendWater),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(l.pain,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 120,
                        child: _miniChart(
                          context,
                          ys: [
                            for (var i = 0; i < entries.length; i++)
                              entries[entries.length - 1 - i]
                                  .painLevel
                                  .toDouble()
                          ],
                          color: cs.primary,
                          maxY: 10,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(l.water,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 120,
                        child: _miniChart(
                          context,
                          ys: [
                            for (var i = 0; i < entries.length; i++)
                              entries[entries.length - 1 - i]
                                  .hydrationMl
                                  .toDouble()
                          ],
                          color: _waterColor,
                          maxY: _waterMax(entries
                              .map((e) => e.hydrationMl.toDouble())
                              .toList()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SectionCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  cs.primary.withValues(alpha: 0.1),
                              child: Text(e.mood,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fmtDateTime(e.date),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(l.painMl(e.painLevel, e.hydrationMl)),
                                  if (e.notes.isNotEmpty)
                                    Text(e.notes,
                                        style: TextStyle(
                                            color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  context.read<TrackerProvider>().remove(e.id),
                            )
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }

  static double _waterMax(List<double> ys) {
    final m = ys.isEmpty ? 0.0 : ys.reduce((a, b) => a > b ? a : b);
    final rounded = ((m / 500).ceil() * 500).toDouble();
    return rounded < 1000 ? 1000 : rounded;
  }

  Widget _miniChart(BuildContext context,
      {required List<double> ys, required Color color, required double maxY}) {
    final cs = Theme.of(context).colorScheme;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (ys.length - 1).clamp(1, 1000).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: maxY / 2,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 3,
            color: color,
            dotData: const FlDotData(show: true),
            belowBarData:
                BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
            spots: [
              for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])
            ],
          )
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          title,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      );

  pw.Widget _pdfKeyValueTable(List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        data: rows,
        cellStyle: const pw.TextStyle(fontSize: 10),
        cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.2),
          1: const pw.FlexColumnWidth(2),
        },
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
        },
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }
}
