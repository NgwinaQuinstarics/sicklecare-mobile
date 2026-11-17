import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../doctor/doctor_dashboard_screen.dart';
import '../doctor/doctor_ui_components.dart';
import '../../models/doctor_profile.dart';
import '../../providers/care_ui_provider.dart';
import '../../services/doctor_application_service.dart';
import '../../widgets/section_card.dart';

/// Validated clinician details submitted to the application service.
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

  Map<String, Object?> toPayload() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'specialty': specialty,
        'licenseNumber': licenseNumber,
        'qualifications': qualifications,
        'facilityName': facilityName,
        'yearsOfExperience': yearsOfExperience,
        'availabilityDays': availabilityDays,
        'bio': bio,
      };
}

typedef DoctorRegistrationSubmitter = Future<void> Function(
  DoctorRegistrationDraft draft,
);

/// Clinician-specific onboarding screen.
///
/// The normal flow creates a Firebase account and submits a server-validated
/// application. [onSubmitted] is retained as a test/preview seam.
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String? _passwordValidator(String? value) {
    if (value == null || value.length < 8) {
      return 'Use a password with at least 8 characters.';
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
      if (submitter != null) {
        await submitter(draft);
        if (!mounted) return;
        _completePreview(draft);
        return;
      }

      final auth = FirebaseAuth.instance;
      final signedInUser = auth.currentUser;
      if (signedInUser == null) {
        try {
          await auth.createUserWithEmailAndPassword(
            email: draft.email,
            password: _passwordController.text,
          );
        } on FirebaseAuthException catch (error) {
          if (error.code != 'email-already-in-use') rethrow;
          await auth.signInWithEmailAndPassword(
            email: draft.email,
            password: _passwordController.text,
          );
        }
      } else if (signedInUser.email?.toLowerCase() !=
          draft.email.toLowerCase()) {
        throw StateError(
          'Sign out and use the same email address as this application.',
        );
      }
      await DoctorApplicationService().createApplication(draft.toPayload());
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth',
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.code == 'email-already-in-use'
            ? 'An account already uses this email. Sign in to that account and continue.'
            : error.message ?? 'The account could not be created.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error is StateError
            ? error.message
            : 'We could not submit your professional application. Check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _completePreview(DoctorRegistrationDraft draft) {
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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DoctorDashboardScreen(
          doctorName: draft.fullName,
          specialty: draft.specialty,
          facilityName: draft.facilityName,
          verificationStatus: DoctorVerificationStatus.pending,
        ),
      ),
      (route) => false,
    );
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: _passwordValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (value) =>
                              value != _passwordController.text
                                  ? 'Passwords do not match.'
                                  : null,
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
                    child: Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        value: _credentialsConfirmed,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                            'I confirm these details and consent to credential review.'),
                        subtitle: Text(
                          'Your credential will be private and viewable only by authorized administrators.',
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
                  if (widget.onSubmitted == null &&
                      Firebase.apps.isNotEmpty &&
                      FirebaseAuth.instance.currentUser != null)
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pushNamedAndRemoveUntil(
                                '/auth',
                                (route) => false,
                              ),
                      child: const Text('Return to application status'),
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
