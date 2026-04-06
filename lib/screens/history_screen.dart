import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

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
  List<Map<String, dynamic>> logs = [];

  Future<void> loadHistory() async {
    final uid = user?.uid;
    if (uid == null) return;

    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .orderBy('updatedAt')
        .get();

    List<FlSpot> pain = [];
    List<FlSpot> water = [];
    List<Map<String, dynamic>> tempLogs = [];

    int index = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final painLevel = (data['painLevel'] ?? 0).toDouble();
      final hydration = (data['hydration'] ?? 0).toDouble();

      pain.add(FlSpot(index.toDouble(), painLevel));
      water.add(FlSpot(index.toDouble(), hydration));

      tempLogs.add({
        'date': doc.id,
        'pain': painLevel,
        'hydration': hydration,
        'meals': (data['meals'] as List?)?.length ?? 0,
      });

      index++;
    }

    if (!mounted) return;

    setState(() {
      painSpots = pain;
      hydrationSpots = water;
      logs = tempLogs;
    });
  }

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text("Health Analytics"),
        backgroundColor: Colors.redAccent,
      ),

      body: logs.isEmpty
          ? const Center(child: Text("No data yet"))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // 📈 PAIN CHART
                _buildChart("Pain Trend", painSpots),

                const SizedBox(height: 20),

                // 💧 HYDRATION CHART
                _buildChart("Hydration Trend", hydrationSpots),

                const SizedBox(height: 20),

                // 📅 HISTORY LIST
                const Text(
                  "History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                ...logs.map((log) => Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(log['date']),
                        subtitle: Text(
                          "Pain: ${log['pain']} | Water: ${log['hydration']}L | Meals: ${log['meals']}",
                        ),
                      ),
                    )),
              ],
            ),
    );
  }

  // 🔥 CLEAN CHART UI
  Widget _buildChart(String title, List<FlSpot> spots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

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