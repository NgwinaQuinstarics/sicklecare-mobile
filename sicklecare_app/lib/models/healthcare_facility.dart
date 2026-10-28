enum FacilityType {
  hospital,
  clinic,
  healthCenter,
}

extension FacilityTypeLabel on FacilityType {
  String get label {
    switch (this) {
      case FacilityType.hospital:
        return 'Hospital';
      case FacilityType.clinic:
        return 'Clinic';
      case FacilityType.healthCenter:
        return 'Health centre';
    }
  }
}

/// A service offered by a healthcare facility.
class FacilityService {
  const FacilityService({
    required this.id,
    required this.name,
    required this.description,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final String description;
  final bool isAvailable;

  FacilityService copyWith({
    String? id,
    String? name,
    String? description,
    bool? isAvailable,
  }) {
    return FacilityService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// UI-facing facility data. Coordinates are mock-friendly and optional map UI
/// can use them without choosing a map provider.
class HealthcareFacility {
  const HealthcareFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.phoneNumber,
    required this.openingHours,
    required this.services,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    required this.hasEmergencyCare,
    required this.description,
    this.email,
    this.website,
    this.imageUrl,
  });

  final String id;
  final String name;
  final FacilityType type;
  final String address;
  final String city;
  final String phoneNumber;
  final String? email;
  final String? website;
  final List<String> openingHours;
  final List<FacilityService> services;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final bool hasEmergencyCare;
  final String description;
  final String? imageUrl;

  HealthcareFacility copyWith({
    String? id,
    String? name,
    FacilityType? type,
    String? address,
    String? city,
    String? phoneNumber,
    String? email,
    String? website,
    List<String>? openingHours,
    List<FacilityService>? services,
    double? distanceKm,
    double? latitude,
    double? longitude,
    bool? isOpen,
    bool? hasEmergencyCare,
    String? description,
    String? imageUrl,
  }) {
    return HealthcareFacility(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      city: city ?? this.city,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
      services: services ?? this.services,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOpen: isOpen ?? this.isOpen,
      hasEmergencyCare: hasEmergencyCare ?? this.hasEmergencyCare,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
