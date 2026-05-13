import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';
import '../widgets/main_navigation.dart';

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

  double localWater = 0;
  List<String> meals = [];
  final mealController = TextEditingController();

  Timer? debounce;
  bool isSliding = false;

  static const Color brandBlue = Color(0xFF1E40AF);
  static const Color softBg = Color(0xFFF8FAFC);

  // ================= DATE =================

  String get today {
    final now = DateTime.now();

    return "${now.year}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  // ================= DOC REF =================

  DocumentReference<Map<String, dynamic>> get docRef {
    final uid = user?.uid;

    if (uid == null) {
      throw Exception("User not logged in");
    }

    return firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today);
  }

  // ================= STREAM =================

  Stream<DocumentSnapshot<Map<String, dynamic>>> get stream {
    return docRef
        .snapshots()
        .cast<DocumentSnapshot<Map<String, dynamic>>>();
  }

  // ================= SAVE =================

  Future<void> saveData() async {
    final uid = user?.uid;

    if (uid == null) return;

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

    debounce = Timer(
      const Duration(milliseconds: 600),
      () {
        saveData();
      },
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    mealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,

      drawer: const AppDrawer(),

      // ✅ BOTTOM NAVIGATION
      bottomNavigationBar:
          const MainNavigation(currentIndex: 1),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: brandBlue,
        ),

        title: const Text(
          "Health Tracker",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),

      body: user == null
          ? const Center(
              child: Text("User not logged in"),
            )
          : StreamBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
              stream: stream,

              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data!.exists) {
                  final data = snapshot.data!.data()!;

                  final firebaseWater =
                      (data['hydration'] ?? 0)
                          .toDouble();

                  final firebaseMeals =
                      List<String>.from(
                    data['meals'] ?? [],
                  );

                  if (!isSliding) {
                    localWater =
                        firebaseWater.clamp(0, 5);
                  }

                  meals = firebaseMeals;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ================= HEADER =================

                      Container(
                        padding:
                            const EdgeInsets.all(24),

                        decoration: BoxDecoration(
                          gradient:
                              const LinearGradient(
                            colors: [
                              Color(0xFF1E40AF),
                              Color(0xFF3B82F6),
                            ],
                          ),

                          borderRadius:
                              BorderRadius.circular(
                                  24),
                        ),

                        child: const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Text(
                              "Daily Health Tracking",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 8),

                            Text(
                              "Monitor hydration and nutrition daily.",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ================= HYDRATION =================

                      Container(
                        padding:
                            const EdgeInsets.all(20),

                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                                  22),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(
                                      alpha: 0.04),
                              blurRadius: 10,
                              offset:
                                  const Offset(0, 4),
                            ),
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  color: Colors.blue,
                                ),

                                SizedBox(width: 8),

                                Text(
                                  "Hydration",
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Text(
                              "${localWater.toStringAsFixed(1)} L",

                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Slider(
                              value: localWater,

                              min: 0,
                              max: 5,
                              divisions: 10,

                              activeColor:
                                  brandBlue,

                              onChangeStart: (_) {
                                setState(() {
                                  isSliding = true;
                                });
                              },

                              onChanged: (value) {
                                setState(() {
                                  localWater = value;
                                });

                                autoSave();
                              },

                              onChangeEnd: (_) {
                                setState(() {
                                  isSliding = false;
                                });

                                saveData();
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ================= MEALS =================

                      const Text(
                        "Meals",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller:
                                  mealController,

                              decoration:
                                  InputDecoration(
                                hintText:
                                    "Add meal",

                                filled: true,
                                fillColor:
                                    Colors.white,

                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              16),

                                  borderSide:
                                      BorderSide.none,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  brandBlue,

                              padding:
                                  const EdgeInsets
                                      .all(16),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            16),
                              ),
                            ),

                            onPressed: () {
                              final meal =
                                  mealController.text
                                      .trim();

                              if (meal.isEmpty) {
                                return;
                              }

                              setState(() {
                                meals.add(meal);

                                mealController
                                    .clear();
                              });

                              saveData();
                            },

                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,

                        children: meals.map((meal) {
                          return Chip(
                            label: Text(meal),

                            backgroundColor:
                                Colors.white,

                            deleteIconColor:
                                Colors.red,

                            onDeleted: () {
                              setState(() {
                                meals.remove(meal);
                              });

                              saveData();
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 35),

                      // ================= SAVE BUTTON =================

                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                brandBlue,

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 16,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(18),
                            ),
                          ),

                          onPressed: saveData,

                          child: const Text(
                            "Save Data",

                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
    );
  }
}