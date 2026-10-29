import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n/strings.dart';
import 'constants/app_strings.dart';
import 'auth_gate.dart';
import 'widgets/section_card.dart';

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
      _finishSignup();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.message?.toLowerCase() ?? '';
      if (e.code == 'network-request-failed' ||
          msg.contains('failed to connect') ||
          msg.contains('connection reset') ||
          msg.contains('socketexception')) {
        setState(() => _error = context.l10n.networkError);
      } else {
        setState(() => _error = _signupErrorMessage(e, l));
      }
    } catch (e) {
      if (!mounted) return;
      final str = e.toString().toLowerCase();
      if (str.contains('pigeonuserdetails')) {
        // Known bug in firebase_auth 4.16.0 on Android, but user is actually successfully created.
        _finishSignup();
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

  String _signupErrorMessage(FirebaseAuthException error, L10n l) {
    switch (error.code) {
      case 'email-already-in-use':
        return l.tr(
          'An account already uses this email. Try signing in instead.',
          'Un compte utilise déjà cet e-mail. Essaie plutôt de te connecter.',
        );
      case 'invalid-email':
        return l.validEmail;
      case 'weak-password':
        return l.tr(
          'Choose a password with at least 6 characters.',
          'Choisis un mot de passe d’au moins 6 caractères.',
        );
      case 'operation-not-allowed':
        return l.tr(
          'Account creation is unavailable right now. Please try again later.',
          'La création de compte est indisponible pour le moment. Réessaie plus tard.',
        );
      default:
        return error.message ??
            l.tr(
              'We could not create your account. Please try again.',
              'Nous n’avons pas pu créer ton compte. Réessaie.',
            );
    }
  }

  /// Starts a fresh authenticated navigation stack after account creation.
  /// This removes the signup and role-selection routes, preventing Back from
  /// reopening onboarding after the account is already active.
  void _finishSignup() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  /// Returns to the existing sign-in route without asking a warrior to walk
  /// back through role selection first.
  void _returnToSignIn() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('Create warrior account', 'Créer un compte warrior')),
      ),
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
                    const SizedBox(height: 8),
                    Text(
                      l.tr(
                        'A personal space for your everyday care planning.',
                        'Un espace personnel pour organiser tes soins au quotidien.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    SectionCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.favorite_outline,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.tr('Warrior account', 'Compte warrior'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  l.tr(
                                    'Start with the basics. You can review health details later in your profile.',
                                    'Commence par l’essentiel. Tu pourras revoir tes informations de santé plus tard dans ton profil.',
                                  ),
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
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
                    TextFormField(
                      controller: _name,
                      enabled: !_loading,
                      autofillHints: const [AutofillHints.name],
                      textCapitalization: TextCapitalization.words,
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
                      enabled: !_loading,
                      autofillHints: const [AutofillHints.email],
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
                      key: const Key('warrior-signup-genotype'),
                      controller: _genotype,
                      enabled: !_loading,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l.tr(
                          'Genotype (optional)',
                          'Génotype (facultatif)',
                        ),
                        helperText: l.tr(
                          'You can add or update this later.',
                          'Tu peux l’ajouter ou le modifier plus tard.',
                        ),
                        prefixIcon: const Icon(Icons.science_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pass,
                      enabled: !_loading,
                      autofillHints: const [AutofillHints.newPassword],
                      enableSuggestions: false,
                      autocorrect: false,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
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
                          onChanged: _loading
                              ? null
                              : (v) =>
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
                      key: const Key('warrior-signup-submit'),
                      onPressed: _loading ? null : _signup,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l.createAccount),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: _loading ? null : _returnToSignIn,
                        icon: const Icon(Icons.login_outlined),
                        label: Text(l.tr(
                          'Already have an account? Sign in',
                          'Tu as déjà un compte ? Connecte-toi',
                        )),
                      ),
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
