import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// 🔥 Last 7 days real-time stream
  Stream<List<Map<String, dynamic>>> watchLast7Days(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .orderBy('updatedAt', descending: true)
        .limit(7)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// 🔥 Single day live stream (today dashboard)
  Stream<Map<String, dynamic>> watchToday(String uid, String today) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }
}