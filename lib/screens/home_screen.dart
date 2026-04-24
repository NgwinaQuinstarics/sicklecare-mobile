import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';
import 'hydration_nutrition_screen.dart';
import 'tracker_screen.dart';
import 'reminders_screen.dart';
import 'support_screen.dart';
import 'history_screen.dart';
import 'weather_screen.dart';
import '../utils/date_helper.dart';
import '../models/health_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  late AnimationController _fadeController;
  late Animation<double> _fade;

  double painLevel = 0;

  @override
  void initState() {
    super.initState();

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fade = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> savePainLevel(double value) async {
    final uid = user?.uid;
    if (uid == null) return;

    await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(DateHelper.today())
        .set({
      'painLevel': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;

    const brandBlue = Color(0xFF1E40AF);
    const softBg = Color(0xFFF8FAFC);
    const textMain = Color(0xFF0F172A);
    const accentBrown = Color(0xFF5D4037);
    const criticalRed = Color(0xFFB91C1C);

    return Scaffold(
      backgroundColor: softBg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: brandBlue),
        title: const Text(
          "SickleCare",
          style: TextStyle(color: textMain, fontWeight: FontWeight.bold),
        ),
      ),

      body: uid == null
          ? const Center(child: Text("Authentication Required"))
          : StreamBuilder<DocumentSnapshot>(
              stream: firestore
                  .collection('users')
                  .doc(uid)
                  .collection('daily')
                  .doc(DateHelper.today())
                  .snapshots(),

              builder: (context, snapshot) {
                final data = HealthData.fromMap(
                    snapshot.data?.data() as Map<String, dynamic>?);

                painLevel = data.painLevel;

                return FadeTransition(
                  opacity: _fade,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const SizedBox(height: 20),

                        Row(
                          children: const [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, color: Colors.blue),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Welcome back",
                                    style: TextStyle(color: Colors.grey)),
                                Text("Warrior",
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        Row(
                          children: [
                            _metric("Hydration",
                                "${data.hydration.toStringAsFixed(1)}L",
                                Icons.water_drop, brandBlue),
                            const SizedBox(width: 12),
                            _metric("Meals",
                                "${data.meals.length}",
                                Icons.restaurant, accentBrown),
                          ],
                        ),

                        const SizedBox(height: 25),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Pain Level",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text("${painLevel.toInt()}/10"),
                                ],
                              ),
                              Slider(
                                value: painLevel,
                                min: 0,
                                max: 10,
                                divisions: 10,
                                activeColor: brandBlue,
                                onChanged: (value) {
                                  setState(() => painLevel = value);
                                  savePainLevel(value);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _tile("Health", Icons.favorite, brandBlue,
                                () => _nav(const HydrationNutritionScreen())),
                            _tile("Tracker", Icons.assignment, criticalRed,
                                () => _nav(const TrackerScreen())),
                            _tile("Reminders", Icons.alarm, Colors.orange,
                                () => _nav(const RemindersScreen())),
                            _tile("Support", Icons.support_agent, Colors.teal,
                                () => _nav(const SupportScreen())),
                            _tile("History", Icons.bar_chart, accentBrown,
                                () => _nav(const HistoryScreen())),
                            _tile("Weather", Icons.cloud, Colors.blueGrey,
                                () => _nav(const WeatherScreen())),
                          ],
                        ),

                        const SizedBox(height: 40),

                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.favorite, color: Colors.red),
                              SizedBox(height: 10),
                              Text(
                                "Your strength is in consistency.",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Every small action builds a healthier tomorrow.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _metric(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}