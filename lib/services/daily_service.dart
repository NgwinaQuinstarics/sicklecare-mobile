import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyService {
  static final _firestore = FirebaseFirestore.instance;
  static final _user = FirebaseAuth.instance.currentUser;

  static String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  static Future<void> update(Map<String, dynamic> data) async {
    final uid = _user?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // ✅ CRITICAL
  }
}