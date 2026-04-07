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
  List<FlSpot> adherenceSpots = [];

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

    int index = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final pain = (data['painLevel'] ?? 0).toDouble();
      final water = (data['hydration'] ?? 0).toDouble();

      final reminders = List<Map<String, dynamic>>.from(
        data['reminders'] ?? [],
      );

      int completed = reminders.where((r) => r['completed'] == true).length;
      int total = reminders.length;

      double adherence = total == 0 ? 0 : (completed / total) * 10;

      painSpots.add(FlSpot(index.toDouble(), pain));
      hydrationSpots.add(FlSpot(index.toDouble(), water));
      adherenceSpots.add(FlSpot(index.toDouble(), adherence));

      logs.add({
        'date': doc.id,
        'pain': pain,
        'hydration': water,
        'adherence': adherence.toStringAsFixed(1),
      });

      index++;
    }

    if (!mounted) return;
    setState(() {});
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

                _buildChart("Pain Trend", painSpots),
                const SizedBox(height: 20),

                _buildChart("Hydration Trend", hydrationSpots),
                const SizedBox(height: 20),

                _buildChart("Reminder Adherence", adherenceSpots),
                const SizedBox(height: 20),

                const Text(
                  "History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                ...logs.map((log) => Card(
                      child: ListTile(
                        title: Text(log['date']),
                        subtitle: Text(
                          "Pain: ${log['pain']} | Water: ${log['hydration']}L | Adherence: ${log['adherence']}/10",
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

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