import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_health.dart';

class HealthService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  String today() {
    final now = DateTime.now();
    return "${now.year}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  DocumentReference<Map<String, dynamic>> docRef() {
    return _db
        .collection("users")
        .doc(uid)
        .collection("days")
        .doc(today());
  }

  Stream<DailyHealth> streamDay() {
    return docRef().snapshots().map((snap) {
      return DailyHealth.fromMap(snap.data());
    });
  }

  Future<void> save(DailyHealth data) async {
    await docRef().set(
      data.toMap(),
      SetOptions(merge: true),
    );
  }
}