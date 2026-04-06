import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  double painLevel = 0;
  final notesController = TextEditingController();

  final List<String> allSymptoms = [
    "Fatigue",
    "Fever",
    "Chest Pain",
    "Headache",
    "Joint Pain",
    "Shortness of Breath"
  ];

  List<String> selectedSymptoms = [];

  // 🔥 SAVE CRISIS LOG
  Future<void> saveLog() async {
    final uid = user?.uid;
    if (uid == null) return;

    await firestore
        .collection('users')
        .doc(uid)
        .collection('crisis_logs')
        .add({
      'painLevel': painLevel,
      'symptoms': selectedSymptoms,
      'notes': notesController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    // Reset form
    setState(() {
      painLevel = 0;
      selectedSymptoms.clear();
      notesController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Crisis logged successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crisis Tracker"),
        backgroundColor: Colors.redAccent,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            // ❤️ Pain Level
            const Text(
              "Pain Level",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Slider(
              value: painLevel,
              min: 0,
              max: 10,
              divisions: 10,
              label: painLevel.toInt().toString(),
              activeColor: Colors.redAccent,
              onChanged: (value) {
                setState(() => painLevel = value);
              },
            ),

            const SizedBox(height: 20),

            // 🩺 Symptoms
            const Text(
              "Symptoms",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Wrap(
              spacing: 8,
              children: allSymptoms.map((symptom) {
                final isSelected = selectedSymptoms.contains(symptom);

                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  selectedColor: Colors.redAccent,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selectedSymptoms.add(symptom);
                      } else {
                        selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 📝 Notes
            const Text(
              "Notes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Describe how you feel...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // 💾 SAVE BUTTON
            ElevatedButton(
              onPressed: saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text("Save Log"),
            ),

            const SizedBox(height: 30),

            // 📊 RECENT LOGS
            const Text(
              "Recent Logs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('users')
                  .doc(uid)
                  .collection('crisis_logs')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logs = snapshot.data!.docs;

                if (logs.isEmpty) {
                  return const Text("No logs yet");
                }

                return Column(
                  children: logs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final pain = data['painLevel'] ?? 0;
                    final symptoms =
                        List<String>.from(data['symptoms'] ?? []);
                    final notes = data['notes'] ?? "";

                    return Card(
                      child: ListTile(
                        title: Text("Pain: $pain"),
                        subtitle: Text(
                          "${symptoms.join(", ")}\n$notes",
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}