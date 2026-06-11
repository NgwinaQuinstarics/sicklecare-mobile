import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/strings.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? context.l10n.loginFailed);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final l = context.l10n;
    if (_email.text.trim().isEmpty) {
      setState(() => _error = l.enterEmailReset);
      return;
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _email.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.resetEmailSent)),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;
    return Scaffold(
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
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/AppIcon.png',
                            width: 84, height: 84, cacheWidth: 240, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(l.welcomeBack,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 26, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(l.signInSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 28),
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
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: cs.error)),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: Text(l.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : Text(l.signIn),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l.noAccount),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen()),
                          ),
                          child: Text(l.signUp),
                        ),
                      ],
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
