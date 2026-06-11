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
import '../../widgets/section_card.dart';
import '../profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _version = '${p.version}+${p.buildNumber}');
    }).catchError((_) {});
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse(AppStrings.websiteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      final msg =
          e.code == 'requires-recent-login' ? l.reauthNeeded : (e.message ?? '');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
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
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(l.theme),
                  subtitle: Text(l.themeName(theme.themeMode.name)),
                ),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(l.system)),
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
                  title: Text(l.deleteAccount, style: TextStyle(color: cs.error)),
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
