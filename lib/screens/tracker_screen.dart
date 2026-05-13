import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';
import '../widgets/main_navigation.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  double painLevel = 0;
  double hydration = 0;

  bool fatigue = false;
  bool fever = false;
  bool headache = false;

  List<String> meals = [];

  final notesController = TextEditingController();

  // ================= DATE =================
  String get today {
    final now = DateTime.now();
    return "${now.year}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  String? get uid => auth.currentUser?.uid;

  DocumentReference? get docRef {
    if (uid == null) return null;
    return firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today);
  }

  // ================= LOAD =================
  Future<void> loadData() async {
    if (docRef == null) return;

    final doc = await docRef!.get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      painLevel = (data['painLevel'] ?? 0).toDouble();
      hydration = (data['hydration'] ?? 0).toDouble();

      fatigue = data['fatigue'] ?? false;
      fever = data['fever'] ?? false;
      headache = data['headache'] ?? false;

      meals = List<String>.from(data['meals'] ?? []);
      notesController.text = data['notes'] ?? "";
    });
  }

  // ================= SAVE =================
  Future<void> saveData() async {
    if (docRef == null) return;

    if (!_formKey.currentState!.validate()) return;

    await docRef!.set({
      'painLevel': painLevel,
      'hydration': hydration,
      'meals': meals,
      'fatigue': fatigue,
      'fever': fever,
      'headache': headache,
      'notes': notesController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tracker saved successfully ✅")),
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1A56BE);
    const Color softBg = Color(0xFFF4F7FA);

    return Scaffold(
      backgroundColor: softBg,

      // ================= DRAWER =================
      drawer: const AppDrawer(),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: const MainNavigation(currentIndex: 1),

      appBar: AppBar(
        title: const Text(
          "Daily Health Tracker",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: brandBlue),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              const Text(
                "Track your daily health",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // ================= PAIN =================
              _card(
                title: "Pain Level",
                child: Column(
                  children: [
                    Text("${painLevel.toInt()} / 10",
                        style: const TextStyle(fontSize: 22)),
                    Slider(
                      value: painLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      onChanged: (v) => setState(() => painLevel = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ================= HYDRATION =================
              _card(
                title: "Hydration (Litres)",
                child: Column(
                  children: [
                    Text("${hydration.toStringAsFixed(1)} L"),
                    Slider(
                      value: hydration,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      onChanged: (v) => setState(() => hydration = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ================= SYMPTOMS =================
              _card(
                title: "Symptoms",
                child: Column(
                  children: [
                    _check("Fatigue", fatigue, (v) => setState(() => fatigue = v!)),
                    _check("Fever", fever, (v) => setState(() => fever = v!)),
                    _check("Headache", headache, (v) => setState(() => headache = v!)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ================= NOTES =================
              _card(
                title: "Notes",
                child: TextFormField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: saveData,
                child: const Text("Save Tracker"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= CARD =================
  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ================= CHECKBOX =================
  Widget _check(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}