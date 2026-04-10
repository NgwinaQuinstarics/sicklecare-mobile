import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final contactController = TextEditingController();

  String genotype = "SS";
  bool notifications = true;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final uid = user?.uid;
    if (uid == null) return;

    try {
      final doc = await firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? "";
        ageController.text = (data['age'] ?? "").toString();
        contactController.text = data['contact'] ?? "";
        genotype = data['genotype'] ?? "SS";
        notifications = data['notifications'] ?? true;
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> saveProfile() async {
    final uid = user?.uid;
    if (uid == null) return;

    try {
      await firestore.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'age': int.tryParse(ageController.text) ?? 0,
        'contact': contactController.text.trim(),
        'genotype': genotype,
        'notifications': notifications,
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget sectionCard({required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget textField(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(), // ✅ navigation added

      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.redAccent, // ✅ your app color
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// 🔴 PROFILE HEADER
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: const Color.fromARGB(255, 95, 138, 239),
                    child: Text(
                      (user?.email ?? "U")[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    user?.email ?? "",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  /// 🧾 PERSONAL INFO
                  sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Personal Information",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),

                        textField(nameController, "Full Name"),
                        textField(ageController, "Age",
                            type: TextInputType.number),
                        textField(contactController, "Emergency Contact",
                            type: TextInputType.phone),

                        DropdownButtonFormField<String>(
                          initialValue: genotype,
                          decoration: InputDecoration(
                            labelText: "Genotype",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: ["AA", "AS", "SS", ]
                              .map((g) =>
                                  DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => genotype = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔔 SETTINGS
                  sectionCard(
                    child: SwitchListTile(
                      title: const Text("Enable Notifications"),
                      value: notifications,
                      activeThumbColor: const Color.fromARGB(255, 95, 138, 239),
                      onChanged: (val) {
                        setState(() => notifications = val);
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 💾 SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(82, 129, 247, 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}