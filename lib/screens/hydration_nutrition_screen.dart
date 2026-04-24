import 'dart:async';
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

class _HydrationNutritionScreenState extends State<HydrationNutritionScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  double localWater = 0;
  List<String> meals = [];
  final mealController = TextEditingController();

  bool saving = false;
  bool isSliding = false;

  Timer? debounce;

  // ✅ FIXED DATE FORMAT (CRITICAL)
  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  DocumentReference<Map<String, dynamic>> get docRef {
    return firestore
        .collection('users')
        .doc(user!.uid)
        .collection('daily')
        .doc(today);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get stream =>
      docRef.snapshots();

  // ================= SAVE =================
  Future<void> saveData() async {
    if (user == null) return;

    try {
      await docRef.set({
        'hydration': localWater,
        'meals': meals,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("SAVE ERROR: $e");
    }
  }

  // ================= AUTO SAVE =================
  void autoSave() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 700), () {
      saveData();
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    mealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1E40AF);
    const Color softBg = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: softBg,
      drawer: const AppDrawer(),

      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: brandBlue),
        title: const Text("Health Tracker"),
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data()!;

            final firebaseWater =
                (data['hydration'] ?? 0).toDouble();

            meals = List<String>.from(data['meals'] ?? []);

            // only sync when user is NOT sliding
            if (!isSliding) {
              localWater = firebaseWater.clamp(0, 5);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Daily Health Tracking",
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 25),

                // ================= HYDRATION =================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                        "${localWater.toStringAsFixed(1)} L",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Slider(
                        value: localWater.clamp(0, 5),
                        min: 0,
                        max: 5,
                        divisions: 10,
                        activeColor: brandBlue,

                        onChangeStart: (_) {
                          setState(() => isSliding = true);
                        },

                        onChanged: (value) {
                          setState(() => localWater = value);
                          autoSave();
                        },

                        onChangeEnd: (_) {
                          setState(() => isSliding = false);
                          saveData();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ================= MEALS =================
                const Text(
                  "Meals",
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
                          hintText: "Add meal",
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
                        if (mealController.text.trim().isEmpty) return;

                        setState(() {
                          meals.add(mealController.text.trim());
                          mealController.clear();
                        });

                        saveData();
                      },
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Wrap(
                  spacing: 10,
                  children: meals.map((meal) {
                    return Chip(
                      label: Text(meal),
                      onDeleted: () {
                        setState(() => meals.remove(meal));
                        saveData();
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saveData,
                    child: const Text("Save Data"),
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