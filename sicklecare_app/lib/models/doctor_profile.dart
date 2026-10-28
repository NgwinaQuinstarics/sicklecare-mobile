/// UI-only verification states. These values intentionally do not prescribe
/// Firestore fields or a credential-review workflow.
enum DoctorVerificationStatus {
  pending,
  approved,
  rejected,
}

extension DoctorVerificationStatusLabel on DoctorVerificationStatus {
  String get label {
    switch (this) {
      case DoctorVerificationStatus.pending:
        return 'Pending review';
      case DoctorVerificationStatus.approved:
        return 'Verified';
      case DoctorVerificationStatus.rejected:
        return 'Action needed';
    }
  }
}

/// A document or professional qualification submitted for UI review flows.
class DoctorCredential {
  const DoctorCredential({
    required this.id,
    required this.title,
    required this.issuedBy,
    required this.submittedAt,
    this.status = DoctorVerificationStatus.pending,
    this.rejectionReason,
  });

  final String id;
  final String title;
  final String issuedBy;
  final DateTime submittedAt;
  final DoctorVerificationStatus status;
  final String? rejectionReason;

  DoctorCredential copyWith({
    String? id,
    String? title,
    String? issuedBy,
    DateTime? submittedAt,
    DoctorVerificationStatus? status,
    String? rejectionReason,
    bool clearRejectionReason = false,
  }) {
    return DoctorCredential(
      id: id ?? this.id,
      title: title ?? this.title,
      issuedBy: issuedBy ?? this.issuedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      rejectionReason:
          clearRejectionReason ? null : rejectionReason ?? this.rejectionReason,
    );
  }
}

/// Professional information needed to render doctor-facing presentation
/// screens. It is deliberately independent of authentication and backend data.
class DoctorProfile {
  const DoctorProfile({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.qualifications,
    required this.facilityName,
    required this.email,
    required this.phoneNumber,
    required this.availabilitySummary,
    required this.isAvailable,
    required this.verificationStatus,
    required this.credentials,
    this.bio = '',
    this.city = '',
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String specialty;
  final List<String> qualifications;
  final String facilityName;
  final String city;
  final String email;
  final String phoneNumber;
  final String availabilitySummary;
  final bool isAvailable;
  final DoctorVerificationStatus verificationStatus;
  final List<DoctorCredential> credentials;
  final String bio;
  final String? avatarUrl;

  bool get isVerified =>
      verificationStatus == DoctorVerificationStatus.approved;

  bool get hasSubmittedCredentials => credentials.isNotEmpty;

  DoctorProfile copyWith({
    String? id,
    String? fullName,
    String? specialty,
    List<String>? qualifications,
    String? facilityName,
    String? city,
    String? email,
    String? phoneNumber,
    String? availabilitySummary,
    bool? isAvailable,
    DoctorVerificationStatus? verificationStatus,
    List<DoctorCredential>? credentials,
    String? bio,
    String? avatarUrl,
  }) {
    return DoctorProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      specialty: specialty ?? this.specialty,
      qualifications: qualifications ?? this.qualifications,
      facilityName: facilityName ?? this.facilityName,
      city: city ?? this.city,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      availabilitySummary: availabilitySummary ?? this.availabilitySummary,
      isAvailable: isAvailable ?? this.isAvailable,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      credentials: credentials ?? this.credentials,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
