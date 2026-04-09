import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleService {
  static final firestore = FirebaseFirestore.instance;
  static final user = FirebaseAuth.instance.currentUser;

  // ✅ CHECK IF ADMIN
  static Future<bool> isAdmin() async {
    final uid = user?.uid;
    if (uid == null) return false;

    final doc =
        await firestore.collection('users').doc(uid).get();

    if (!doc.exists) return false;

    final data = doc.data();

    return data?['role'] == 'admin';
  }
}