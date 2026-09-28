/// A trusted person to contact from the emergency information screen.
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.alternatePhoneNumber,
  });

  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final String? alternatePhoneNumber;

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phoneNumber,
    String? alternatePhoneNumber,
    bool clearAlternatePhoneNumber = false,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      alternatePhoneNumber: clearAlternatePhoneNumber
          ? null
          : alternatePhoneNumber ?? this.alternatePhoneNumber,
    );
  }
}

/// Health details used only by the temporary presentation layer.
class WarriorHealthProfile {
  const WarriorHealthProfile({
    required this.id,
    required this.displayName,
    required this.bloodGroup,
    required this.genotype,
    required this.primaryFacilityName,
    required this.emergencyContact,
    required this.allergies,
    required this.knownTriggers,
    required this.careNotes,
    this.primaryDoctorName,
    this.hydrationGoalMl = 2500,
  });

  final String id;
  final String displayName;
  final String bloodGroup;
  final String genotype;
  final String primaryFacilityName;
  final String? primaryDoctorName;
  final EmergencyContact emergencyContact;
  final List<String> allergies;
  final List<String> knownTriggers;
  final String careNotes;
  final int hydrationGoalMl;

  WarriorHealthProfile copyWith({
    String? id,
    String? displayName,
    String? bloodGroup,
    String? genotype,
    String? primaryFacilityName,
    String? primaryDoctorName,
    bool clearPrimaryDoctorName = false,
    EmergencyContact? emergencyContact,
    List<String>? allergies,
    List<String>? knownTriggers,
    String? careNotes,
    int? hydrationGoalMl,
  }) {
    return WarriorHealthProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      genotype: genotype ?? this.genotype,
      primaryFacilityName: primaryFacilityName ?? this.primaryFacilityName,
      primaryDoctorName: clearPrimaryDoctorName
          ? null
          : primaryDoctorName ?? this.primaryDoctorName,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      allergies: allergies ?? this.allergies,
      knownTriggers: knownTriggers ?? this.knownTriggers,
      careNotes: careNotes ?? this.careNotes,
      hydrationGoalMl: hydrationGoalMl ?? this.hydrationGoalMl,
    );
  }
}
