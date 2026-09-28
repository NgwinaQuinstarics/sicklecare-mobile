import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../doctor/doctor_dashboard_screen.dart';
import '../doctor/doctor_ui_components.dart';
import '../doctor/doctor_verification_status_screen.dart';
import '../../models/doctor_profile.dart';
import '../../providers/care_ui_provider.dart';
import '../../widgets/section_card.dart';

/// UI-facing data emitted after a valid clinician registration form is
/// submitted. The integration layer can map this lightweight draft to its
/// domain model or backend request without making this screen Firebase-aware.
class DoctorRegistrationDraft {
  const DoctorRegistrationDraft({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.specialty,
    required this.licenseNumber,
    required this.qualifications,
    required this.facilityName,
    required this.yearsOfExperience,
    required this.availabilityDays,
    required this.bio,
  });

  final String fullName;
  final String email;
  final String phone;
  final String specialty;
  final String licenseNumber;
  final String qualifications;
  final String facilityName;
  final int yearsOfExperience;
  final List<String> availabilityDays;
  final String bio;
}

typedef DoctorRegistrationSubmitter = Future<void> Function(
  DoctorRegistrationDraft draft,
);

/// Clinician-specific onboarding screen.
///
/// It is deliberately presentation-only: if [onSubmitted] is omitted, it
/// uses a brief in-memory loading state and routes to the mock dashboard.
class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({
    super.key,
    this.onSubmitted,
  });

  final DoctorRegistrationSubmitter? onSubmitted;

  @override
  State<DoctorRegistrationScreen> createState() =>
      _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  static const _specialties = [
    'Haematology',
    'General practice',
    'Paediatrics',
    'Internal medicine',
    'Nursing',
    'Pharmacy',
    'Other',
  ];

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _facilityController = TextEditingController();
  final _yearsController = TextEditingController();
  final _bioController = TextEditingController();

  String _specialty = _specialties.first;
  final Set<String> _availabilityDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};
  bool _credentialsConfirmed = false;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _qualificationsController.dispose();
    _facilityController.dispose();
    _yearsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Enter your $label.';
    return null;
  }

  String? _emailValidator(String? value) {
    final required = _required(value, 'email address');
    if (required != null) return required;
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_availabilityDays.isEmpty) {
      setState(() {
        _submitError = 'Choose at least one day that you are available.';
      });
      return;
    }
    if (!_credentialsConfirmed) {
      setState(() {
        _submitError =
            'Please confirm that the professional information is accurate.';
      });
      return;
    }

    final years = int.tryParse(_yearsController.text.trim());
    if (years == null || years < 0 || years > 80) {
      setState(() {
        _submitError = 'Enter a valid number of years of experience.';
      });
      return;
    }

    final draft = DoctorRegistrationDraft(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      specialty: _specialty,
      licenseNumber: _licenseController.text.trim(),
      qualifications: _qualificationsController.text.trim(),
      facilityName: _facilityController.text.trim(),
      yearsOfExperience: years,
      availabilityDays:
          _weekdays.where(_availabilityDays.contains).toList(growable: false),
      bio: _bioController.text.trim(),
    );

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final submitter = widget.onSubmitted;
      if (submitter == null) {
        await Future<void>.delayed(const Duration(milliseconds: 850));
      } else {
        await submitter(draft);
      }
      if (!mounted) return;

      // Preserve the information the clinician just entered for the remainder
      // of this preview session. This state is in-memory only and never
      // creates a Firebase profile or uploads a credential.
      final qualifications = draft.qualifications
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      context.read<CareUiProvider>().updateDoctorProfile(
            DoctorProfile(
              id: 'preview-doctor-${DateTime.now().millisecondsSinceEpoch}',
              fullName: draft.fullName,
              specialty: draft.specialty,
              qualifications: qualifications.isEmpty
                  ? [draft.qualifications]
                  : qualifications,
              facilityName: draft.facilityName,
              email: draft.email,
              phoneNumber: draft.phone,
              availabilitySummary:
                  '${draft.availabilityDays.join(', ')} · Hours to be confirmed',
              isAvailable: true,
              verificationStatus: DoctorVerificationStatus.pending,
              credentials: const [],
              bio: draft.bio,
            ),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Professional profile created. Credentials are ready for review.'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DoctorDashboardScreen(
            doctorName: draft.fullName,
            specialty: draft.specialty,
            facilityName: draft.facilityName,
            verificationStatus: DoctorVerificationStatus.pending,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitError =
            'We could not create your professional profile. Check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Create clinician profile')),
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
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                children: [
                  SectionCard(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary,
                        Color.lerp(cs.primary, Colors.black, 0.2)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.medical_information_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Build a trusted care profile',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your details stay in this profile while professional credentials are reviewed.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const DoctorSectionHeader(
                    title: 'About you',
                    subtitle:
                        'Use the professional details you want patients to see.',
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full professional name',
                            hintText: 'e.g. Dr. Amina Nfor',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) => _required(value, 'full name'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Professional email',
                            hintText: 'name@hospital.org',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            hintText: '+237 6XX XXX XXX',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) =>
                              _required(value, 'phone number'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const DoctorSectionHeader(
                    title: 'Professional details',
                    subtitle:
                        'These details help people find appropriate care.',
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _specialty,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Primary specialty',
                            prefixIcon: Icon(Icons.medical_services_outlined),
                          ),
                          items: _specialties
                              .map(
                                (specialty) => DropdownMenuItem(
                                  value: specialty,
                                  child: Text(specialty),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _isSubmitting
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _specialty = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _qualificationsController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Qualifications',
                            hintText: 'e.g. MBBS, MSc Haematology',
                            prefixIcon: Icon(Icons.workspace_premium_outlined),
                          ),
                          validator: (value) =>
                              _required(value, 'qualifications'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _licenseController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Professional registration number',
                            hintText: 'Enter the number shown on your licence',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) =>
                              _required(value, 'registration number'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _facilityController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Primary facility or practice',
                            hintText: 'e.g. Regional Hospital Buea',
                            prefixIcon: Icon(Icons.local_hospital_outlined),
                          ),
                          validator: (value) =>
                              _required(value, 'facility or practice'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _yearsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Years of clinical experience',
                            hintText: '0',
                            prefixIcon: Icon(Icons.timeline_outlined),
                          ),
                          validator: (value) {
                            final required =
                                _required(value, 'years of experience');
                            if (required != null) return required;
                            final years = int.tryParse(value!.trim());
                            if (years == null || years < 0 || years > 80) {
                              return 'Enter a number from 0 to 80.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const DoctorSectionHeader(
                    title: 'Availability',
                    subtitle:
                        'You can refine hours and appointment rules later.',
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usual working days',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select each day you usually accept consultations.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _weekdays
                              .map(
                                (day) => FilterChip(
                                  label: Text(day),
                                  selected: _availabilityDays.contains(day),
                                  onSelected: _isSubmitting
                                      ? null
                                      : (selected) {
                                          setState(() {
                                            if (selected) {
                                              _availabilityDays.add(day);
                                            } else {
                                              _availabilityDays.remove(day);
                                            }
                                            _submitError = null;
                                          });
                                        },
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const DoctorSectionHeader(
                    title: 'Short introduction',
                    subtitle:
                        'Optional, patient-friendly information about your care approach.',
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    child: TextFormField(
                      controller: _bioController,
                      minLines: 4,
                      maxLines: 6,
                      maxLength: 400,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Professional bio',
                        hintText:
                            'Share your areas of focus and approach to care.',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: CheckboxListTile(
                      value: _credentialsConfirmed,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                          'I confirm these professional details are accurate.'),
                      subtitle: Text(
                        'You will be asked to submit supporting credentials next.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _credentialsConfirmed = value ?? false;
                                _submitError = null;
                              });
                            },
                    ),
                  ),
                  if (_submitError != null) ...[
                    const SizedBox(height: 14),
                    _RegistrationError(message: _submitError!),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'Creating profile…'
                          : 'Create professional profile',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const DoctorVerificationStatusScreen(
                                  status: DoctorVerificationStatus.pending,
                                ),
                              ),
                            ),
                    child: const Text(
                        'Already submitted? View verification status'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationError extends StatelessWidget {
  const _RegistrationError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: cs.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: cs.onErrorContainer, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
