import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class HydrationNutritionScreen extends StatefulWidget {
  const HydrationNutritionScreen({super.key});

  @override
  State<HydrationNutritionScreen> createState() =>
      _HydrationNutritionScreenState();
}

class _HydrationNutritionScreenState extends State<HydrationNutritionScreen> {
  // Hydration
  int glasses = 3;
  final int hydrationGoal = 8;

  // Nutrition
  int meals = 2;
  final int nutritionGoal = 3;

  // Days of week
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void logGlass() {
    if (glasses < hydrationGoal) {
      setState(() {
        glasses++;
      });
    }
  }

  void logMeal() {
    if (meals < nutritionGoal) {
      setState(() {
        meals++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hydrationPct = ((glasses / hydrationGoal) * 100).round();
    final nutritionPct = ((meals / nutritionGoal) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Health Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HomeScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // HEADER MESSAGE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay Healthy 💧🍎',
                      style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your hydration and nutrition for a better you.',
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // HYDRATION CARD
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(
                        "Hydration Tracker",
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glass count
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$glasses',
                                  style: GoogleFonts.nunito(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.blueAccent)),
                              Text('of $hydrationGoal glasses',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(width: 24),
                          // Bottle graphic
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.blueAccent, width: 3),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 400),
                                    height: 120 * (glasses / hydrationGoal),
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                              Text('$hydrationPct%',
                                  style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ],
                          ),
                          const SizedBox(width: 24),
                          // Remaining
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Remaining',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600])),
                              Text('${hydrationGoal - glasses}',
                                  style: GoogleFonts.nunito(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: glasses < hydrationGoal ? logGlass : null,
                        child: Text(
                          glasses >= hydrationGoal
                              ? '🎉 Goal Reached!'
                              : '+ Log a Glass',
                          style: GoogleFonts.nunito(
                              fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // NUTRITION CARD
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(
                        "Nutrition Tracker",
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.orangeAccent),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$meals',
                                  style: GoogleFonts.nunito(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.orangeAccent)),
                              Text('of $nutritionGoal meals',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.orangeAccent, width: 3),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 400),
                                    height: 120 * (meals / nutritionGoal),
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ),
                              Text('$nutritionPct%',
                                  style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Remaining',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600])),
                              Text('${nutritionGoal - meals}',
                                  style: GoogleFonts.nunito(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: meals < nutritionGoal ? logMeal : null,
                        child: Text(
                          meals >= nutritionGoal
                              ? '🎉 Goal Reached!'
                              : '+ Log a Meal',
                          style: GoogleFonts.nunito(
                              fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}