import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/section_card.dart';
import '../widgets/status_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _genotype = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  bool _seeded = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.watch<AuthProvider>().profile;
    if (!_seeded && profile != null) {
      _name.text = profile['name'] as String? ?? '';
      _genotype.text = profile['genotype'] as String? ?? '';
      _phone.text = profile['phone'] as String? ?? '';
      _seeded = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _genotype.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().updateProfile({
        'name': _name.text.trim(),
        'genotype': _genotype.text.trim(),
        'phone': _phone.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.profileUpdated)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = l.tr(
          'We could not save your profile. Check your connection and try again.',
          'Nous n’avons pas pu enregistrer votre profil. Vérifiez votre connexion et réessayez.',
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
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
                  Text(
                    auth.user?.email ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              StatusBanner(
                tone: StatusBannerTone.error,
                title: l.tr('Profile not saved', 'Profil non enregistré'),
                message: _error,
              ),
            ],
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l.fullName),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l.required
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _genotype,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(labelText: l.genotype),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l.phone),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty || phone.length >= 7) return null;
                      return l.tr(
                        'Enter a valid phone number',
                        'Entrez un numéro de téléphone valide',
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
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
      ),
    );
  }
}
