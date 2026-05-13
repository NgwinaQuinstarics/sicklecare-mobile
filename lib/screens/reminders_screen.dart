import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';
import '../widgets/main_navigation.dart';

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

  static const Color primary = Color(0xFF1E40AF);
  static const Color bg = Color(0xFFF4F7FA);
  static const Color cardColor = Colors.white;

  String get today {
    final now = DateTime.now();
    return "${now.year}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  DocumentReference<Map<String, dynamic>> get docRef {
    return firestore
        .collection('users')
        .doc(user!.uid)
        .collection('reminders')
        .doc(today);
  }

  Stream<List<Map<String, dynamic>>> get remindersStream {
    return docRef.snapshots().map((doc) {
      if (!doc.exists) return [];
      return List<Map<String, dynamic>>.from(
        doc.data()?['reminders'] ?? [],
      );
    });
  }

  Future<void> save(List<Map<String, dynamic>> reminders) async {
    await docRef.set({
      'reminders': reminders,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> add(List<Map<String, dynamic>> current) async {
    if (titleController.text.trim().isEmpty || selectedTime == null) return;

    final updated = List<Map<String, dynamic>>.from(current);

    updated.add({
      'title': titleController.text.trim(),
      'hour': selectedTime!.hour,
      'minute': selectedTime!.minute,
      'completed': false,
    });

    titleController.clear();
    selectedTime = null;

    await save(updated);
  }

  Future<void> toggle(List<Map<String, dynamic>> current, int index) async {
    final updated = List<Map<String, dynamic>>.from(current);
    updated[index]['completed'] =
        !(updated[index]['completed'] ?? false);
    await save(updated);
  }

  Future<void> delete(List<Map<String, dynamic>> current, int index) async {
    final updated = List<Map<String, dynamic>>.from(current);
    updated.removeAt(index);
    await save(updated);
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      // ================= DRAWER =================
      drawer: const AppDrawer(),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: const MainNavigation(currentIndex: 3),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primary),
        title: const Text(
          "Daily Reminders",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: remindersStream,
        builder: (context, snapshot) {
          final reminders = snapshot.data ?? [];

          return Column(
            children: [
              // ================= INPUT =================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "Enter reminder",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );

                            if (picked != null) {
                              setState(() => selectedTime = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            selectedTime == null
                                ? "Pick Time"
                                : selectedTime!.format(context),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            onPressed: () => add(reminders),
                            child: const Text("Add Reminder"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ================= LIST =================
              Expanded(
                child: reminders.isEmpty
                    ? const Center(
                        child: Text(
                          "No reminders yet.\nAdd your first task ✨",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          final item = reminders[index];

                          final time =
                              "${item['hour']}:${(item['minute'] ?? 0).toString().padLeft(2, '0')}";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: item['completed'] ?? false,
                                onChanged: (_) =>
                                    toggle(reminders, index),
                              ),
                              title: Text(
                                item['title'],
                                style: TextStyle(
                                  decoration: item['completed'] == true
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text("Time: $time"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    delete(reminders, index),
                              ),
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