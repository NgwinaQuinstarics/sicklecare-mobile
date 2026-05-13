import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_drawer.dart';
import '../widgets/main_navigation.dart'; // ✅ ADD THIS

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

  Future<void> loadProfile() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc = await firestore.collection('users').doc(uid).get();

    if (doc.exists && mounted) {
      final data = doc.data()!;
      setState(() {
        nameController.text = data['name'] ?? "";
        ageController.text = (data['age'] ?? "").toString();
        contactController.text = data['contact'] ?? "";
        genotype = data['genotype'] ?? "SS";
        notifications = data['notifications'] ?? true;
        isLoading = false;
      });
    } else if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveProfile() async {
    final uid = user?.uid;
    if (uid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
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
          content: Text("Profile securely synchronized"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sync failed: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      drawer: const AppDrawer(),

      // ✅ BOTTOM NAVIGATION ADDED HERE
      bottomNavigationBar: const MainNavigation(currentIndex: 4),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : CustomScrollView(
              slivers: [
                _buildSliverHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("IDENTITY & CONTACT"),
                        _buildProfileCard([
                          _buildModernInput(
                              nameController, "Full Name", Icons.badge_outlined),
                          _buildModernInput(ageController, "Age",
                              Icons.calendar_today_outlined,
                              type: TextInputType.number),
                          _buildModernInput(
                              contactController,
                              "Emergency Contact",
                              Icons.contact_emergency_outlined,
                              type: TextInputType.phone),
                        ]),

                        const SizedBox(height: 24),

                        _buildSectionHeader("CLINICAL DATA"),
                        _buildProfileCard([
                          DropdownButtonFormField<String>(
                            value: genotype,
                            decoration: _inputDecoration(
                                "Blood Genotype", Icons.bloodtype_outlined),
                            items: ["AA", "AS", "SS"]
                                .map((g) => DropdownMenuItem(
                                    value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) => setState(() => genotype = v!),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        _buildSectionHeader("SYSTEM PREFERENCES"),
                        _buildProfileCard([
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Health Notifications",
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text(
                                "Receive alerts for hydration & medication"),
                            value: notifications,
                            activeColor: accentBlue,
                            onChanged: (v) =>
                                setState(() => notifications = v),
                          ),
                        ]),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("SAVE PROFILE"),
                          ),
                        ),

                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 200,
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
            child: CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: bgGrey,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildModernInput(
      TextEditingController c, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: _inputDecoration(label, icon),
      ),
    );
  }
}