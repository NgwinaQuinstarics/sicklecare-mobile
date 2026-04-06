import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  bool hydrationReminder = false;
  bool medicationReminder = false;

  TimeOfDay hydrationTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay medicationTime = const TimeOfDay(hour: 20, minute: 0);

  // ✅ LOAD SETTINGS FROM FIREBASE
  Future<void> loadData() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc = await firestore.collection('users').doc(uid).get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data()!;

      setState(() {
        hydrationReminder = data['hydrationReminder'] ?? false;
        medicationReminder = data['medicationReminder'] ?? false;
      });
    }
  }

  // ✅ SAVE SETTINGS
  Future<void> saveSettings() async {
    final uid = user?.uid;
    if (uid == null) return;

    await firestore.collection('users').doc(uid).set({
      'hydrationReminder': hydrationReminder,
      'medicationReminder': medicationReminder,
    }, SetOptions(merge: true));
  }

  // ⏰ PICK TIME
  Future<void> pickTime(bool isHydration) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isHydration ? hydrationTime : medicationTime,
    );

    if (picked != null) {
      setState(() {
        if (isHydration) {
          hydrationTime = picked;
        } else {
          medicationTime = picked;
        }
      });
    }
  }

  // 🔔 TOGGLE REMINDER (FIXED)
  Future<void> toggleReminder(bool value, bool isHydration) async {
    setState(() {
      if (isHydration) {
        hydrationReminder = value;
      } else {
        medicationReminder = value;
      }
    });

    await saveSettings();

    final time = isHydration ? hydrationTime : medicationTime;

    if (value) {
      // ✅ NEW CORRECT CALL
      await NotificationService.scheduleDailyReminder(
        id: isHydration ? 1 : 2,
        title: isHydration ? "💧 Drink Water" : "💊 Take Medication",
        body: isHydration
            ? "Stay hydrated for better health"
            : "Time for your medication",
        hour: time.hour,
        minute: time.minute,
      );
    } else {
      await NotificationService.cancel(isHydration ? 1 : 2);
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
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

          // 💧 HYDRATION
          _reminderCard(
            title: "Hydration Reminder",
            value: hydrationReminder,
            time: hydrationTime,
            onToggle: (val) => toggleReminder(val, true),
            onTimePick: () => pickTime(true),
          ),

          const SizedBox(height: 20),

          // 💊 MEDICATION
          _reminderCard(
            title: "Medication Reminder",
            value: medicationReminder,
            time: medicationTime,
            onToggle: (val) => toggleReminder(val, false),
            onTimePick: () => pickTime(false),
          ),
        ],
      ),
    );
  }

  // 🔥 UI CARD
  Widget _reminderCard({
    required String title,
    required bool value,
    required TimeOfDay time,
    required Function(bool) onToggle,
    required VoidCallback onTimePick,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text("Time: ${time.format(context)}"),
        trailing: Switch(
          value: value,
          onChanged: onToggle,
        ),
        onTap: onTimePick,
      ),
    );
  }
}