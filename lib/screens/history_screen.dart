import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;

import '../widgets/app_drawer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  List<FlSpot> painSpots = [];
  List<FlSpot> hydrationSpots = [];
  List<FlSpot> adherenceSpots = [];

  List<Map<String, dynamic>> logs = [];

  bool isLoading = true;

  //  SMART ALERTS
  List<String> alerts = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  //  LOAD DATA
  Future<void> loadHistory() async {
    final uid = user?.uid;
    if (uid == null) return;

    painSpots.clear();
    hydrationSpots.clear();
    adherenceSpots.clear();
    logs.clear();
    alerts.clear();

    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .orderBy('updatedAt')
        .get();

    int index = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final pain = (data['painLevel'] ?? 0).toDouble();
      final hydration = (data['hydrationLevel'] ?? 0).toDouble();
      final medication = data['medicationTaken'] ?? false;

      final adherence = medication ? 10.0 : 0.0;

      //  charts
      painSpots.add(FlSpot(index.toDouble(), pain));
      hydrationSpots.add(FlSpot(index.toDouble(), hydration));
      adherenceSpots.add(FlSpot(index.toDouble(), adherence));

      //  logs
      logs.add({
        'id': doc.id,
        'pain': pain,
        'hydration': hydration,
        'adherence': adherence,
      });

      //  SMART ANALYSIS
      if (pain >= 7) {
        alerts.add("⚠️ High pain detected on ${doc.id}. Consider medical attention.");
      }

      if (hydration < 2) {
        alerts.add("💧 Low hydration on ${doc.id}. Drink more water.");
      }

      if (!medication) {
        alerts.add("💊 Medication missed on ${doc.id}.");
      }

      index++;
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // 🗑 DELETE
  Future<void> deleteRecord(String id) async {
    final uid = user?.uid;
    if (uid == null) return;

    await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(id)
        .delete();

    loadHistory();
  }

  //  CSV EXPORT
  Future<void> exportCSV() async {
    if (logs.isEmpty) return;

    String csv = "Date,Pain,Hydration,Adherence\n";

    for (var log in logs) {
      csv +=
          "${log['id']},${log['pain']},${log['hydration']},${log['adherence']}\n";
    }

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/health_history.csv");

    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: "Health Report");
  }

  //  PDF EXPORT
  Future<void> exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text("SickleCare Health Report",
              style: pw.TextStyle(fontSize: 24)),

          pw.SizedBox(height: 20),

          pw.TableHelper.fromTextArray(
            headers: ["Date", "Pain", "Hydration", "Adherence"],
            data: logs.map((log) {
              return [
                log['id'],
                log['pain'].toString(),
                log['hydration'].toString(),
                log['adherence'].toString(),
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          pw.Text("Health Alerts",
              style: pw.TextStyle(fontSize: 18)),

          ...alerts.map((a) => pw.Text(a)),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/health_report.pdf");

    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)],
        text: "My Health Report");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text("Health Analytics"),
        backgroundColor: const Color.fromARGB(255, 49, 127, 237),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: exportCSV,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportPDF,
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // 🚨 ALERT SECTION
                if (alerts.isNotEmpty) ...[
                  const Text("Health Alerts",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  ...alerts.map((a) => Card(
                        color: Colors.red.shade100,
                        child: ListTile(
                          leading: const Icon(Icons.warning, color: Colors.red),
                          title: Text(a),
                        ),
                      )),

                  const SizedBox(height: 20),
                ],

                _buildChart("Pain Trend", painSpots),
                const SizedBox(height: 20),

                _buildChart("Hydration Trend", hydrationSpots),
                const SizedBox(height: 20),

                _buildChart("Medication Adherence", adherenceSpots),
                const SizedBox(height: 20),

                const Text("History",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                ...logs.map((log) => Card(
                      child: ListTile(
                        title: Text(log['id']),
                        subtitle: Text(
                          "Pain: ${log['pain']} | Water: ${log['hydration']}L | Adherence: ${log['adherence']}/10",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Delete Record"),
                                content: const Text("Are you sure?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      deleteRecord(log['id']);
                                    },
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )),
              ],
            ),
    );
  }

  Widget _buildChart(String title, List<FlSpot> spots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

        const SizedBox(height: 10),

        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}