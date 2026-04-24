import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  DocumentReference<Map<String, dynamic>> get dailyRef =>
      _db.collection('users').doc(uid).collection('daily').doc(today);

  Future<void> saveDailyData({
    required double hydration,
    required List<String> meals,
    double? painLevel,
  }) async {
    await dailyRef.set({
      'hydration': hydration,
      'meals': meals,
      if (painLevel != null) 'painLevel': painLevel,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDaily() {
    return dailyRef.snapshots();
  }
}