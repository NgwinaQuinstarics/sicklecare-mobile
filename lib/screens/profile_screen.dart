import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';
import '../widgets/main_navigation.dart';

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

  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color surfaceWhite = Colors.white;
  static const Color bgGrey = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    contactController.dispose();
    super.dispose();
  }

  // ================= LOAD PROFILE =================
  Future<void> loadProfile() async {
    final uid = user?.uid;

    if (uid == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          nameController.text = data['name'] ?? "";
          ageController.text = (data['age'] ?? "").toString();
          contactController.text = data['contact'] ?? "";
          genotype = data['genotype'] ?? "SS";
          notifications = data['notifications'] ?? true;
        });
      }
    } catch (e) {
      debugPrint("LOAD PROFILE ERROR: $e");
    }

    setState(() => isLoading = false);
  }

  // ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    final uid = user?.uid;
    if (uid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: primaryBlue)),
    );

    try {
      await firestore.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'age': int.tryParse(ageController.text) ?? 0,
        'contact': contactController.text.trim(),
        'genotype': genotype,
        'notifications': notifications,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile saved successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e")),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: bgGrey,
      drawer: const AppDrawer(),

      // NOTE: adjust index if needed in your nav system
      bottomNavigationBar: const MainNavigation(currentIndex: 3),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : CustomScrollView(
              slivers: [
                _buildHeader(),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        _section("PERSONAL INFO"),
                        _card([
                          _input(nameController, "Full Name", Icons.person),
                          _input(ageController, "Age", Icons.calendar_today,
                              type: TextInputType.number),
                          _input(contactController, "Contact", Icons.phone,
                              type: TextInputType.phone),
                        ]),

                        const SizedBox(height: 20),

                        _section("MEDICAL INFO"),
                        _card([
                          DropdownButtonFormField<String>(
                            value: genotype,
                            decoration: _dec("Genotype", Icons.bloodtype),
                            items: ["AA", "AS", "SS"]
                                .map((g) =>
                                    DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => genotype = v);
                              }
                            },
                          ),
                        ]),

                        const SizedBox(height: 20),

                        _section("SETTINGS"),
                        _card([
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Notifications"),
                            value: notifications,
                            activeColor: accentBlue,
                            onChanged: (v) =>
                                setState(() => notifications = v),
                          ),
                        ]),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                            ),
                            child: const Text("SAVE PROFILE"),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text("PROFILE"),
        centerTitle: true,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, accentBlue],
            ),
          ),
          child: const Center(
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: bgGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: _dec(label, icon),
      ),
    );
  }
}