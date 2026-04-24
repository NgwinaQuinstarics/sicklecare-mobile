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

  bool saving = false;

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  // ================= REAL-TIME STREAM =================
  Stream<DocumentSnapshot> getDailyStream() {
    final uid = user?.uid;
    return firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .snapshots();
  }

  // ================= SAVE =================
  Future<void> saveData() async {
    final uid = user?.uid;
    if (uid == null) return;

    setState(() => saving = true);

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

    setState(() => saving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved successfully")),
    );
  }

  @override
  void dispose() {
    mealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1E40AF);
    const Color softBg = Color(0xFFF8FAFC);
    const Color textMain = Color(0xFF0F172A);
    const Color danger = Color(0xFFB91C1C);

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
              color: textMain, fontWeight: FontWeight.w700),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: getDailyStream(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;

            water = (data['hydration'] ?? 0).toDouble();
            meals = List<String>.from(data['meals'] ?? []);
          }

          return SingleChildScrollView(
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
                  "Stay consistent. Your body depends on it.",
                  style: TextStyle(color: Colors.grey[600]),
                ),

                const SizedBox(height: 25),

                // ================= HYDRATION =================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                        "${water.toStringAsFixed(1)} L",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      Slider(
                        value: water,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        activeColor: brandBlue,
                        onChanged: (value) {
                          setState(() => water = value);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ================= NUTRITION =================
                const Text(
                  "Meals 🍽",
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
                          hintText: "e.g Rice, Beans",
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

                    ElevatedButton(
                      onPressed: () {
                        if (mealController.text.isNotEmpty) {
                          setState(() {
                            meals.add(mealController.text.trim());
                            mealController.clear();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                      ),
                      child: const Icon(Icons.add),
                    )
                  ],
                ),

                const SizedBox(height: 15),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: meals.map((meal) {
                    return Chip(
                      label: Text(meal),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => meals.remove(meal));
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Save",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}