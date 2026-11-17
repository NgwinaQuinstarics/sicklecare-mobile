import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/warrior_health_profile.dart';
import '../../providers/care_ui_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';

/// Editable presentation of a warrior's health profile.
///
/// Saving updates only [CareUiProvider]'s in-memory preview state.
class WarriorHealthProfileScreen extends StatefulWidget {
  const WarriorHealthProfileScreen({super.key, required this.profile});

  final WarriorHealthProfile profile;

  @override
  State<WarriorHealthProfileScreen> createState() =>
      _WarriorHealthProfileScreenState();
}

class _WarriorHealthProfileScreenState
    extends State<WarriorHealthProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bloodGroup;
  late final TextEditingController _genotype;
  late final TextEditingController _facility;
  late final TextEditingController _doctor;
  late final TextEditingController _allergies;
  late final TextEditingController _triggers;
  late final TextEditingController _careNotes;
  late final TextEditingController _goal;
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: profile.displayName);
    _bloodGroup = TextEditingController(text: profile.bloodGroup);
    _genotype = TextEditingController(text: profile.genotype);
    _facility = TextEditingController(text: profile.primaryFacilityName);
    _doctor = TextEditingController(text: profile.primaryDoctorName ?? '');
    _allergies = TextEditingController(text: profile.allergies.join(', '));
    _triggers = TextEditingController(text: profile.knownTriggers.join(', '));
    _careNotes = TextEditingController(text: profile.careNotes);
    _goal = TextEditingController(text: profile.hydrationGoalMl.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _bloodGroup.dispose();
    _genotype.dispose();
    _facility.dispose();
    _doctor.dispose();
    _allergies.dispose();
    _triggers.dispose();
    _careNotes.dispose();
    _goal.dispose();
    super.dispose();
  }

  List<String> _terms(TextEditingController controller) => controller.text
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final goal = int.tryParse(_goal.text.trim());
    if (goal == null || goal < 250 || goal > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a hydration goal between 250 and 10,000 ml.')),
      );
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    context.read<CareUiProvider>().updateWarriorProfile(
          widget.profile.copyWith(
            displayName: _name.text.trim(),
            bloodGroup: _bloodGroup.text.trim(),
            genotype: _genotype.text.trim(),
            primaryFacilityName: _facility.text.trim(),
            primaryDoctorName:
                _doctor.text.trim().isEmpty ? null : _doctor.text.trim(),
            clearPrimaryDoctorName: _doctor.text.trim().isEmpty,
            allergies: _terms(_allergies),
            knownTriggers: _terms(_triggers),
            careNotes: _careNotes.text.trim(),
            hydrationGoalMl: goal,
          ),
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Health profile updated in this UI preview.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        context.watch<CareUiProvider>().warriorProfile ?? widget.profile;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health profile'),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    if (_editing) {
                      _save();
                    } else {
                      setState(() => _editing = true);
                    }
                  },
            child: Text(_editing ? 'Save' : 'Edit'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                children: [
                  StatusBanner(
                    tone: StatusBannerTone.info,
                    title: 'Health details preview',
                    message:
                        'Keep this card concise and verify care decisions with a clinician. These values stay in memory only.',
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: cs.primary.withValues(alpha: 0.12),
                          child: Icon(Icons.favorite_outline,
                              color: cs.primary, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${profile.genotype} · Blood group ${profile.bloodGroup}',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HealthSection(
                    title: 'Essential details',
                    child: Column(
                      children: [
                        _HealthField(
                          controller: _name,
                          label: 'Display name',
                          icon: Icons.person_outline,
                          editing: _editing,
                          textCapitalization: TextCapitalization.words,
                          validator: _required('a display name'),
                        ),
                        _HealthField(
                          controller: _genotype,
                          label: 'Genotype',
                          icon: Icons.bloodtype_outlined,
                          editing: _editing,
                          textCapitalization: TextCapitalization.characters,
                          validator: _required('a genotype'),
                        ),
                        _HealthField(
                          controller: _bloodGroup,
                          label: 'Blood group',
                          icon: Icons.water_drop_outlined,
                          editing: _editing,
                          textCapitalization: TextCapitalization.characters,
                        ),
                        _HealthField(
                          controller: _goal,
                          label: 'Daily hydration goal (ml)',
                          icon: Icons.local_drink_outlined,
                          editing: _editing,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HealthSection(
                    title: 'Care team',
                    child: Column(
                      children: [
                        _HealthField(
                          controller: _facility,
                          label: 'Primary facility',
                          icon: Icons.local_hospital_outlined,
                          editing: _editing,
                          textCapitalization: TextCapitalization.words,
                          validator: _required('a primary facility'),
                        ),
                        _HealthField(
                          controller: _doctor,
                          label: 'Primary clinician',
                          icon: Icons.medical_services_outlined,
                          editing: _editing,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HealthSection(
                    title: 'Safety notes',
                    child: Column(
                      children: [
                        _HealthField(
                          controller: _allergies,
                          label: 'Allergies (comma-separated)',
                          icon: Icons.warning_amber_outlined,
                          editing: _editing,
                          maxLines: 2,
                        ),
                        _HealthField(
                          controller: _triggers,
                          label: 'Known triggers (comma-separated)',
                          icon: Icons.bolt_outlined,
                          editing: _editing,
                          maxLines: 2,
                        ),
                        _HealthField(
                          controller: _careNotes,
                          label: 'Care notes',
                          icon: Icons.note_alt_outlined,
                          editing: _editing,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_saving ? 'Saving…' : 'Save preview changes'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? Function(String?) _required(String label) {
    return (value) =>
        value == null || value.trim().isEmpty ? 'Enter $label.' : null;
  }
}

class _HealthSection extends StatelessWidget {
  const _HealthSection({required this.title, required this.child});

  final String title;
  final Widget child;

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
          child,
        ],
      ),
    );
  }
}

class _HealthField extends StatelessWidget {
  const _HealthField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.editing,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool editing;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          validator: validator,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.text.isEmpty ? 'Not added yet' : controller.text,
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
