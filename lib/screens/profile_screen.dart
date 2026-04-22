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

  // Professional Aesthetic Palette
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
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryBlue)),
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
          behavior: SnackBarBehavior.floating,
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
                          _buildModernInput(nameController, "Legal Full Name", Icons.badge_outlined),
                          _buildModernInput(ageController, "Current Age", Icons.calendar_today_outlined, type: TextInputType.number),
                          _buildModernInput(contactController, "Emergency Contact", Icons.contact_emergency_outlined, type: TextInputType.phone),
                        ]),
                        
                        const SizedBox(height: 24),
                        
                        _buildSectionHeader("CLINICAL DATA"),
                        _buildProfileCard([
                          DropdownButtonFormField<String>(
                            initialValue: genotype, // FIXED: initialValue used here
                            decoration: _inputDecoration("Blood Genotype", Icons.bloodtype_outlined),
                            items: ["AA", "AS", "SS"]
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) => setState(() => genotype = v!),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        _buildSectionHeader("SYSTEM PREFERENCES"),
                        _buildProfileCard([
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Health Notifications", style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text("Receive automated hydration and medication alerts"),
                            value: notifications,
                            activeThumbColor: accentBlue, // FIXED: activeThumbColor used here
                            onChanged: (v) => setState(() => notifications = v),
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
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("COMMIT CHANGES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
      expandedHeight: 200.0,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text("PROFILE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, accentBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withAlpha(40),
              child: const Icon(Icons.person_outline_rounded, size: 45, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.2)),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: children),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: bgGrey,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    );
  }

  Widget _buildModernInput(TextEditingController c, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        keyboardType: type,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: _inputDecoration(label, icon),
      ),
    );
  }
}