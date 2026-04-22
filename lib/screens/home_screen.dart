import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';
import 'hydration_nutrition_screen.dart';
import 'tracker_screen.dart';
import 'reminders_screen.dart';
import 'support_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  double painLevel = 0;

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;

    const brandBlue = Color(0xFF1A56BE);
    const softBg = Color(0xFFF4F7FA);
    const textMain = Color(0xFF1E293B);
    const accentBrown = Color(0xFF5D4037);
    const criticalRed = Color(0xFFB91C1C);

    return Scaffold(
      backgroundColor: softBg,
      drawer: const AppDrawer(),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: brandBlue),
        title: const Text(
          "SickleCare",
          style: TextStyle(
            color: textMain,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          )
        ],
      ),

      body: uid == null
          ? const Center(child: Text("Authentication Required"))
          : StreamBuilder<DocumentSnapshot>(
              stream: firestore
                  .collection('users')
                  .doc(uid)
                  .collection('daily')
                  .doc(today)
                  .snapshots(),
              builder: (context, snapshot) {
                double hydration = 0;
                int mealsCount = 0;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  hydration = (data['hydration'] ?? 0).toDouble();
                  painLevel = (data['painLevel'] ?? 0).toDouble();
                  mealsCount = (data['meals'] as List?)?.length ?? 0;
                }

                return FadeTransition(
                  opacity: _fadeAnim,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [

                      const SizedBox(height: 10),

                      /// HEADER
                      const Text(
                        "Today’s Health Snapshot",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      /// METRICS
                      Row(
                        children: [
                          _metric("Hydration",
                              "${hydration.toStringAsFixed(1)}L",
                              Icons.water_drop, brandBlue),
                          const SizedBox(width: 10),
                          _metric("Meals", "$mealsCount",
                              Icons.restaurant, accentBrown),
                        ],
                      ),

                      const SizedBox(height: 25),

                      /// PAIN TRACKER
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Pain Level",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  "${painLevel.toInt()}/10",
                                  style: TextStyle(
                                    color: painLevel > 6
                                        ? criticalRed
                                        : brandBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: painLevel,
                              min: 0,
                              max: 10,
                              divisions: 10,
                              activeColor: brandBlue,
                              onChanged: (v) {
                                setState(() => painLevel = v);
                                savePainLevel(v);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// MODULES
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _tile("Health", Icons.healing, brandBlue, () {
                            _nav(const HydrationNutritionScreen());
                          }),
                          _tile("Tracker", Icons.assignment, criticalRed,
                              () {
                            _nav(const TrackerScreen());
                          }),
                          _tile("Reminders", Icons.alarm, Colors.orange,
                              () {
                            _nav(const RemindersScreen());
                          }),
                          _tile("Support", Icons.people, Colors.teal,
                              () {
                            _nav(const SupportScreen());
                          }),
                          _tile("History", Icons.bar_chart, accentBrown,
                              () {
                            _nav(const HistoryScreen());
                          }),
                        ],
                      ),

                      const SizedBox(height: 40),

                      const Center(
                        child: Text(
                          "Stay strong. Every drop of effort counts 💙",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}