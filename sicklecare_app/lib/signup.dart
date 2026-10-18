import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n/strings.dart';
import 'constants/app_strings.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _genotype = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _acceptTerms = false;
  String? _error;
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _openTerms;
    _privacyTap = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _genotype.dispose();
    super.dispose();
  }

  Future<void> _openTerms() async {
    final uri = Uri.parse(AppStrings.termsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching terms URL: $e');
    }
  }

  Future<void> _openPrivacy() async {
    final uri = Uri.parse(AppStrings.privacyUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching privacy URL: $e');
    }
  }

  Future<void> _signup() async {
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() => _error = l.mustAcceptTerms);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
      try {
        await cred.user?.updateDisplayName(_name.text.trim());
      } catch (e) {
        debugPrint('updateDisplayName failed (known Pigeon bug): $e');
      }
      // Firestore profile creation — non-fatal if rules block it.
      // The profile will be created/merged on next login via AuthProvider.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'genotype': _genotype.text.trim(),
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreErr) {
        debugPrint('Firestore profile write failed (non-fatal): $firestoreErr');
      }
      // Pop the signup screen so the user automatically lands on MainShell
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      final msg = e.message?.toLowerCase() ?? '';
      if (e.code == 'network-request-failed' ||
          msg.contains('failed to connect') ||
          msg.contains('connection reset') ||
          msg.contains('socketexception')) {
        setState(() => _error = context.l10n.networkError);
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('pigeonuserdetails')) {
        // Known bug in firebase_auth 4.16.0 on Android, but user is actually successfully created.
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (str.contains('socketexception') ||
          str.contains('failed to connect') ||
          str.contains('connection reset') ||
          str.contains('network') ||
          str.contains('clientexception')) {
        setState(() => _error = context.l10n.networkError);
      } else {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.createAccount)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset('assets/logo.png',
                            width: 68,
                            height: 68,
                            cacheWidth: 200,
                            fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l.joinSickleCare,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 24, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: l.fullName,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l.required : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? l.validEmail : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _genotype,
                      decoration: InputDecoration(
                        labelText: l.genotypeHint,
                        prefixIcon: const Icon(Icons.science_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pass,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? l.min6 : null,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (v) =>
                              setState(() => _acceptTerms = v ?? false),
                        ),
                        Expanded(
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: l.acceptTermsPrefix),
                            TextSpan(
                              text: l.termsLink,
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _termsTap,
                            ),
                            TextSpan(text: l.and),
                            TextSpan(
                              text: l.privacyLink,
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _privacyTap,
                            ),
                          ])),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: cs.error)),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _loading ? null : _signup,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : Text(l.createAccount),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
