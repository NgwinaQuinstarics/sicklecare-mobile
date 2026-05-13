import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  static String get _today =>
      DateTime.now().toIso8601String().split('T')[0];

  static DocumentReference<Map<String, dynamic>> _doc() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('daily')
        .doc(_today);
  }

  static Future<void> updateData(Map<String, dynamic> data) async {
    await _doc().set(
      {
        ...data,
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> stream() {
    return _doc().snapshots();
  }
}