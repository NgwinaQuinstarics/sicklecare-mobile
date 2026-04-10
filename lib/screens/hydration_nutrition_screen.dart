import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';

class HydrationNutritionScreen extends StatefulWidget {
  const HydrationNutritionScreen({super.key});

  @override
  State<HydrationNutritionScreen> createState() =>
      _HydrationNutritionScreenState();
}

class _HydrationNutritionScreenState
    extends State<HydrationNutritionScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  double water = 0;
  final mealController = TextEditingController();
  List<String> meals = [];

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  // ✅ LOAD DATA
  Future<void> loadData() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      setState(() {
        water = (doc.data()?['hydration'] ?? 0).toDouble();
        meals = List<String>.from(doc.data()?['meals'] ?? []);
      });
    }
  }

  // ✅ SAVE DATA
  Future<void> saveData() async {
    final uid = user?.uid;
    if (uid == null) return;

    await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .set({
      'hydration': water,
      'meals': meals,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved successfully ✅")),
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    mealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(), // ✅ GLOBAL DRAWER

      appBar: AppBar(
        title: const Text("Health Tracker"),
        backgroundColor: const Color.fromARGB(255, 49, 127, 237),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            // 💧 HYDRATION
            const Text(
              "Hydration 💧",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "${water.toStringAsFixed(1)} L",
                      style: const TextStyle(fontSize: 18),
                    ),
                    Slider(
                      value: water,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() => water = value);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🍽 NUTRITION
            const Text(
              "Nutrition 🍽",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mealController,
                    decoration: const InputDecoration(
                      labelText: "Add meal",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: () {
                    if (mealController.text.isNotEmpty) {
                      setState(() {
                        meals.add(mealController.text);
                        mealController.clear();
                      });
                    }
                  },
                )
              ],
            ),

            const SizedBox(height: 10),

            ...meals.map((meal) => Card(
                  child: ListTile(
                    title: Text(meal),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          meals.remove(meal);
                        });
                      },
                    ),
                  ),
                )),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}