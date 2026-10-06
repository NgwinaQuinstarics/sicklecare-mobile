import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final db = FirebaseFirestore.instance;

  static Future<void> submitSupportMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final payload = {
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'status': 'new',
      'source': 'mobile_support',
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (user != null) {
      await db.collection('support_messages').add({
        ...payload,
        'uid': user.uid,
        'userEmail': user.email,
        'userName': user.displayName,
      });
      return;
    }

    await db.collection('contacts').add(payload);
  }

  static Future<void> submitContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) =>
      submitSupportMessage(
        name: name,
        email: email,
        subject: subject,
        message: message,
      );

  static Stream<DocumentSnapshot<Map<String, dynamic>>> contentDoc(String key) {
    return db.collection('content').doc(key).snapshots();
  }

  static Future<void> updateContent(String key, Map<String, dynamic> data) {
    return db.collection('content').doc(key).set(data, SetOptions(merge: true));
  }
}
