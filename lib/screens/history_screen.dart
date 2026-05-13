import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;

import '../widgets/app_drawer.dart';
import '../widgets/main_navigation.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  final List<FlSpot> painSpots = [];
  final List<FlSpot> hydrationSpots = [];

  final List<Map<String, dynamic>> logs = [];
  final List<Map<String, dynamic>> alerts = [];

  bool loading = true;

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color background = Color(0xFFF4F7FA);

  Future<void> loadHistory() async {
    final uid = user?.uid;

    if (uid == null) return;

    setState(() {
      loading = true;

      painSpots.clear();
      hydrationSpots.clear();
      logs.clear();
      alerts.clear();
    });

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('daily')
          .get();

      final docs = snapshot.docs.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      int index = 0;

      for (final doc in docs) {
        final data = doc.data();

        final pain = (data['painLevel'] ?? 0).toDouble();
        final hydration = (data['hydration'] ?? 0).toDouble();

        painSpots.add(
          FlSpot(index.toDouble(), pain),
        );

        hydrationSpots.add(
          FlSpot(index.toDouble(), hydration),
        );

        logs.add({
          'id': doc.id,
          'pain': pain,
          'hydration': hydration,
        });

        if (pain >= 7) {
          alerts.add({
            'id': '${doc.id}_pain',
            'message': '⚠️ High pain detected on ${doc.id}',
          });
        }

        if (hydration < 2) {
          alerts.add({
            'id': '${doc.id}_water',
            'message': '💧 Low hydration detected on ${doc.id}',
          });
        }

        index++;
      }
    } catch (e) {
      debugPrint("History error: $e");
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> deleteRecord(String id) async {
    final uid = user?.uid;

    if (uid == null) return;

    await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(id)
        .delete();

    await loadHistory();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Record deleted"),
      ),
    );
  }

  Future<void> exportCSV() async {
    String csv = "Date,Pain,Hydration\n";

    for (final log in logs) {
      csv +=
          "${log['id']},${log['pain']},${log['hydration']}\n";
    }

    final dir = await getTemporaryDirectory();

    final file = File("${dir.path}/history.csv");

    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "SickleCare History Export",
    );
  }

  Future<void> exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "SickleCare Health Report",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  "Total Records: ${logs.length}",
                ),

                pw.SizedBox(height: 20),

                ...logs.map(
                  (log) => pw.Padding(
                    padding:
                        const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Text(
                      "${log['id']}  |  Pain: ${log['pain']}  |  Water: ${log['hydration']}L",
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();

    final file = File("${dir.path}/history_report.pdf");

    await file.writeAsBytes(
      await pdf.save(),
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "SickleCare PDF Report",
    );
  }

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      drawer: const AppDrawer(),

      bottomNavigationBar:
          const MainNavigation(currentIndex: 2),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

        iconTheme: const IconThemeData(
          color: primaryBlue,
        ),

        title: const Text(
          "Health History",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: exportCSV,
            icon: const Icon(
              Icons.table_chart_rounded,
            ),
          ),

          IconButton(
            onPressed: exportPDF,
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadHistory,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1565C0),
                          Color(0xFF0D47A1),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Health Analytics",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "Track your hydration and pain history over time.",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (alerts.isNotEmpty) ...[
                    const Text(
                      "Health Alerts",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...alerts.map(
                      (alert) => Container(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Colors.red.shade50,
                          borderRadius:
                              BorderRadius
                                  .circular(18),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning_rounded,
                            color: Colors.red,
                          ),
                          title: Text(
                            alert['message'],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                            ),
                            onPressed: () {
                              setState(() {
                                alerts.removeWhere(
                                  (a) =>
                                      a['id'] ==
                                      alert['id'],
                                );
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],

                  _chartCard(
                    title: "Pain Trend",
                    subtitle:
                        "Daily pain level analysis",
                    spots: painSpots,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 20),

                  _chartCard(
                    title: "Hydration Trend",
                    subtitle:
                        "Daily water intake analysis",
                    spots: hydrationSpots,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required List<FlSpot> spots,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 220,

            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 10,

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),

                borderData: FlBorderData(
                  show: false,
                ),

                titlesData: FlTitlesData(
                  show: false,
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty
                        ? [
                            const FlSpot(0, 0)
                          ]
                        : spots,

                    isCurved: true,

                    color: color,

                    barWidth: 4,

                    dotData: const FlDotData(
                      show: true,
                    ),

                    belowBarData:
                        BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}