import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  bool isLoading = true;

  String name = "";
  int age = 0;
  String genotype = "";
  String contact = "";

  bool hydrationReminder = true;
  bool medicationReminder = true;
  bool crisisAlerts = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ✅ LOAD PROFILE DATA
  Future<void> loadProfile() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc = await firestore.collection('users').doc(uid).get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        name = data['name'] ?? '';
        age = data['age'] ?? 0;
        genotype = data['genotype'] ?? '';
        contact = data['emergencyContact'] ?? '';

        hydrationReminder = data['hydrationReminder'] ?? true;
        medicationReminder = data['medicationReminder'] ?? true;
        crisisAlerts = data['crisisAlerts'] ?? true;

        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // ✅ SAVE SETTINGS
  Future<void> saveSettings() async {
    final uid = user?.uid;
    if (uid == null) return;

    await firestore.collection('users').doc(uid).update({
      'hydrationReminder': hydrationReminder,
      'medicationReminder': medicationReminder,
      'crisisAlerts': crisisAlerts,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings updated")),
    );
  }

  // ✅ CONFIRM EXIT
  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Exit Profile"),
        content: const Text("Discard changes and go back?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      // ✅ NEW SAFE API (NO WARNINGS)
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.of(context); // SAFE capture

        final shouldLeave = await _confirmExit();

        if (!mounted) return;

        if (shouldLeave) {
          navigator.pop();
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profile & Settings"),
          backgroundColor: Colors.blueAccent,

          // ✅ BACK BUTTON FIXED
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final navigator = Navigator.of(context); // SAFE

              final shouldLeave = await _confirmExit();

              if (!mounted) return;

              if (shouldLeave) {
                navigator.pop();
              }
            },
          ),
        ),

        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // 👤 PROFILE INFO
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "Personal Info",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text("Name: $name"),
                          Text("Age: $age"),
                          Text("Genotype: $genotype"),
                          Text("Emergency Contact: $contact"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔔 NOTIFICATIONS
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  SwitchListTile(
                    title: const Text("Hydration Reminder"),
                    value: hydrationReminder,
                    activeThumbColor: Colors.blue,
                    onChanged: (val) {
                      setState(() => hydrationReminder = val);
                    },
                  ),

                  SwitchListTile(
                    title: const Text("Medication Reminder"),
                    value: medicationReminder,
                    activeThumbColor: Colors.blue,
                    onChanged: (val) {
                      setState(() => medicationReminder = val);
                    },
                  ),

                  SwitchListTile(
                    title: const Text("Crisis Alerts"),
                    value: crisisAlerts,
                    activeThumbColor: Colors.blue,
                    onChanged: (val) {
                      setState(() => crisisAlerts = val);
                    },
                  ),

                  const SizedBox(height: 20),

                  // 💾 SAVE BUTTON
                  ElevatedButton(
                    onPressed: saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Save Settings"),
                  ),
                ],
              ),
      ),
    );
  }
}