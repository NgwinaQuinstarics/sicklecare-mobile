import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/care_ui_repository.dart';
import '../models/app_role.dart';
import '../models/doctor_profile.dart';
import '../models/health_tracking.dart';
import '../models/healthcare_facility.dart';
import '../models/warrior_health_profile.dart';

/// In-memory state for the new care presentation flows.
///
/// This provider intentionally has no Firebase, Hive, HTTP, or location
/// dependencies. Screens can use it today with [MockCareUiRepository] and a
/// real repository can be supplied after the app's data contracts are agreed.
class CareUiProvider extends ChangeNotifier {
  CareUiProvider({CareUiRepository? repository, bool autoLoad = true})
      : _repository = repository ?? const MockCareUiRepository() {
    if (autoLoad) {
      unawaited(load());
    }
  }

  final CareUiRepository _repository;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  AppRole _activeRole = AppRole.warrior;

  DoctorProfile? _doctorProfile;
  bool _hasCustomDoctorProfile = false;
  WarriorHealthProfile? _warriorProfile;
  List<HealthcareFacility> _facilities = [];
  List<MedicationPlan> _medications = [];
  List<PainCrisis> _painCrises = [];
  List<HealthTimelineEvent> _timeline = [];
  int _hydrationTodayMl = 0;

  String _facilitySearchQuery = '';
  FacilityType? _facilityTypeFilter;
  bool _emergencyFacilitiesOnly = false;
  HealthcareFacility? _selectedFacility;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  AppRole get activeRole => _activeRole;

  DoctorProfile? get doctorProfile => _doctorProfile;
  WarriorHealthProfile? get warriorProfile => _warriorProfile;
  List<HealthcareFacility> get facilities => List.unmodifiable(_facilities);
  List<MedicationPlan> get medications => List.unmodifiable(_medications);
  List<PainCrisis> get painCrises => List.unmodifiable(_painCrises);
  List<HealthTimelineEvent> get timeline => List.unmodifiable(_timeline);
  HealthcareFacility? get selectedFacility => _selectedFacility;

  String get facilitySearchQuery => _facilitySearchQuery;
  FacilityType? get facilityTypeFilter => _facilityTypeFilter;
  bool get emergencyFacilitiesOnly => _emergencyFacilitiesOnly;
  int get hydrationTodayMl => _hydrationTodayMl;
  int get hydrationGoalMl => _warriorProfile?.hydrationGoalMl ?? 2500;

  double get hydrationProgress {
    if (hydrationGoalMl <= 0) {
      return 0;
    }
    return _hydrationTodayMl / hydrationGoalMl;
  }

  List<MedicationPlan> get activeMedications {
    return List.unmodifiable(
      _medications.where((medication) => medication.isActive),
    );
  }

