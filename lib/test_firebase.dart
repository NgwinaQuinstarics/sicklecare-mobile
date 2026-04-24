import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testSave() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print("NO USER LOGGED IN");
    return;
  }

  final now = DateTime.now();
  final docId =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('daily')
      .doc(docId)
      .set({
    "hydration": 2.5,
    "painLevel": 3,
    "meals": ["rice", "fish"],
    "createdAt": FieldValue.serverTimestamp(),
  });

  print("✅ TEST DATA SAVED SUCCESSFULLY");
}