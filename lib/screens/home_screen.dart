import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';
import '../widgets/main_navigation.dart';
import '../utils/date_helper.dart';

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
  late Animation<double> _fadeAnimation;

  double painLevel = 0;

  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textMain = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
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

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text("User not authenticated"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      drawer: const AppDrawer(),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

        iconTheme: const IconThemeData(
          color: primaryBlue,
        ),

        title: Row(
          children: [
            Image.asset(
              "assets/logo.png",
              width: 38,
              height: 38,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 10),

            const Text(
              "SickleCare",
              style: TextStyle(
                color: textMain,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: const MainNavigation(
        currentIndex: 0,
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestore
            .collection('users')
            .doc(uid)
            .collection('daily')
            .doc(DateHelper.today())
            .snapshots(),

        builder: (context, snapshot) {
          double hydration = 0;
          double pain = 0;
          List meals = [];

          if (snapshot.hasData && snapshot.data!.data() != null) {
            final data = snapshot.data!.data()!;

            hydration = (data['hydration'] ?? 0).toDouble();
            pain = (data['painLevel'] ?? 0).toDouble();
            meals = data['meals'] ?? [];
          }

          painLevel = pain;

          return FadeTransition(
            opacity: _fadeAnimation,

            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ================= HEADER =================

                  Container(
                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E40AF),
                          Color(0xFF3B82F6),
                        ],
                      ),

                      borderRadius: BorderRadius.circular(26),
                    ),

                    child: Row(
                      children: [

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                user?.email ?? "User",

                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ================= METRICS =================

                  Row(
                    children: [

                      Expanded(
                        child: _metricCard(
                          title: "Hydration",
                          value: "$hydration L",
                          icon: Icons.water_drop,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _metricCard(
                          title: "Meals",
                          value: meals.length.toString(),
                          icon: Icons.restaurant,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ================= PAIN TRACKER =================

                  Container(
                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(26),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [

                            const Text(
                              "Pain Level",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),

                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: 0.1),

                                borderRadius:
                                    BorderRadius.circular(20),
                              ),

                              child: Text(
                                "${painLevel.toInt()}/10",

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Slider(
                          value: painLevel,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          activeColor: primaryBlue,

                          onChanged: (value) async {
                            setState(() {
                              painLevel = value;
                            });

                            await savePainLevel(value);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ================= DAILY TIP =================

                  Container(
                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(26),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            Icon(
                              Icons.lightbulb,
                              color: Colors.orange,
                            ),

                            SizedBox(width: 10),

                            Text(
                              "Daily Wellness Tip",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 14),

                        Text(
                          "Stay hydrated, rest properly, avoid stress, and follow your medication reminders consistently to reduce sickle cell complications.",

                          style: TextStyle(
                            color: Colors.grey,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(
            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            value,

            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}