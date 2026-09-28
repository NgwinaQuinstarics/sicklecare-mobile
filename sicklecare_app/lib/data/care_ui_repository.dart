import '../models/doctor_profile.dart';
import '../models/health_tracking.dart';
import '../models/healthcare_facility.dart';
import '../models/warrior_health_profile.dart';

/// A complete UI fixture set. It lets presentation work progress without
/// defining a backend contract prematurely.
class CareUiData {
  const CareUiData({
    required this.doctorProfile,
    required this.warriorProfile,
    required this.facilities,
    required this.medications,
    required this.painCrises,
    required this.timeline,
    required this.hydrationTodayMl,
  });

  final DoctorProfile doctorProfile;
  final WarriorHealthProfile warriorProfile;
  final List<HealthcareFacility> facilities;
  final List<MedicationPlan> medications;
  final List<PainCrisis> painCrises;
  final List<HealthTimelineEvent> timeline;
  final int hydrationTodayMl;
}

/// Boundary for the presentation provider. A real adapter can replace this
/// later after data requirements have been jointly agreed.
abstract class CareUiRepository {
  Future<CareUiData> load();
}

/// Deliberately fictional, in-memory data for building and testing UI flows.
/// It contains no Firebase calls, patient records, or production facility data.
class MockCareUiRepository implements CareUiRepository {
  const MockCareUiRepository();

