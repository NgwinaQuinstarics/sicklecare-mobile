import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final db = FirebaseFirestore.instance;

  static Future<void> submitContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    await db.collection('contact_messages').add({
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> contentDoc(String key) {
    return db.collection('content').doc(key).snapshots();
  }

  static Future<void> updateContent(String key, Map<String, dynamic> data) {
    return db.collection('content').doc(key).set(data, SetOptions(merge: true));
  }
}
