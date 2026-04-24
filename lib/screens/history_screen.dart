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
  List<Map<String, dynamic>> alerts = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final uid = user?.uid;
    if (uid == null) return;

    setState(() => loading = true);

    painSpots.clear();
    hydrationSpots.clear();
    adherenceSpots.clear();
    logs.clear();
    alerts.clear();

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('daily')
          .get();

      int index = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final pain = (data['painLevel'] ?? 0).toDouble();
        final hydration = (data['hydration'] ?? 0).toDouble();
        final medication = data['medicationTaken'] ?? false;

        final adherence = medication ? 10.0 : 0.0;

        painSpots.add(FlSpot(index.toDouble(), pain));
        hydrationSpots.add(FlSpot(index.toDouble(), hydration));
        adherenceSpots.add(FlSpot(index.toDouble(), adherence));

        logs.add({
          'id': doc.id,
          'pain': pain,
          'hydration': hydration,
          'adherence': adherence,
        });

        if (pain >= 7) {
          alerts.add({
            'id': "${doc.id}_pain",
            'message': "⚠️ High pain on ${doc.id}"
          });
        }

        if (hydration < 2) {
          alerts.add({
            'id': "${doc.id}_hydration",
            'message': "💧 Low hydration on ${doc.id}"
          });
        }

        if (!medication) {
          alerts.add({
            'id': "${doc.id}_med",
            'message': "💊 Medication missed on ${doc.id}"
          });
        }

        index++;
      }
    } catch (e) {
      debugPrint("History error: $e");
    }

    if (mounted) {
      setState(() => loading = false);
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

    loadHistory();
  }

  Future<void> exportCSV() async {
    String csv = "Date,Pain,Hydration,Adherence\n";

    for (var log in logs) {
      csv +=
          "${log['id']},${log['pain']},${log['hydration']},${log['adherence']}\n";
    }

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/history.csv");

    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("SickleCare Report"),
            pw.SizedBox(height: 10),
            pw.Text("Total Records: ${logs.length}"),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/report.pdf");

    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF4F7FA);
    const primaryBlue = Color(0xFF1A56BE);

    return Scaffold(
      backgroundColor: bg,
      drawer: const AppDrawer(),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Health History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: primaryBlue),
        actions: [
          IconButton(
            onPressed: exportCSV,
            icon: const Icon(Icons.table_chart),
          ),
          IconButton(
            onPressed: exportPDF,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (alerts.isNotEmpty) ...[
                  const Text(
                    "Health Alerts",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...alerts.map((alert) => Card(
                        color: Colors.red.shade100,
                        child: ListTile(
                          leading: const Icon(Icons.warning),
                          title: Text(alert['message']),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                alerts.removeWhere(
                                    (a) => a['id'] == alert['id']);
                              });
                            },
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],

                _chart("Pain Trend", painSpots),
                const SizedBox(height: 20),
                _chart("Hydration Trend", hydrationSpots),
                const SizedBox(height: 20),
                _chart("Medication Adherence", adherenceSpots),

                const SizedBox(height: 20),

                const Text(
                  "History Records",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                ...logs.map((log) => Card(
                      child: ListTile(
                        title: Text(log['id']),
                        subtitle: Text(
                          "Pain: ${log['pain']} | Water: ${log['hydration']} | Adherence: ${log['adherence']}/10",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteRecord(log['id']),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }

  Widget _chart(String title, List<FlSpot> spots) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    dotData: FlDotData(show: false),
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