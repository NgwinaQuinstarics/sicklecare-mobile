import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/doctor_profile.dart';
import '../../providers/care_ui_provider.dart';
import '../../services/doctor_application_service.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';
import 'doctor_ui_components.dart';

/// Captures credential details and optionally submits them for admin review.
class CredentialSubmissionScreen extends StatefulWidget {
  const CredentialSubmissionScreen({
    super.key,
    required this.verificationStatus,
    this.backendManaged = false,
  });

  final DoctorVerificationStatus verificationStatus;
  final bool backendManaged;

  @override
  State<CredentialSubmissionScreen> createState() =>
      _CredentialSubmissionScreenState();
}

class _CredentialSubmissionScreenState
    extends State<CredentialSubmissionScreen> {
  static const _credentialTypes = [
    'Medical practice licence',
    'Specialty certificate',
    'Professional registration',
    'Facility appointment letter',
    'Other qualification',
  ];

  final _formKey = GlobalKey<FormState>();
  final _issuerController = TextEditingController();
  final _referenceController = TextEditingController();
  String _credentialType = _credentialTypes.first;
  String? _selectedFileLabel;
  PlatformFile? _selectedFile;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _issuerController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _choosePreviewDocument() async {
    if (widget.backendManaged) {
      try {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.single;
        if (file.bytes == null) {
          throw StateError('The selected file could not be read.');
        }
        if (file.size < 1 || file.size > 10 * 1024 * 1024) {
          throw ArgumentError('Choose a file smaller than 10 MB.');
        }
        if (!mounted) return;
        setState(() {
          _selectedFile = file;
          _selectedFileLabel = file.name;
          _error = null;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _error = error is ArgumentError
            ? error.message
            : 'The credential file could not be selected. Please try again.');
      }
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attach a preview document',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'File upload will be connected only after storage, privacy, and review requirements are agreed.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final file in const [
                    'medical_licence.pdf',
                    'specialty_certificate.pdf',
                    'professional_registration.pdf',
                  ])
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(file),
                      onTap: () => Navigator.pop(context, file),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (choice != null && mounted) setState(() => _selectedFileLabel = choice);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedFileLabel == null ||
        (widget.backendManaged && _selectedFile?.bytes == null)) {
      setState(() => _error = 'Choose a credential file to continue.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    if (widget.backendManaged) {
      try {
        final file = _selectedFile!;
        await DoctorApplicationService().uploadCredential(
          bytes: file.bytes!,
          fileExtension:
              file.extension ?? file.name.split('.').last.toLowerCase(),
          credentialType: _credentialType,
          issuer: _issuerController.text.trim(),
          referenceNumber: _referenceController.text.trim(),
        );
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _error = error is StateError
              ? error.message.toString()
              : error is ArgumentError
                  ? error.message?.toString() ??
                      'The selected credential is invalid.'
                  : 'The credential could not be submitted. Check your connection and try again.';
        });
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth',
        (route) => false,
      );
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    final wasSaved = context.read<CareUiProvider>().submitDoctorCredential(
          DoctorCredential(
            id: 'preview-credential-${DateTime.now().millisecondsSinceEpoch}',
            title: _credentialType,
            issuedBy: _issuerController.text.trim(),
            submittedAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!wasSaved) {
      setState(() => _error = context.read<CareUiProvider>().errorMessage);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credential added to this UI preview for review.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = widget.backendManaged
        ? null
        : context.watch<CareUiProvider>().doctorProfile;
    final verificationStatus =
        profile?.verificationStatus ?? widget.verificationStatus;
    return Scaffold(
      appBar: AppBar(title: const Text('Submit credentials')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                children: [
                  DoctorStatusBanner(
                    status: verificationStatus,
                    title: 'Credential review',
                    message: verificationStatus ==
                            DoctorVerificationStatus.rejected
                        ? 'Update the requested document and submit the revised version.'
                        : 'Add professional documentation for the verification workflow.',
                  ),
                  const SizedBox(height: 16),
                  StatusBanner(
                    tone: StatusBannerTone.info,
                    title: widget.backendManaged
                        ? 'Private document submission'
                        : 'Temporary submission flow',
                    message: widget.backendManaged
                        ? 'Your credential is stored privately and can be reviewed only by an authorized administrator.'
                        : 'Documents are represented by a local preview selection only. Nothing is uploaded or retained outside this session.',
                  ),
                  const SizedBox(height: 18),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Credential details',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _credentialType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Document type',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: _credentialTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _submitting
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _credentialType = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _issuerController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Issuing organisation',
                            hintText: 'Medical council or training institution',
                            prefixIcon: Icon(Icons.account_balance_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter the issuing organisation.'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _referenceController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Reference number (optional)',
                            prefixIcon: Icon(Icons.tag_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed:
                              _submitting ? null : _choosePreviewDocument,
                          icon: const Icon(Icons.attach_file_outlined),
                          label: Text(
                            _selectedFileLabel == null
                                ? widget.backendManaged
                                    ? 'Choose credential file'
                                    : 'Attach preview document'
                                : _selectedFileLabel!,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (profile != null && profile.credentials.isNotEmpty)
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Existing credentials',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          for (final credential in profile.credentials) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.description_outlined,
                                  color: cs.primary),
                              title: Text(credential.title),
                              subtitle: Text(credential.issuedBy),
                              trailing: DoctorStatusPill(
                                status: credential.status,
                                compact: true,
                              ),
                            ),
                            if (credential != profile.credentials.last)
                              const Divider(),
                          ],
                        ],
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    StatusBanner(
                      tone: StatusBannerTone.error,
                      title: 'Credential not added',
                      message: _error,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(
                        _submitting ? 'Adding credential…' : 'Add for review'),
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
