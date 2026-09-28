import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_strings.dart';
import '../../models/warrior_health_profile.dart';
import '../../providers/care_ui_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';

/// A concise emergency information card. The medical values shown are mock
/// data and it deliberately routes urgent needs to local emergency services.
class EmergencyInformationScreen extends StatefulWidget {
  const EmergencyInformationScreen({super.key});

  @override
  State<EmergencyInformationScreen> createState() =>
      _EmergencyInformationScreenState();
}

class _EmergencyInformationScreenState
    extends State<EmergencyInformationScreen> {
  Future<void> _call(String number, String unavailableMessage) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    try {
      final didLaunch = await launchUrl(uri);
      if (!didLaunch && mounted) _showUnavailable(unavailableMessage);
    } catch (_) {
      if (mounted) _showUnavailable(unavailableMessage);
    }
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editContact(EmergencyContact contact) async {
    final name = TextEditingController(text: contact.name);
    final relation = TextEditingController(text: contact.relationship);
    final phone = TextEditingController(text: contact.phoneNumber);
    final alternate =
        TextEditingController(text: contact.alternatePhoneNumber ?? '');
    final formKey = GlobalKey<FormState>();
    final updated = await showModalBottomSheet<EmergencyContact>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit emergency contact',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'This changes only the local UI preview.',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Contact name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a contact name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: relation,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter the relationship.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Primary phone'),
                  validator: (value) => value == null || value.trim().length < 7
                      ? 'Enter a valid phone number.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: alternate,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Alternative phone (optional)'),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    Navigator.pop(
                      sheetContext,
                      contact.copyWith(
                        name: name.text.trim(),
                        relationship: relation.text.trim(),
                        phoneNumber: phone.text.trim(),
                        alternatePhoneNumber: alternate.text.trim().isEmpty
                            ? null
                            : alternate.text.trim(),
                        clearAlternatePhoneNumber:
                            alternate.text.trim().isEmpty,
                      ),
                    );
                  },
                  child: const Text('Save preview contact'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    name.dispose();
    relation.dispose();
    phone.dispose();
    alternate.dispose();
    if (updated != null && mounted) {
      context.read<CareUiProvider>().updateEmergencyContact(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Emergency contact updated in this preview.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CareUiProvider>().warriorProfile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final contact = profile.emergencyContact;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency information')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                StatusBanner(
                  tone: StatusBannerTone.error,
                  title: 'Seek urgent help for serious symptoms',
                  message:
                      'Severe pain, chest pain, breathing trouble, fever, weakness on one side, or confusion need urgent medical assessment.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.error.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.emergency_rounded, color: cs.error, size: 36),
                      const SizedBox(height: 14),
                      Text(
                        'Emergency card',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: cs.onErrorContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Show this information to a clinician when you need urgent care. Confirm all medical information with your care team.',
                        style:
                            TextStyle(color: cs.onErrorContainer, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                        ),
                        onPressed: () => _call(
                          AppStrings.emergencyHotline,
                          'Emergency calling is unavailable on this device.',
                        ),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Call emergency services (112)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _InfoGroup(
                  title: 'Essential health details',
                  children: [
                    _InfoLine(
                      icon: Icons.bloodtype_outlined,
                      label: 'Genotype',
                      value: profile.genotype,
                    ),
                    _InfoLine(
                      icon: Icons.water_drop_outlined,
                      label: 'Blood group',
                      value: profile.bloodGroup,
                    ),
                    _InfoLine(
                      icon: Icons.local_hospital_outlined,
                      label: 'Primary facility',
                      value: profile.primaryFacilityName,
                    ),
                    _InfoLine(
                      icon: Icons.medical_services_outlined,
                      label: 'Primary clinician',
                      value: profile.primaryDoctorName ?? 'Not added yet',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoGroup(
                  title: 'Allergies & care notes',
                  children: [
                    _InfoLine(
                      icon: Icons.warning_amber_outlined,
                      label: 'Allergies',
                      value: profile.allergies.join(', '),
                    ),
                    _InfoLine(
                      icon: Icons.note_alt_outlined,
                      label: 'Care notes',
                      value: profile.careNotes,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Emergency contact',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit emergency contact',
                            onPressed: () => _editContact(contact),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        contact.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        contact.relationship,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _call(
                          contact.phoneNumber,
                          'Calling this contact is unavailable on this device.',
                        ),
                        icon: const Icon(Icons.phone_outlined),
                        label: Text(contact.phoneNumber),
                      ),
                      if (contact.alternatePhoneNumber != null) ...[
                        const SizedBox(height: 8),
                        Text('Alternative: ${contact.alternatePhoneNumber}'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StatusBanner(
                  tone: StatusBannerTone.warning,
                  title: 'Preview information only',
                  message:
                      'This screen uses fictional values. Do not rely on it as a medical emergency record until secure profile and emergency-contact storage are agreed.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
