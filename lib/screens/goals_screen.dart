import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  double waterGoal = 2.5;
  int mealsGoal = 3;
  int painGoal = 3;

  double currentWater = 0;
  int currentMeals = 0;
  double currentPain = 0;

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  @override
  void initState() {
    super.initState();
    loadGoals();
    loadTodayData();
  }

  // ✅ LOAD GOALS
  Future<void> loadGoals() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc = await firestore.collection('goals').doc(uid).get();

    if (doc.exists && mounted) {
      setState(() {
        waterGoal = (doc['waterGoal'] ?? 2.5).toDouble();
        mealsGoal = doc['mealsGoal'] ?? 3;
        painGoal = doc['painGoal'] ?? 3;
      });
    }
  }

  // ✅ LOAD TODAY DATA
  Future<void> loadTodayData() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .get();

    if (doc.exists && mounted) {
      setState(() {
        currentWater = (doc['hydration'] ?? 0).toDouble();
        currentMeals = (doc['meals'] as List?)?.length ?? 0;
        currentPain = (doc['painLevel'] ?? 0).toDouble();
      });
    }
  }

  // ✅ SAVE GOALS
  Future<void> saveGoals() async {
    final uid = user?.uid;
    if (uid == null) return;

    await firestore.collection('goals').doc(uid).set({
      'waterGoal': waterGoal,
      'mealsGoal': mealsGoal,
      'painGoal': painGoal,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Goals saved ✅")),
    );
  }

  double progress(double current, double goal) {
    if (goal == 0) return 0;
    return (current / goal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Goals & Progress"),
        backgroundColor: Colors.redAccent,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadGoals();
          await loadTodayData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            const Text(
              "Daily Goals",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // 💧 WATER
            _goalCard(
              "Hydration",
              "$currentWater / $waterGoal L",
              progress(currentWater, waterGoal),
              Icons.water_drop,
              Colors.blue,
            ),

            Slider(
              value: waterGoal,
              min: 1,
              max: 5,
              divisions: 8,
              label: waterGoal.toStringAsFixed(1),
              onChanged: (v) => setState(() => waterGoal = v),
            ),

            const SizedBox(height: 10),

            // 🍽 MEALS (FIXED HERE)
            _goalCard(
              "Meals",
              "$currentMeals / $mealsGoal",
              progress(
                currentMeals.toDouble(),
                mealsGoal.toDouble(),
              ),
              Icons.restaurant,
              Colors.green,
            ),

            Slider(
              value: mealsGoal.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              label: mealsGoal.toString(),
              onChanged: (v) => setState(() => mealsGoal = v.toInt()),
            ),

            const SizedBox(height: 10),

            // ❤️ PAIN
            _goalCard(
              "Pain Control (Lower is better)",
              "$currentPain / $painGoal",
              1 - progress(currentPain, painGoal.toDouble()),
              Icons.monitor_heart,
              Colors.red,
            ),

            Slider(
              value: painGoal.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: painGoal.toString(),
              onChanged: (v) => setState(() => painGoal = v.toInt()),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveGoals,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Save Goals"),
            ),

            const SizedBox(height: 20),

            _insightCard(),
          ],
        ),
      ),
    );
  }

  Widget _goalCard(String title, String subtitle, double value,
      IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: value),
          ],
        ),
      ),
    );
  }

  Widget _insightCard() {
    String message = "You're doing well 👍";

    if (currentWater < waterGoal * 0.5) {
      message = "Increase water intake 💧";
    } else if (currentMeals < mealsGoal) {
      message = "Try to eat more balanced meals 🍽";
    } else if (currentPain > painGoal) {
      message = "High pain detected — rest & hydrate ❤️";
    }

    return Card(
      color: Colors.yellow[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Insight: $message",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}