  @override
  Future<CareUiData> load() async {
    final now = DateTime.now();

    return CareUiData(
      doctorProfile: DoctorProfile(
        id: 'mock-doctor-1',
        fullName: 'Dr. Eliane M.',
        specialty: 'Clinical haematology',
        qualifications: const ['MD', 'Clinical Haematology Fellowship'],
        facilityName: 'SickleCare Community Hospital',
        city: 'Douala',
        email: 'eliane.m@example.test',
        phoneNumber: '+237 6 00 00 00 10',
        availabilitySummary: 'Mon–Fri · 08:00–16:00',
        isAvailable: true,
        verificationStatus: DoctorVerificationStatus.approved,
        credentials: [
          DoctorCredential(
            id: 'mock-credential-medical-license',
            title: 'Medical practice licence',
            issuedBy: 'Demo medical council',
            submittedAt: now.subtract(const Duration(days: 28)),
            status: DoctorVerificationStatus.approved,
          ),
          DoctorCredential(
            id: 'mock-credential-specialty',
            title: 'Haematology certificate',
            issuedBy: 'Demo training institution',
            submittedAt: now.subtract(const Duration(days: 4)),
          ),
        ],
        bio:
            'A fictional clinician profile used to preview care-team interfaces.',
      ),
      warriorProfile: const WarriorHealthProfile(
        id: 'mock-warrior-1',
        displayName: 'Amina',
        bloodGroup: 'O+',
        genotype: 'HbSS',
        primaryFacilityName: 'SickleCare Community Hospital',
        primaryDoctorName: 'Dr. Eliane M.',
        emergencyContact: EmergencyContact(
          id: 'mock-emergency-contact-1',
          name: 'Grace A.',
          relationship: 'Parent',
          phoneNumber: '+237 6 00 00 00 20',
        ),
        allergies: ['No known allergies recorded'],
        knownTriggers: ['Dehydration', 'Cold weather', 'Stress'],
        careNotes:
            'Mock health information for UI preview only. Confirm care steps with a clinician.',
        hydrationGoalMl: 2500,
      ),
      facilities: const [
        HealthcareFacility(
          id: 'mock-facility-community-hospital',
          name: 'SickleCare Community Hospital',
          type: FacilityType.hospital,
          address: '12 Wellness Avenue, Akwa',
          city: 'Douala',
          phoneNumber: '+237 6 00 00 01 01',
          email: 'care@example.test',
          openingHours: ['Open 24 hours', 'Emergency services every day'],
          services: [
            FacilityService(
              id: 'mock-service-emergency',
              name: 'Emergency care',
              description: 'Urgent assessment and stabilisation.',
            ),
            FacilityService(
              id: 'mock-service-haematology',
              name: 'Haematology clinic',
              description: 'Specialist sickle-cell follow-up.',
            ),
            FacilityService(
              id: 'mock-service-laboratory',
              name: 'Laboratory',
              description: 'Routine blood-work support.',
            ),
          ],
          distanceKm: 1.8,
          latitude: 4.0511,
          longitude: 9.7679,
          isOpen: true,
          hasEmergencyCare: true,
          description:
              'A fictional full-service hospital used for facility discovery UI.',
        ),
        HealthcareFacility(
          id: 'mock-facility-bonaberi-clinic',
          name: 'Bonabéri Family Clinic',
          type: FacilityType.clinic,
          address: '4 Riverside Road, Bonabéri',
          city: 'Douala',
          phoneNumber: '+237 6 00 00 01 02',
          openingHours: ['Mon–Sat · 07:30–19:00', 'Sun · 09:00–14:00'],
          services: [
            FacilityService(
              id: 'mock-service-consultation',
              name: 'General consultation',
              description: 'Primary care consultations.',
            ),
            FacilityService(
              id: 'mock-service-pharmacy',
              name: 'Pharmacy support',
              description: 'Medication collection guidance.',
            ),
          ],
          distanceKm: 3.6,
          latitude: 4.0786,
          longitude: 9.6842,
          isOpen: true,
          hasEmergencyCare: false,
          description: 'A fictional neighbourhood clinic for UI previews.',
        ),
        HealthcareFacility(
          id: 'mock-facility-akwa-health-centre',
          name: 'Akwa Health Centre',
          type: FacilityType.healthCenter,
          address: '25 Unity Street, Akwa',
          city: 'Douala',
          phoneNumber: '+237 6 00 00 01 03',
          website: 'https://example.test/akwa-health-centre',
          openingHours: ['Mon–Fri · 08:00–17:00', 'Sat · 08:00–12:00'],
          services: [
            FacilityService(
              id: 'mock-service-education',
              name: 'Health education',
              description: 'Self-management education and referrals.',
            ),
            FacilityService(
              id: 'mock-service-vaccination',
              name: 'Preventive care',
              description: 'Routine preventive care consultations.',
              isAvailable: false,
            ),
          ],
          distanceKm: 5.2,
          latitude: 4.0435,
          longitude: 9.7043,
          isOpen: false,
          hasEmergencyCare: false,
          description: 'A fictional primary care centre for UI previews.',
        ),
      ],
      medications: [
        MedicationPlan(
          id: 'mock-medication-hydroxyurea',
          name: 'Hydroxyurea',
          dosage: '500 mg',
          scheduleLabel: 'Every morning',
          nextDoseAt: DateTime(now.year, now.month, now.day, 8),
          instructions:
              'Mock reminder only — follow the care plan from a clinician.',
        ),
        MedicationPlan(
          id: 'mock-medication-folic-acid',
          name: 'Folic acid',
          dosage: '5 mg',
          scheduleLabel: 'Every evening',
          nextDoseAt: DateTime(now.year, now.month, now.day, 20),
        ),
      ],
      painCrises: [
        PainCrisis(
          id: 'mock-crisis-1',
          startedAt: now.subtract(const Duration(days: 8, hours: 4)),
          endedAt: now.subtract(const Duration(days: 8)),
          intensity: 6,
          symptoms: const ['Fatigue', 'Joint pain'],
          affectedAreas: const ['Lower back', 'Knees'],
          notes: 'Example entry for the crisis-history interface.',
          actionTaken: 'Rest and hydration',
        ),
      ],
      timeline: [
        HealthTimelineEvent(
          id: 'mock-timeline-hydration',
          occurredAt: now.subtract(const Duration(hours: 2)),
          type: HealthTimelineEventType.hydration,
          title: 'Hydration logged',
          description: '400 ml added to today\'s goal.',
        ),
        HealthTimelineEvent(
          id: 'mock-timeline-medication',
          occurredAt: now.subtract(const Duration(days: 1, hours: 10)),
          type: HealthTimelineEventType.medication,
          title: 'Medication reminder completed',
          description: 'Example timeline item.',
        ),
        HealthTimelineEvent(
          id: 'mock-timeline-crisis',
          occurredAt: now.subtract(const Duration(days: 8)),
          type: HealthTimelineEventType.crisis,
          title: 'Pain crisis resolved',
          description: 'Example entry for the health-history interface.',
          severity: 6,
        ),
      ],
      hydrationTodayMl: 1400,
    );
  }
}
