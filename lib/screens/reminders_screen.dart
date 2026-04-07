import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> reminders = [];

  final titleController = TextEditingController();
  TimeOfDay? selectedTime;

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  // ✅ LOAD REMINDERS
  Future<void> loadReminders() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .get();

    if (doc.exists && mounted) {
      setState(() {
        reminders = List<Map<String, dynamic>>.from(
          doc.data()?['reminders'] ?? [],
        );
      });
    }
  }

  // ✅ SAVE REMINDERS
  Future<void> saveReminders() async {
    final uid = user?.uid;
    if (uid == null) return;

    await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .set({
      'reminders': reminders,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ✅ ADD REMINDER
  void addReminder() {
    if (titleController.text.isEmpty || selectedTime == null) return;

    setState(() {
      reminders.add({
        'title': titleController.text,
        'hour': selectedTime!.hour,
        'minute': selectedTime!.minute,
        'completed': false,
      });

      titleController.clear();
      selectedTime = null;
    });

    saveReminders();
  }

  // ✅ TOGGLE COMPLETE (🔥 HABIT TRACKING)
  void toggleComplete(int index) {
    setState(() {
      reminders[index]['completed'] =
          !(reminders[index]['completed'] ?? false);
    });

    saveReminders();
  }

  // ✅ DELETE
  void deleteReminder(int index) {
    setState(() {
      reminders.removeAt(index);
    });

    saveReminders();
  }

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text("Reminders"),
        backgroundColor: Colors.redAccent,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            "Set Reminder ⏰",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: "Medication / Food / Activity",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );

              if (picked != null) {
                setState(() => selectedTime = picked);
              }
            },
            child: Text(
              selectedTime == null
                  ? "Pick Time"
                  : "Time: ${selectedTime!.format(context)}",
            ),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: addReminder,
            child: const Text("Add Reminder"),
          ),

          const SizedBox(height: 20),

          const Text(
            "Today's Reminders",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          ...reminders.asMap().entries.map((entry) {
            int index = entry.key;
            var reminder = entry.value;

            final time =
                "${reminder['hour']}:${reminder['minute'].toString().padLeft(2, '0')}";

            return Card(
              child: ListTile(
                leading: Checkbox(
                  value: reminder['completed'] ?? false,
                  onChanged: (_) => toggleComplete(index),
                ),
                title: Text(
                  reminder['title'],
                  style: TextStyle(
                    decoration: reminder['completed']
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text("Time: $time"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteReminder(index),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}