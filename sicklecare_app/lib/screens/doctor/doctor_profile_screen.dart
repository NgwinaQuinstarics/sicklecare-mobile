import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/doctor_profile.dart';
import '../../providers/care_ui_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';
import 'doctor_ui_components.dart';

/// A clinician-facing professional profile with a local edit mode.
/// When a preview [DoctorProfile] is supplied, edits remain in the in-memory
/// UI provider; no backend profile fields are created or changed.
class DoctorProfessionalProfileScreen extends StatefulWidget {
  const DoctorProfessionalProfileScreen({
    super.key,
    required this.fullName,
    required this.specialty,
    required this.facilityName,
    required this.verificationStatus,
    this.profile,
  });

  final String fullName;
  final String specialty;
  final String facilityName;
  final DoctorVerificationStatus verificationStatus;
  final DoctorProfile? profile;

  @override
  State<DoctorProfessionalProfileScreen> createState() =>
      _DoctorProfessionalProfileScreenState();
}

class _DoctorProfessionalProfileScreenState
    extends State<DoctorProfessionalProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _specialty;
  late final TextEditingController _facility;
  late final TextEditingController _bio;
  late final TextEditingController _availability;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  bool _saving = false;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: profile?.fullName ?? widget.fullName);
    _specialty =
        TextEditingController(text: profile?.specialty ?? widget.specialty);
    _facility = TextEditingController(
        text: profile?.facilityName ?? widget.facilityName);
    _bio = TextEditingController(
      text: profile?.bio.isNotEmpty == true
          ? profile!.bio
          : 'Clinical care profile preview. Add a short professional introduction for people seeking support.',
    );
    _availability = TextEditingController(
      text: profile?.availabilitySummary ?? 'Mon–Fri · 08:00–16:00',
    );
    _phone = TextEditingController(
      text: profile?.phoneNumber ?? '+237 6XX XXX XXX',
    );
    _email = TextEditingController(
      text: profile?.email ?? 'doctor@example.test',
    );
    _isAvailable = profile?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _specialty.dispose();
    _facility.dispose();
    _bio.dispose();
    _availability.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    final profile = widget.profile;
    if (profile != null) {
      context.read<CareUiProvider>().updateDoctorProfile(
            profile.copyWith(
              fullName: _name.text.trim(),
              specialty: _specialty.text.trim(),
              facilityName: _facility.text.trim(),
              bio: _bio.text.trim(),
              availabilitySummary: _availability.text.trim(),
              phoneNumber: _phone.text.trim(),
              email: _email.text.trim(),
              isAvailable: _isAvailable,
            ),
          );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Professional profile updated in this preview.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional profile'),
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
                  SectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DoctorAvatar(
                          name: _name.text,
                          radius: 34,
                          showAvailability: true,
                          isAvailable: _isAvailable,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _specialty.text,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 10),
                              DoctorStatusPill(
                                  status: widget.verificationStatus),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatusBanner(
                    tone: StatusBannerTone.info,
                    title: 'Preview profile',
                    message:
                        'Edits are visible only in this screen while the professional-profile data contract is being finalised.',
                  ),
                  const SizedBox(height: 20),
                  _ProfileSection(
                    title: 'Professional details',
                    child: Column(
                      children: [
                        _ProfileField(
                          controller: _name,
                          label: 'Display name',
                          icon: Icons.person_outline,
                          editing: _editing,
                          textCapitalization: TextCapitalization.words,
                          validator: _required('a display name'),
                          onChanged: (_) => setState(() {}),
                        ),
                        _ProfileField(
                          controller: _specialty,
                          label: 'Specialty',
                          icon: Icons.medical_services_outlined,
                          editing: _editing,
                          textCapitalization: TextCapitalization.words,
                          validator: _required('a specialty'),
                          onChanged: (_) => setState(() {}),
                        ),
                        _ProfileField(
                          controller: _facility,
                          label: 'Facility',
                          icon: Icons.local_hospital_outlined,
                          editing: _editing,
                          textCapitalization: TextCapitalization.words,
                          validator: _required('a facility'),
                        ),
                        _ProfileField(
                          controller: _bio,
                          label: 'About your practice',
                          icon: Icons.subject_outlined,
                          editing: _editing,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileSection(
                    title: 'Availability & contact',
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.toggle_on_outlined),
                          title: const Text('Available for care'),
                          subtitle: Text(
                            _isAvailable
                                ? 'People can see your current availability.'
                                : 'Your profile shows that you are unavailable.',
                          ),
                          value: _isAvailable,
                          onChanged: _editing
                              ? (value) => setState(() => _isAvailable = value)
                              : null,
                        ),
                        _ProfileField(
                          controller: _availability,
                          label: 'Availability summary',
                          icon: Icons.schedule_outlined,
                          editing: _editing,
                        ),
                        _ProfileField(
                          controller: _phone,
                          label: 'Professional phone',
                          icon: Icons.phone_outlined,
                          editing: _editing,
                          keyboardType: TextInputType.phone,
                        ),
                        _ProfileField(
                          controller: _email,
                          label: 'Professional email',
                          icon: Icons.email_outlined,
                          editing: _editing,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            return RegExp(r'^\S+@\S+\.\S+$')
                                    .hasMatch(value.trim())
                                ? null
                                : 'Enter a valid email address.';
                          },
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.editing,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool editing;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
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
          onChanged: onChanged,
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
