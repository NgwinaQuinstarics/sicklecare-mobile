import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User?            user      = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final nameController    = TextEditingController();
  final ageController     = TextEditingController();
  final contactController = TextEditingController();

  String genotype       = "SS";
  bool   notifications  = true;
  bool   isLoading      = true;

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const _blue      = Color(0xFF1E40AF);
  static const _blueMid   = Color(0xFF2563EB);
  static const _red       = Color(0xFFE53935);
  static const _redLight  = Color(0xFFFFEBEE);
  static const _redBorder = Color(0x40E53935);
  static const _bg        = Color(0xFFF0F4FF);
  static const _white     = Color(0xFFFFFFFF);
  static const _textDark  = Color(0xFF1A237E);
  static const _grey      = Color(0xFF90A4AE);
  static const _shadowSm  = Color(0x10000000);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    contactController.dispose();
    super.dispose();
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    final uid = user?.uid;
    if (uid == null) { setState(() => isLoading = false); return; }
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final d = doc.data()!;
        setState(() {
          nameController.text    = d['name']    ?? '';
          ageController.text     = (d['age']    ?? '').toString();
          contactController.text = d['contact'] ?? '';
          genotype               = d['genotype']      ?? 'SS';
          notifications          = d['notifications'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('LOAD PROFILE ERROR: $e');
    }
    setState(() => isLoading = false);
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    final uid = user?.uid;
    if (uid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _blue)),
    );

    try {
      await firestore.collection('users').doc(uid).set({
        'name':          nameController.text.trim(),
        'age':           int.tryParse(ageController.text.trim()) ?? 0,
        'contact':       contactController.text.trim(),
        'genotype':      genotype,
        'notifications': notifications,
        'updatedAt':     FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully ✅'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (user?.uid == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      backgroundColor: _bg,
      // ── back arrow only — no drawer, no bottom nav ──
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatarCard(),
                        const SizedBox(height: 24),
                        _sectionLabel('PERSONAL INFO'),
                        _buildCard([
                          _input(nameController,    'Full Name', Icons.person_rounded),
                          _input(ageController,     'Age',       Icons.cake_rounded,
                              type: TextInputType.number),
                          _input(contactController, 'Contact',   Icons.phone_rounded,
                              type: TextInputType.phone,
                              isLast: true),
                        ]),
                        const SizedBox(height: 20),
                        _sectionLabel('MEDICAL INFO'),
                        _buildCard([
                          _genotypeSelector(),
                          const SizedBox(height: 4),
                          _genotypeHint(),
                        ]),
                        const SizedBox(height: 20),
                        _sectionLabel('SETTINGS'),
                        _buildCard([
                          _notificationToggle(),
                        ]),
                        const SizedBox(height: 32),
                        _saveButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Sliver AppBar ──────────────────────────────────────────────────────────

  Widget _buildAppBar() => SliverAppBar(
        expandedHeight: 160,
        pinned: true,
        backgroundColor: _blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: FlexibleSpaceBar(
          centerTitle: true,
          title: const Text('My Profile',
              style: TextStyle(
                  color: _white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_blue, _blueMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      );

  // ── Avatar Card ────────────────────────────────────────────────────────────

  Widget _buildAvatarCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: _shadowSm, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_red, Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x4DE53935),
                      blurRadius: 10,
                      offset: Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.person_rounded,
                  color: _white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameController.text.isEmpty
                        ? 'SickleCare Patient'
                        : nameController.text,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(fontSize: 12, color: _grey),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _redLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _redBorder),
                    ),
                    child: Text('Genotype: $genotype',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _red,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Section Label ──────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _grey,
                letterSpacing: 1.2)),
      );

  // ── Card ───────────────────────────────────────────────────────────────────

  Widget _buildCard(List<Widget> children) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: _shadowSm, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );

  // ── Text Input ─────────────────────────────────────────────────────────────

  Widget _input(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool isLast = false,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: isLast ? 12 : 14),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13, color: _grey),
            prefixIcon: Icon(icon, color: _blue, size: 20),
            filled: true,
            fillColor: _bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blueMid, width: 1.5),
            ),
          ),
        ),
      );

  // ── Genotype Selector ──────────────────────────────────────────────────────

  Widget _genotypeSelector() => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: DropdownButtonFormField<String>(
          initialValue: genotype,
          decoration: InputDecoration(
            labelText: 'Genotype',
            labelStyle: const TextStyle(fontSize: 13, color: _grey),
            prefixIcon:
                const Icon(Icons.bloodtype_rounded, color: _red, size: 20),
            filled: true,
            fillColor: _bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blueMid, width: 1.5),
            ),
          ),
          items: ['AA', 'AS', 'SS', 'SC', 'CC']
              .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(g,
                        style: const TextStyle(
                            fontSize: 14, color: _textDark)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => genotype = v);
          },
        ),
      );

  // ── Genotype Hint ──────────────────────────────────────────────────────────

  Widget _genotypeHint() {
    final hints = {
      'SS': ('Sickle Cell Disease — monitor closely', _red),
      'SC': ('Sickle Cell Disease variant — monitor regularly', _red),
      'AS': ('Sickle Cell Trait — carrier, mostly healthy', Color(0xFFE65100)),
      'AA': ('Normal — no sickle cell risk', Color(0xFF2E7D32)),
      'CC': ('Haemoglobin C Disease — consult doctor', Color(0xFF6A1B9A)),
    };
    final hint = hints[genotype];
    if (hint == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: hint.$2),
          const SizedBox(width: 6),
          Expanded(
            child: Text(hint.$1,
                style: TextStyle(
                    fontSize: 11, color: hint.$2, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  // ── Notification Toggle ────────────────────────────────────────────────────

  Widget _notificationToggle() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notifications
                    ? const Color(0xFFE3F2FD)
                    : _bg,
              ),
              child: Icon(
                notifications
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: notifications ? _blue : _grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textDark)),
                  Text(
                    notifications
                        ? 'Reminders and health alerts are on'
                        : 'All notifications are off',
                    style: const TextStyle(fontSize: 11, color: _grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: notifications,
              activeThumbColor: _blue,
              onChanged: (v) => setState(() => notifications = v),
            ),
          ],
        ),
      );

  // ── Save Button ────────────────────────────────────────────────────────────

  Widget _saveButton() => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: _white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            shadowColor: const Color(0x55E53935),
          ).copyWith(
            elevation: WidgetStateProperty.all(4),
          ),
          child: const Text('SAVE PROFILE',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
        ),
      );
}