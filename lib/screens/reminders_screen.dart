import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';
import '../widgets/main_navigation.dart';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  final titleController = TextEditingController();
  TimeOfDay? selectedTime;

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  DocumentReference<Map<String, dynamic>> get docRef =>
      firestore.collection('users').doc(user!.uid).collection('reminders').doc(today);

  Stream<List<Map<String, dynamic>>> get remindersStream {
    return docRef.snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return [];

      final raw = data['reminders'];
      if (raw is! List) return [];

      return raw.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> save(List<Map<String, dynamic>> reminders) async {
    await docRef.set({'reminders': reminders}, SetOptions(merge: true));
  }

  Future<void> add(List<Map<String, dynamic>> current) async {
    if (titleController.text.trim().isEmpty || selectedTime == null) return;

    final id = DateTime.now().millisecondsSinceEpoch;

    final updated = List<Map<String, dynamic>>.from(current);

    updated.add({
      'id': id,
      'title': titleController.text.trim(),
      'hour': selectedTime!.hour,
      'minute': selectedTime!.minute,
      'completed': false,
      'missed': false,
    });

    await NotificationService.scheduleReminder(
      id: id,
      title: titleController.text.trim(),
      hour: selectedTime!.hour,
      minute: selectedTime!.minute,
    );

    titleController.clear();
    setState(() => selectedTime = null);

    await save(updated);
  }

  Future<void> toggle(List<Map<String, dynamic>> list, int i) async {
    final updated = List<Map<String, dynamic>>.from(list);

    updated[i]['completed'] = !(updated[i]['completed'] ?? false);

    if (updated[i]['completed'] == true) {
      await NotificationService.cancel(updated[i]['id']);
    }

    await save(updated);
  }

  Future<void> delete(List<Map<String, dynamic>> list, int i) async {
    final updated = List<Map<String, dynamic>>.from(list);

    await NotificationService.cancel(updated[i]['id']);

    updated.removeAt(i);

    await save(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      bottomNavigationBar: const MainNavigation(currentIndex: 3),

      appBar: AppBar(
        title: const Text("Medication Reminders"),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: remindersStream,
        builder: (context, snapshot) {
          final reminders = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Medication name",
                        prefixIcon: Icon(Icons.medication),
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
                            : selectedTime!.format(context),
                      ),
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () => add(reminders),
                      child: const Text("Add Reminder"),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: reminders.isEmpty
                    ? const Center(child: Text("No reminders yet"))
                    : ListView.builder(
                        itemCount: reminders.length,
                        itemBuilder: (context, i) {
                          final item = reminders[i];

                          return ListTile(
                            title: Text(item['title'] ?? ''),
                            subtitle: Text(
                              "${item['hour']}:${item['minute']}",
                            ),
                            leading: Checkbox(
                              value: item['completed'] ?? false,
                              onChanged: (_) => toggle(reminders, i),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => delete(reminders, i),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}