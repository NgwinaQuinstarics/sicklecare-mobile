import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> loadHistory() async {
    final uid = user?.uid;
    if (uid == null) return;

    painSpots.clear();
    hydrationSpots.clear();
    adherenceSpots.clear();
    logs.clear();

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
      final water = (data['hydrationLevel'] ?? 0).toDouble();

      final adherence = (data['medicationTaken'] ?? false) ? 10.0 : 0.0;

      painSpots.add(FlSpot(index.toDouble(), pain));
      hydrationSpots.add(FlSpot(index.toDouble(), water));
      adherenceSpots.add(FlSpot(index.toDouble(), adherence));

      logs.add({
        'id': doc.id,
        'pain': pain,
        'hydration': water,
        'adherence': adherence,
      });

      index++;
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  // 🗑 DELETE RECORD
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

  // 📥 EXPORT TO CSV
  Future<void> exportData() async {
    if (logs.isEmpty) return;

    String csv = "Date,Pain,Hydration,Adherence\n";

    for (var log in logs) {
      csv +=
          "${log['id']},${log['pain']},${log['hydration']},${log['adherence']}\n";
    }

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/health_history.csv");

    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: "My Health Report");
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
            icon: const Icon(Icons.download),
            onPressed: exportData,
          )
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : logs.isEmpty
              ? const Center(child: Text("No data yet"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [

                    _buildChart("Pain Trend", painSpots),
                    const SizedBox(height: 20),

                    _buildChart("Hydration Trend", hydrationSpots),
                    const SizedBox(height: 20),

                    _buildChart("Medication Adherence", adherenceSpots),
                    const SizedBox(height: 20),

                    const Text(
                      "History",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

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
                                    content: const Text(
                                        "Are you sure you want to delete this entry?"),
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