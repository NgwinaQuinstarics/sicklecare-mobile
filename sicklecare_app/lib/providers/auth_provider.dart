import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  User? get user => FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;
  bool _profileLoading = false;
  bool get profileLoading => _profileLoading;

  bool get isAdmin => (_profile?['role'] ?? 'user') == 'admin';
  bool get isDoctor => (_profile?['role'] ?? 'user') == 'doctor';

  AuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((u) async {
      if (u != null) {
        _profileLoading = true;
        _profile = null;
        notifyListeners();
        await loadProfile();
        _profileLoading = false;
      } else {
        _profile = null;
        _profileLoading = false;
      }
      notifyListeners();
    });
  }

  Future<void> loadProfile() async {
    final u = user;
    if (u == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      _profile = doc.data();
    } catch (_) {
      // Keep the authenticated experience available when profile retrieval is
      // temporarily unavailable. UI-only role features safely fall back to the
      // existing warrior shell until the profile can be loaded.
      _profile ??= const {};
    }
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final u = user;
    if (u == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(u.uid)
        .set(data, SetOptions(merge: true));
    await loadProfile();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  /// Permanently deletes the user's Firestore profile and auth account.
  /// May throw FirebaseAuthException('requires-recent-login').
  Future<void> deleteAccount() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).delete();
    } catch (_) {}
    await u.delete();
    _profile = null;
    notifyListeners();
  }
}
