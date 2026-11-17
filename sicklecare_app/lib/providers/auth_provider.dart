import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  User? get user => FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;
  bool _profileLoading = false;
  bool get profileLoading => _profileLoading;
  String? _profileError;
  String? get profileError => _profileError;
  bool _isAdmin = false;
  bool _isDoctor = false;

  bool get isAdmin => _isAdmin;
  bool get isDoctor => _isDoctor;

  AuthProvider() {
    FirebaseAuth.instance.idTokenChanges().listen((u) async {
      if (u != null) {
        _profileLoading = true;
        _profile = null;
        _profileError = null;
        _isAdmin = false;
        _isDoctor = false;
        notifyListeners();
        try {
          final token = await u.getIdTokenResult();
          _isAdmin = token.claims?['admin'] == true;
          _isDoctor = token.claims?['doctor'] == true;
          await loadProfile();
        } catch (error) {
          _profileError = 'Your profile could not be refreshed.';
          debugPrint('Unable to load the signed-in profile: $error');
        } finally {
          _profileLoading = false;
        }
      } else {
        _profile = null;
        _profileLoading = false;
        _profileError = null;
        _isAdmin = false;
        _isDoctor = false;
      }
      notifyListeners();
    });
  }

  Future<void> loadProfile() async {
    final u = user;
    if (u == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(u.uid);
    final doc = await ref.get();
    if (doc.exists) {
      _profile = doc.data();
      _profileError = null;
      return;
    }

    final data = <String, dynamic>{
      'name': u.displayName ?? '',
      'email': u.email ?? '',
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await ref.set(data);
    _profile = data;
    _profileError = null;
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
    final doctorApplication = await FirebaseFirestore.instance
        .collection('doctor_applications')
        .doc(u.uid)
        .get();
    if (doctorApplication.exists) {
      throw StateError(
        'Doctor applications and accounts can only be deactivated by an administrator.',
      );
    }
    await u.delete();
    _profile = null;
    _profileError = null;
    notifyListeners();
  }
}
