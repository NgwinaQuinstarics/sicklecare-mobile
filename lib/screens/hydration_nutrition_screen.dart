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

  bool loading = true;

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= LOAD =================
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

    setState(() => loading = false);
  }

  // ================= SAVE =================
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
      const SnackBar(content: Text("Health data saved successfully")),
    );
  }

  @override
  void dispose() {
    mealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1A56BE);
    const Color softBg = Color(0xFFF4F7FA);
    const Color accentRed = Color(0xFFB91C1C);

    return Scaffold(
      backgroundColor: softBg,
      drawer: const AppDrawer(),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: brandBlue),
        title: const Text(
          "Health Tracker",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // HEADER
                  const Text(
                    "Daily Health Tracking",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Monitor hydration and nutrition to stay stable.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 25),

                  // ================= HYDRATION CARD =================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Hydration 💧",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "${water.toStringAsFixed(1)} Litres",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: brandBlue,
                            inactiveTrackColor: Colors.grey[200],
                            thumbColor: Colors.white,
                            overlayColor: brandBlue.withValues(alpha: 0.2),
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: water,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            onChanged: (value) {
                              setState(() => water = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ================= NUTRITION =================
                  const Text(
                    "Nutrition 🍽",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [

                      Expanded(
                        child: TextField(
                          controller: mealController,
                          decoration: InputDecoration(
                            hintText: "Add meal (e.g Rice, Fish)",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: brandBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            if (mealController.text.isNotEmpty) {
                              setState(() {
                                meals.add(mealController.text.trim());
                                mealController.clear();
                              });
                            }
                          },
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 15),

                  // MEALS LIST
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: meals.map((meal) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(meal),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  meals.remove(meal);
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: accentRed,
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Save Health Data",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}