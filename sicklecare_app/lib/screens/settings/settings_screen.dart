import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/strings.dart';
import '../../constants/app_strings.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../services/care_plan_service.dart';
import '../../services/privacy_data_service.dart';
import '../../widgets/section_card.dart';
import '../history_screen.dart';
import '../profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  List<EmergencyContact> _emergencyContacts = const [];

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _version = '${p.version}+${p.buildNumber}');
    }).catchError((_) {});
    _loadEmergencyContacts();
  }

  void _loadEmergencyContacts() {
    try {
      _emergencyContacts = CarePlanService.getEmergencyContacts();
    } catch (_) {
      _emergencyContacts = const [];
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } catch (e) {
      debugPrint('Error launching $url: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open link. Please try again.')),
        );
      }
    }
  }

  Future<void> _openWebsite() => _launch(AppStrings.websiteUrl);
  Future<void> _openTerms() => _launch(AppStrings.termsUrl);
  Future<void> _openPrivacy() => _launch(AppStrings.privacyUrl);

  Future<void> _exportLocalData() async {
    final l = context.l10n;
    try {
      await PrivacyDataService.shareLocalDataExport();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.failed(e.toString()))));
    }
  }

  Future<void> _deleteLocalHealthData() async {
    final l = context.l10n;
    final trackerProvider = context.read<TrackerProvider>();
    final reminderProvider = context.read<ReminderProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tr('Delete local health data?',
            'Supprimer les données santé locales ?')),
        content: Text(l.tr(
          'This clears check-ins, reminders, Sika chat, local emergency contacts, and scheduled alarms on this phone. Your account remains active.',
          'Cela efface les check-ins, rappels, conversation Sika, contacts d’urgence locaux et alarmes programmées sur ce téléphone. Ton compte reste actif.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PrivacyDataService.deleteLocalHealthData();
      if (!mounted) return;
      await trackerProvider.load();
      await reminderProvider.load();
      setState(() => _emergencyContacts = const []);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr('Local health data deleted.',
              'Données santé locales supprimées.')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.failed(e.toString()))));
    }
  }

  Future<void> _saveEmergencyContacts(
    List<EmergencyContact> contacts,
  ) async {
    await CarePlanService.saveEmergencyContacts(contacts);
    if (!mounted) return;
    setState(() => _emergencyContacts = contacts);
  }

  Future<void> _editEmergencyContact({
    EmergencyContact? contact,
    int? index,
  }) async {
    final l = context.l10n;
    final name = TextEditingController(text: contact?.name ?? '');
    final relationship =
        TextEditingController(text: contact?.relationship ?? '');
    final phone = TextEditingController(text: contact?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(contact == null
            ? l.tr('Add emergency contact', 'Ajouter un contact d’urgence')
            : l.tr('Edit emergency contact', 'Modifier le contact d’urgence')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: InputDecoration(labelText: l.name),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: relationship,
                decoration: InputDecoration(
                  labelText: l.tr('Relationship', 'Lien'),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phone,
                decoration: InputDecoration(labelText: l.phone),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? l.required : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                ctx,
                EmergencyContact(
                  name: name.text,
                  relationship: relationship.text,
                  phone: phone.text,
                ),
              );
            },
            child: Text(l.save),
          ),
        ],
      ),
    );

    name.dispose();
    relationship.dispose();
    phone.dispose();
    if (result == null) return;

    final updated = [..._emergencyContacts];
    if (index == null) {
      updated.add(result);
    } else {
      updated[index] = result;
    }
    await _saveEmergencyContacts(updated);
  }

  Future<void> _deleteEmergencyContact(int index) async {
    final updated = [..._emergencyContacts]..removeAt(index);
    await _saveEmergencyContacts(updated);
  }

  Future<void> _deleteAccount() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAccountConfirm),
        content: Text(l.deleteAccountBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.accountDeleted)));
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'requires-recent-login'
          ? l.reauthNeeded
          : (e.message ?? '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.failed(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = context.watch<ThemeProvider>();
    final localeProv = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final profileName = (auth.profile?['name'] as String?)?.trim();
    final langCode = localeProv.locale?.languageCode ?? 'system';

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SectionCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.person, color: cs.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (profileName != null && profileName.isNotEmpty)
                            ? profileName
                            : l.myProfile,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(auth.user?.email ?? l.tapToEdit,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.security_outlined),
                  title:
                      Text(l.tr('Privacy & data', 'Confidentialité & données')),
                  subtitle: Text(l.tr(
                    'App Check is enabled and health exports stay user-controlled.',
                    'App Check est activé et les exports santé restent contrôlés par l’utilisateur.',
                  )),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_download_outlined),
                  title:
                      Text(l.tr('Export app data', 'Exporter les données app')),
                  subtitle: Text(l.tr(
                    'Share a JSON copy of local check-ins, reminders, care setup, and Sika history.',
                    'Partager une copie JSON locale des check-ins, rappels, paramètres de soin et historique Sika.',
                  )),
                  onTap: _exportLocalData,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(l.tr('Doctor report', 'Rapport médecin')),
                  subtitle: Text(l.tr(
                    'Export your tracking history as a PDF.',
                    'Exporte ton historique de suivi en PDF.',
                  )),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_sweep_outlined, color: cs.error),
                  title: Text(
                    l.tr('Delete local health data',
                        'Supprimer les données santé locales'),
                    style: TextStyle(color: cs.error),
                  ),
                  subtitle: Text(l.tr(
                    'Clear this phone without deleting your account.',
                    'Effacer ce téléphone sans supprimer le compte.',
                  )),
                  onTap: _deleteLocalHealthData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.supervisor_account_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.tr('Caregiver mode', 'Mode aidant'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: l.tr('Add contact', 'Ajouter un contact'),
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _editEmergencyContact(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _emergencyContacts.isEmpty
                      ? l.tr(
                          'Add trusted contacts for Crisis mode. They stay saved on this phone for offline access.',
                          'Ajoute des contacts de confiance pour le mode crise. Ils restent sur ce téléphone pour un accès hors ligne.',
                        )
                      : l.tr(
                          '${_emergencyContacts.length} trusted contact(s) available offline in Crisis mode.',
                          '${_emergencyContacts.length} contact(s) de confiance disponibles hors ligne en mode crise.',
                        ),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                ),
                if (_emergencyContacts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (var i = 0; i < _emergencyContacts.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.contact_phone_outlined),
                      title: Text(
                        _emergencyContacts[i].displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _emergencyContacts[i].detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l.tr('Edit', 'Modifier'),
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editEmergencyContact(
                              contact: _emergencyContacts[i],
                              index: i,
                            ),
                          ),
                          IconButton(
                            tooltip: l.delete,
                            icon: Icon(
                              Icons.delete_outline,
                              color: cs.error,
                            ),
                            onPressed: () => _deleteEmergencyContact(i),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _editEmergencyContact(),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(l.tr(
                      'Add emergency contact', 'Ajouter un contact d’urgence')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(l.theme),
                  subtitle: Text(l.themeName(theme.themeMode.name)),
                ),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                        value: ThemeMode.system, label: Text(l.system)),
                    ButtonSegment(value: ThemeMode.light, label: Text(l.light)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(l.dark)),
                  ],
                  selected: {theme.themeMode},
                  onSelectionChanged: (s) => theme.setMode(s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.language, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(l.language,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l.system),
                      selected: langCode == 'system',
                      onSelected: (_) => localeProv.setLocale(null),
                    ),
                    ChoiceChip(
                      label: const Text('Français'),
                      selected: langCode == 'fr',
                      onSelected: (_) =>
                          localeProv.setLocale(const Locale('fr')),
                    ),
                    ChoiceChip(
                      label: const Text('English'),
                      selected: langCode == 'en',
                      onSelected: (_) =>
                          localeProv.setLocale(const Locale('en')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l.termsLink),
                  onTap: _openTerms,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l.privacyLink),
                  onTap: _openPrivacy,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.public),
                  title: Text(l.website),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: _openWebsite,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.appVersion),
                  subtitle: Text(_version.isEmpty ? '—' : _version),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: Text(l.signOut),
                  onTap: () async {
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever_outlined, color: cs.error),
                  title:
                      Text(l.deleteAccount, style: TextStyle(color: cs.error)),
                  onTap: _deleteAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
