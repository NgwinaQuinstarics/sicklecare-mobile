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

  int painLevel = 0;
  bool fatigue = false;
  bool fever = false;
  bool headache = false;
  final notesController = TextEditingController();

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  // ✅ LOAD EXISTING DATA
  Future<void> loadData() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data()!;

      setState(() {
        painLevel = (data['painLevel'] ?? 0).toInt();
        fatigue = data['fatigue'] ?? false;
        fever = data['fever'] ?? false;
        headache = data['headache'] ?? false;
        notesController.text = data['notes'] ?? "";
      });
    }
  }

  // ✅ SAVE DATA
  Future<void> saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = user?.uid;
    if (uid == null) return;

    await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .set({
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
    return Scaffold(
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text("Daily Health Tracker"),
        backgroundColor: Colors.redAccent,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              // ❤️ PAIN LEVEL
              const Text(
                "Pain Level",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "$painLevel / 10",
                        style: const TextStyle(fontSize: 20),
                      ),
                      Slider(
                        value: painLevel.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        activeColor: Colors.redAccent,
                        onChanged: (value) {
                          setState(() {
                            painLevel = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ⚠️ SYMPTOMS
              const Text(
                "Symptoms",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              Card(
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text("Fatigue"),
                      value: fatigue,
                      onChanged: (val) {
                        setState(() => fatigue = val!);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text("Fever"),
                      value: fever,
                      onChanged: (val) {
                        setState(() => fever = val!);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text("Headache"),
                      value: headache,
                      onChanged: (val) {
                        setState(() => headache = val!);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 📝 NOTES
              const Text(
                "Additional Notes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Describe how you feel...",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.length > 200) {
                    return "Keep notes under 200 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // 💾 SAVE BUTTON
              ElevatedButton(
                onPressed: saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Save Tracker"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}