import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';

import 'hydration_nutrition_screen.dart';
import 'tracker_screen.dart';
import 'reminders_screen.dart';
import 'goals_screen.dart';
import 'support_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  //  SAVE PAIN LEVEL
  Future<void> savePainLevel(double value) async {
    final uid = user?.uid;
    if (uid == null) return;

    await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .set({
      'painLevel': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ✅ GLOBAL DRAWER (CLEAN)
      drawer: const AppDrawer(),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 127, 237),
        title: const Text("SickleCare"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          )
        ],
      ),

      body: uid == null
          ? const Center(child: Text("User not logged in"))
          : StreamBuilder<DocumentSnapshot>(
              stream: firestore
                  .collection('users')
                  .doc(uid)
                  .collection('daily')
                  .doc(today)
                  .snapshots(),
              builder: (context, snapshot) {
                double hydration = 0;
                double painLevel = 0;
                int mealsCount = 0;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>;

                  hydration = (data['hydration'] ?? 0).toDouble();
                  painLevel = (data['painLevel'] ?? 0).toDouble();
                  mealsCount =
                      (data['meals'] as List?)?.length ?? 0;
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [

                    // 👋 Welcome
                    const Text(
                      "Welcome back, Warrior 💪",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      user?.email ?? "",
                      style: TextStyle(color: Colors.grey[700]),
                    ),

                    const SizedBox(height: 20),

                    //  STATS
                    Row(
                      children: [
                        _card(
                          "Hydration",
                          "${hydration.toStringAsFixed(1)} L",
                          Icons.water_drop,
                        ),
                        const SizedBox(width: 10),
                        _card(
                          "Meals",
                          "$mealsCount meals",
                          Icons.restaurant,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _card(
                          "Pain",
                          painLevel.toInt().toString(),
                          Icons.monitor_heart,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ❤️ PAIN TRACKER
                    const Text(
                      "How are you feeling today?",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
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
                              "Pain Level: ${painLevel.toInt()}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            Slider(
                              value: painLevel,
                              min: 0,
                              max: 10,
                              divisions: 10,
                              activeColor: const Color.fromARGB(255, 49, 127, 237),
                              label: painLevel.toInt().toString(),
                              onChanged: (value) {
                                setState(() {
                                  painLevel = value;
                                });
                                savePainLevel(value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ⚡ QUICK ACTIONS
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 10),

                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      children: [

                        _actionCard(
                          "Health",
                          Icons.favorite,
                          Colors.blue,
                          () => _navigate(
                              const HydrationNutritionScreen()),
                        ),

                        _actionCard(
                          "Tracker",
                          Icons.warning,
                          Colors.red,
                          () => _navigate(const TrackerScreen()),
                        ),

                        _actionCard(
                          "Reminders",
                          Icons.alarm,
                          Colors.orange,
                          () => _navigate(const RemindersScreen()),
                        ),

                        _actionCard(
                          "Goals",
                          Icons.flag,
                          Colors.green,
                          () => _navigate(const GoalsScreen()),
                        ),

                        _actionCard(
                          "Support",
                          Icons.people,
                          Colors.teal,
                          () => _navigate(const SupportScreen()),
                        ),

                        _actionCard(
                          "Analytics",
                          Icons.show_chart,
                          Colors.purple,
                          () => _navigate(const HistoryScreen()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
    );
  }

  // NAVIGATION
  void _navigate(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // 📊 CARD
  Widget _card(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.redAccent),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(value,
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  // ⚡ ACTION CARD
  Widget _actionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}