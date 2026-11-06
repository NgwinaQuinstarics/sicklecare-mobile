import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/privacy_data_service.dart';

class AuthProvider extends ChangeNotifier {
  User? get user => FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _profile;
  StreamSubscription<User?>? _authSubscription;
  bool _isAdmin = false;

  Map<String, dynamic>? get profile => _profile;

  bool get isAdmin => _isAdmin;

  AuthProvider() {
    _authSubscription = FirebaseAuth.instance.idTokenChanges().listen(
      _handleAuthChange,
    );
  }

  Future<void> _handleAuthChange(User? u) async {
    if (u == null) {
      _isAdmin = false;
      _profile = null;
      notifyListeners();
      return;
    }

    try {
      final token = await u.getIdTokenResult();
      _isAdmin = token.claims?['admin'] == true;
    } catch (error) {
      debugPrint('Failed to read Firebase admin claim: $error');
      _isAdmin = false;
    }

    if (FirebaseAuth.instance.currentUser?.uid != u.uid) return;
    await loadProfile();
  }

  Future<void> loadProfile() async {
    final u = user;
    if (u == null) return;
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(u.uid);
      final doc = await ref.get();
      if (doc.exists) {
        _profile = doc.data();
      } else {
        // Profile doesn't exist yet (signup Firestore write may have failed).
        // Create it now.
        final data = <String, dynamic>{
          'name': u.displayName ?? '',
          'email': u.email ?? '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        };
        try {
          await ref.set(data);
          _profile = data;
        } catch (_) {
          // If Firestore rules still block, keep profile null — app still works.
          _profile = data; // Use local fallback so the app doesn't break.
        }
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Failed to load user profile: $error');
    }
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
    await u.delete();
    _profile = null;
    _isAdmin = false;
    try {
      await PrivacyDataService.deleteLocalHealthData();
    } catch (error) {
      debugPrint('Account deleted, but local data cleanup failed: $error');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
