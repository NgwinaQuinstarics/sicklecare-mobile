import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/section_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _genotype = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthProvider>().profile ?? {};
    _name.text = p['name'] ?? '';
    _genotype.text = p['genotype'] ?? '';
    _phone.text = p['phone'] ?? '';
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _loading = true);
    await context.read<AuthProvider>().updateProfile({
      'name': _name.text.trim(),
      'genotype': _genotype.text.trim(),
      'phone': _phone.text.trim(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.profileUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SectionCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.person, size: 36, color: cs.primary),
                ),
                const SizedBox(height: 12),
                Text(auth.user?.email ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              children: [
                TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l.fullName)),
                const SizedBox(height: 10),
                TextField(
                    controller: _genotype,
                    decoration: InputDecoration(labelText: l.genotype)),
                const SizedBox(height: 10),
                TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l.phone)),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l.saveChanges),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l.signOut),
              onTap: () async {
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
