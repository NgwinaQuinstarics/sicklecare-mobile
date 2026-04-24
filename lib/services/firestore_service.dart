import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  DocumentReference get todayRef {
    return _db
        .collection('users')
        .doc(_user!.uid)
        .collection('daily')
        .doc(today);
  }

  /// 🔥 SAVE (MERGE SAFE)
  Future<void> save(Map<String, dynamic> data) async {
    await todayRef.set(data, SetOptions(merge: true));
  }

  /// 🔥 STREAM (REAL TIME)
  Stream<DocumentSnapshot> stream() {
    return todayRef.snapshots();
  }

  /// 🔥 GET ONCE
  Future<DocumentSnapshot> get() async {
    return await todayRef.get();
  }
}