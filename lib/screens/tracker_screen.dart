import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  double painLevel = 0; // FIX: use double for consistency
  bool fatigue = false;
  bool fever = false;
  bool headache = false;

  final notesController = TextEditingController();

  // ================= FIXED DATE FORMAT =================
  String get today {
    final now = DateTime.now();
    return "${now.year}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  DocumentReference get docRef => firestore
      .collection('users')
      .doc(user!.uid)
      .collection('daily')
      .doc(today);

  // ================= LOAD =================
  Future<void> loadData() async {
    final doc = await docRef.get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        painLevel = (data['painLevel'] ?? 0).toDouble();
        fatigue = data['fatigue'] ?? false;
        fever = data['fever'] ?? false;
        headache = data['headache'] ?? false;
        notesController.text = data['notes'] ?? "";
      });
    }
  }

  // ================= SAVE (FIXED) =================
  Future<void> saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = user?.uid;
    if (uid == null) return;

    await docRef.set({
      'painLevel': painLevel,
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

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1A56BE);
    const Color softBg = Color(0xFFF4F7FA);

    return Scaffold(
      backgroundColor: softBg,
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text(
          "Daily Health Tracker",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: brandBlue),
        elevation: 0,
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

              // PAIN
              _card(
                title: "Pain Level",
                child: Column(
                  children: [
                    Text(
                      "${painLevel.toInt()} / 10",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: painLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: brandBlue,
                      onChanged: (value) {
                        setState(() => painLevel = value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // SYMPTOMS
              _card(
                title: "Symptoms",
                child: Column(
                  children: [
                    _checkTile("Fatigue", fatigue, (v) {
                      setState(() => fatigue = v!);
                    }),
                    _checkTile("Fever", fever, (v) {
                      setState(() => fever = v!);
                    }),
                    _checkTile("Headache", headache, (v) {
                      setState(() => headache = v!);
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // NOTES
              _card(
                title: "Notes",
                child: TextFormField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "How do you feel today?",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 25),

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

  Widget _checkTile(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}