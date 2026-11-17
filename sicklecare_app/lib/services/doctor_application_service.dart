import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class DoctorApplicationService {
  DoctorApplicationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<void> createApplication(Map<String, Object?> details) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before creating a doctor application.');
    }
    if (user.email?.toLowerCase() !=
        details['email']?.toString().toLowerCase()) {
      throw StateError(
          'The application email must match the signed-in account.');
    }

    await _functions
        .httpsCallable('createDoctorApplication')
        .call<Map<String, dynamic>>(details);
  }

  Future<void> uploadCredential({
    required Uint8List bytes,
    required String fileExtension,
    required String credentialType,
    required String issuer,
    required String referenceNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before submitting a credential.');
    }
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('Credential files must be between 1 byte and 10 MB.');
    }

    final applicationRef =
        _firestore.collection('doctor_applications').doc(user.uid);
    var applicationSnapshot = await applicationRef.get();
    var application = applicationSnapshot.data();
    if (application?['status'] == 'rejected') {
      await _functions
          .httpsCallable('prepareDoctorCredentialResubmission')
          .call();
      applicationSnapshot = await applicationRef.get();
      application = applicationSnapshot.data();
    }
    final uploadPath = application?['credentialUploadPath'];
    if (application?['status'] != 'upload_required' ||
        uploadPath is! String ||
        !uploadPath.startsWith('doctor_credentials/${user.uid}/')) {
      throw StateError(
          'The application is not waiting for a credential upload.');
    }

    final contentType = switch (fileExtension.toLowerCase()) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw ArgumentError('Choose a PDF, JPEG, PNG, or WebP file.'),
    };

    final upload = await _functions
        .httpsCallable('createDoctorCredentialUpload')
        .call<Map<String, dynamic>>({
      'contentType': contentType,
      'size': bytes.length,
    });
    final uploadUrl = upload.data['url'];
    final uploadHeaders = upload.data['headers'];
    if (uploadUrl is! String || uploadHeaders is! Map) {
      throw StateError('The secure credential upload could not be prepared.');
    }
    final headers = <String, String>{};
    for (final entry in uploadHeaders.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is String && value is String) {
        headers[key] = value;
      }
    }
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: headers,
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'The secure credential upload failed (${response.statusCode}).',
      );
    }
    await _functions.httpsCallable('finalizeDoctorApplication').call({
      'credentialType': credentialType,
      'issuer': issuer,
      'referenceNumber': referenceNumber,
    });
  }
}