  List<HealthcareFacility> get visibleFacilities {
    final query = _facilitySearchQuery.trim().toLowerCase();
    final matchingFacilities = _facilities.where((facility) {
      final matchesType =
          _facilityTypeFilter == null || facility.type == _facilityTypeFilter;
      final matchesEmergency =
          !_emergencyFacilitiesOnly || facility.hasEmergencyCare;
      final matchesQuery = query.isEmpty ||
          facility.name.toLowerCase().contains(query) ||
          facility.address.toLowerCase().contains(query) ||
          facility.city.toLowerCase().contains(query) ||
          facility.type.label.toLowerCase().contains(query) ||
          facility.services.any(
            (service) => service.name.toLowerCase().contains(query),
          );
      return matchesType && matchesEmergency && matchesQuery;
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return List.unmodifiable(matchingFacilities);
  }

  Future<void> load({bool force = false}) async {
    if (_isLoading || (_hasLoaded && !force)) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.load();
      // A clinician can complete the mock onboarding while this asynchronous
      // fixture is loading. Keep that session-only profile instead of
      // replacing it with the fixture when the load finishes.
      if (!_hasCustomDoctorProfile) {
        _doctorProfile = data.doctorProfile;
      }
      _warriorProfile = data.warriorProfile;
      _facilities = List.of(data.facilities);
      _medications = List.of(data.medications);
      _painCrises = List.of(data.painCrises)
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      _timeline = List.of(data.timeline)
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      _hydrationTodayMl = data.hydrationTodayMl;
      _selectedFacility = _facilityWithId(_selectedFacility?.id);
      _hasLoaded = true;
    } catch (_) {
      _errorMessage = 'We could not load the preview data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => load(force: true);

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  void setActiveRole(AppRole role) {
    if (_activeRole == role) {
      return;
    }
    _activeRole = role;
    notifyListeners();
  }

  void updateDoctorProfile(DoctorProfile profile) {
    _doctorProfile = profile;
    _hasCustomDoctorProfile = true;
    notifyListeners();
  }

  void updateWarriorProfile(WarriorHealthProfile profile) {
    _warriorProfile = profile;
    notifyListeners();
  }

  void updateEmergencyContact(EmergencyContact contact) {
    final profile = _warriorProfile;
    if (profile == null) {
      return;
    }
    _warriorProfile = profile.copyWith(emergencyContact: contact);
    notifyListeners();
  }

  void setDoctorAvailability(bool isAvailable) {
    final profile = _doctorProfile;
    if (profile == null || profile.isAvailable == isAvailable) {
      return;
    }
    _doctorProfile = profile.copyWith(isAvailable: isAvailable);
    _hasCustomDoctorProfile = true;
    notifyListeners();
  }

  bool submitDoctorCredential(DoctorCredential credential) {
    final profile = _doctorProfile;
    if (profile == null) {
      return _showValidationError('Doctor profile is not ready yet.');
    }
    if (credential.title.trim().isEmpty || credential.issuedBy.trim().isEmpty) {
      return _showValidationError(
        'Add the credential title and issuing organisation before submitting.',
      );
    }

    final credentials = [
      credential,
      ...profile.credentials.where((item) => item.id != credential.id),
    ];
    _doctorProfile = profile.copyWith(
      credentials: credentials,
      verificationStatus:
          profile.verificationStatus == DoctorVerificationStatus.rejected
              ? DoctorVerificationStatus.pending
              : profile.verificationStatus,
    );
    _hasCustomDoctorProfile = true;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void updateDoctorVerificationStatus(DoctorVerificationStatus status) {
    final profile = _doctorProfile;
    if (profile == null || profile.verificationStatus == status) {
      return;
    }
    _doctorProfile = profile.copyWith(verificationStatus: status);
    _hasCustomDoctorProfile = true;
    notifyListeners();
  }

  void updateCredentialStatus(
    String credentialId,
    DoctorVerificationStatus status, {
    String? rejectionReason,
  }) {
    final profile = _doctorProfile;
    if (profile == null) {
      return;
    }
    final credentials = profile.credentials
        .map(
          (credential) => credential.id == credentialId
              ? credential.copyWith(
                  status: status,
                  rejectionReason: rejectionReason,
                  clearRejectionReason:
                      status != DoctorVerificationStatus.rejected &&
                          rejectionReason == null,
                )
              : credential,
        )
        .toList();
    _doctorProfile = profile.copyWith(credentials: credentials);
    _hasCustomDoctorProfile = true;
    notifyListeners();
  }

  void setFacilitySearchQuery(String query) {
    if (_facilitySearchQuery == query) {
      return;
    }
    _facilitySearchQuery = query;
    notifyListeners();
  }

  void setFacilityTypeFilter(FacilityType? type) {
    if (_facilityTypeFilter == type) {
      return;
    }
    _facilityTypeFilter = type;
    notifyListeners();
  }

  void setEmergencyFacilitiesOnly(bool enabled) {
    if (_emergencyFacilitiesOnly == enabled) {
      return;
    }
    _emergencyFacilitiesOnly = enabled;
    notifyListeners();
  }

  void clearFacilityFilters() {
    if (_facilitySearchQuery.isEmpty &&
        _facilityTypeFilter == null &&
        !_emergencyFacilitiesOnly) {
      return;
    }
    _facilitySearchQuery = '';
    _facilityTypeFilter = null;
    _emergencyFacilitiesOnly = false;
    notifyListeners();
  }

  void selectFacility(HealthcareFacility? facility) {
    if (_selectedFacility?.id == facility?.id) {
      return;
    }
    _selectedFacility = facility;
    notifyListeners();
  }

  void selectFacilityById(String? facilityId) {
    selectFacility(_facilityWithId(facilityId));
  }

  bool addMedication(MedicationPlan medication) {
    if (medication.name.trim().isEmpty || medication.dosage.trim().isEmpty) {
      return _showValidationError('Add a medication name and dosage first.');
    }
    _medications = [
      medication,
      ..._medications.where((item) => item.id != medication.id),
    ];
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void toggleMedicationReminder(String medicationId) {
    _medications = _medications
        .map(
          (medication) => medication.id == medicationId
              ? medication.copyWith(
                  reminderEnabled: !medication.reminderEnabled,
                )
              : medication,
        )
        .toList();
    notifyListeners();
  }

  void setMedicationActive(String medicationId, bool isActive) {
    _medications = _medications
        .map(
          (medication) => medication.id == medicationId
              ? medication.copyWith(isActive: isActive)
              : medication,
        )
        .toList();
    notifyListeners();
  }

  void removeMedication(String medicationId) {
    final countBefore = _medications.length;
    _medications.removeWhere((medication) => medication.id == medicationId);
    if (_medications.length != countBefore) {
      notifyListeners();
    }
  }

  void markMedicationTaken(String medicationId, {DateTime? occurredAt}) {
    final medication = _medications.cast<MedicationPlan?>().firstWhere(
          (item) => item?.id == medicationId,
          orElse: () => null,
        );
    if (medication == null) {
      return;
    }
    _addTimelineEvent(
      HealthTimelineEvent(
        id: 'medication-$medicationId-${(occurredAt ?? DateTime.now()).millisecondsSinceEpoch}',
        occurredAt: occurredAt ?? DateTime.now(),
        type: HealthTimelineEventType.medication,
        title: '${medication.name} marked as taken',
        description: '${medication.dosage} · ${medication.scheduleLabel}',
      ),
    );
    notifyListeners();
  }

  bool addPainCrisis(PainCrisis crisis) {
    if (crisis.intensity < 0 || crisis.intensity > 10) {
      return _showValidationError('Pain intensity must be between 0 and 10.');
    }
    if (crisis.symptoms.isEmpty && crisis.affectedAreas.isEmpty) {
      return _showValidationError(
        'Add at least one symptom or affected area to the crisis entry.',
      );
    }

    _painCrises = [
      crisis,
      ..._painCrises.where((item) => item.id != crisis.id),
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _addTimelineEvent(
      HealthTimelineEvent(
        id: 'crisis-${crisis.id}',
        occurredAt: crisis.startedAt,
        type: HealthTimelineEventType.crisis,
        title: crisis.isOngoing ? 'Pain crisis logged' : 'Pain crisis recorded',
        description: crisis.notes,
        severity: crisis.intensity,
      ),
    );
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void endPainCrisis(String crisisId, DateTime endedAt) {
    _painCrises = _painCrises
        .map(
          (crisis) => crisis.id == crisisId
              ? crisis.copyWith(endedAt: endedAt)
              : crisis,
        )
        .toList();
    notifyListeners();
  }

  void addTimelineEvent(HealthTimelineEvent event) {
    _addTimelineEvent(event);
    notifyListeners();
  }

  bool logHydration(int millilitres, {DateTime? occurredAt}) {
    if (millilitres <= 0) {
      return _showValidationError('Enter an amount greater than zero.');
    }
    final time = occurredAt ?? DateTime.now();
    _hydrationTodayMl += millilitres;
    _addTimelineEvent(
      HealthTimelineEvent(
        id: 'hydration-${time.millisecondsSinceEpoch}',
        occurredAt: time,
        type: HealthTimelineEventType.hydration,
        title: 'Hydration logged',
        description: '$millilitres ml added to today\'s goal.',
      ),
    );
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void _addTimelineEvent(HealthTimelineEvent event) {
    _timeline = [event, ..._timeline.where((item) => item.id != event.id)]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  HealthcareFacility? _facilityWithId(String? facilityId) {
    if (facilityId == null) {
      return null;
    }
    for (final facility in _facilities) {
      if (facility.id == facilityId) {
        return facility;
      }
    }
    return null;
  }

  bool _showValidationError(String message) {
    _errorMessage = message;
    notifyListeners();
    return false;
  }
}
