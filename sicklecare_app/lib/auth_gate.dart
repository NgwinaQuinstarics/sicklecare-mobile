import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';
import 'models/doctor_profile.dart';
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/doctor/doctor_verification_status_screen.dart';
import 'screens/main_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _subscription;
  User? _user;
  Future<Widget>? _destination;
  bool _ready = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseAuth.instance.idTokenChanges().listen(
      _onUserChanged,
      onError: (Object error) {
        debugPrint('Authentication state could not be read: $error');
        if (mounted) {
          setState(() {
            _ready = true;
            _authError = 'Your sign-in state could not be verified.';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onUserChanged(User? user) {
    if (!mounted) return;
    setState(() {
      _user = user;
      _ready = true;
      _authError = null;
      _destination = user == null ? null : _resolveDestination(user);
    });
  }

  Future<Widget> _resolveDestination(User user) async {
    final token = await user.getIdTokenResult();
    final application = await FirebaseFirestore.instance
        .collection('doctor_applications')
        .doc(user.uid)
        .get();
    if (!application.exists) {
      if (token.claims?['doctor'] == true) {
        return _DeactivatedAccount(
          onSignOut: _signOut,
          title: 'Doctor access is not linked',
          message:
              'This account has doctor permissions but no approved SickleCare application. Contact an administrator.',
        );
      }
      return const MainShell();
    }

    final data = application.data();
    final status = data?['status'];
    if (status == 'deactivated') {
      return _DeactivatedAccount(onSignOut: _signOut);
    }

    if (status == 'approved' && token.claims?['doctor'] == true) {
      return DoctorDashboardScreen(
        doctorName: _stringOr(data?['fullName'], 'Doctor'),
        specialty: _stringOr(data?['specialty'], 'Healthcare professional'),
        facilityName: _stringOr(data?['facilityName'], ''),
        verificationStatus: DoctorVerificationStatus.approved,
        backendManaged: true,
      );
    }

    if (status != 'upload_required' &&
        status != 'pending' &&
        status != 'rejected' &&
        status != 'approved') {
      throw StateError('The professional application has an unknown status.');
    }

    final isUploadRequired = status == 'upload_required';
    final hasCredential = data?['credential'] is Map;
    return DoctorVerificationStatusScreen(
      status: status == 'rejected'
          ? DoctorVerificationStatus.rejected
          : status == 'approved'
              ? DoctorVerificationStatus.approved
              : DoctorVerificationStatus.pending,
      backendManaged: true,
      canSubmitCredentials: isUploadRequired || status == 'rejected',
      hasSubmittedCredentials: hasCredential,
      accessRefreshRequired:
          status == 'approved' && token.claims?['doctor'] != true,
      onRefreshAccess: () => _refreshAccess(user),
      reviewNote: data != null && data['reviewNotes'] is String
          ? data['reviewNotes'] as String
          : null,
      onContinueAsPatient: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      ),
      onSignOut: _signOut,
    );
  }

  String _stringOr(Object? value, String fallback) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  Future<void> _refreshAccess(User user) async {
    try {
      await user.getIdToken(true);
    } catch (error) {
      debugPrint('Unable to refresh doctor access: $error');
      if (mounted) {
        setState(() {
          _authError = 'Access could not be refreshed. Please try again.';
        });
      }
    }
  }

  void _signOut() {
    unawaited(FirebaseAuth.instance.signOut().catchError((Object error) {
      debugPrint('Sign-out failed: $error');
      if (mounted) {
        setState(() {
          _authError = 'Sign-out failed. Please try again.';
        });
      }
    }));
  }

  void _retry() {
    final user = _user;
    if (user == null) return;
    setState(() {
      _authError = null;
      _destination = _resolveDestination(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_user == null) return const LoginScreen();

    final error = _authError;
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _retry, child: const Text('Try again')),
                TextButton(
                  onPressed: () => unawaited(FirebaseAuth.instance.signOut()),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FutureBuilder<Widget>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your account status could not be loaded securely. Check your connection and try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                    TextButton(
                      onPressed: () =>
                          unawaited(FirebaseAuth.instance.signOut()),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return snapshot.data!;
      },
    );
  }
}

class _DeactivatedAccount extends StatelessWidget {
  const _DeactivatedAccount({
    required this.onSignOut,
    this.title = 'Professional account deactivated',
    this.message =
        'An administrator has disabled this account. Your application and records have been retained.',
  });

  final VoidCallback onSignOut;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 40),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
