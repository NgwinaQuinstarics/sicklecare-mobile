import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sicklecare_app/data/care_ui_repository.dart';
import 'package:sicklecare_app/login.dart';
import 'package:sicklecare_app/models/doctor_profile.dart';
import 'package:sicklecare_app/models/health_tracking.dart';
import 'package:sicklecare_app/models/healthcare_facility.dart';
import 'package:sicklecare_app/providers/care_ui_provider.dart';
import 'package:sicklecare_app/screens/auth/role_selection_screen.dart';
import 'package:sicklecare_app/screens/care/appointment_request_screen.dart';
import 'package:sicklecare_app/screens/care/care_hub_screen.dart';
import 'package:sicklecare_app/screens/care/crisis_tracking_screen.dart';
import 'package:sicklecare_app/screens/care/education_library_screen.dart';
import 'package:sicklecare_app/screens/care/emergency_information_screen.dart';
import 'package:sicklecare_app/screens/care/health_timeline_screen.dart';
import 'package:sicklecare_app/screens/care/medication_hydration_screen.dart';
import 'package:sicklecare_app/screens/care/warrior_health_profile_screen.dart';
import 'package:sicklecare_app/screens/doctor/credential_submission_screen.dart';
import 'package:sicklecare_app/screens/doctor/doctor_dashboard_screen.dart';
import 'package:sicklecare_app/screens/doctor/doctor_profile_screen.dart';
import 'package:sicklecare_app/screens/doctor/doctor_registration_screen.dart';
import 'package:sicklecare_app/screens/doctor/doctor_schedule_screen.dart';
import 'package:sicklecare_app/screens/doctor/doctor_verification_status_screen.dart';
import 'package:sicklecare_app/screens/facilities/facilities_screen.dart';
import 'package:sicklecare_app/screens/facilities/facility_detail_screen.dart';
import 'package:sicklecare_app/theme/app_theme.dart';

Widget previewApp(
  Widget child, {
  CareUiProvider? provider,
  TextScaler? textScaler,
}) {
  return ChangeNotifierProvider<CareUiProvider>.value(
    value: provider ?? CareUiProvider(),
    child: MaterialApp(
      theme: AppTheme.light(),
      builder: (context, routedChild) {
        final resolvedChild = routedChild ?? const SizedBox.shrink();
        if (textScaler == null) return resolvedChild;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: resolvedChild,
        );
      },
      home: child,
    ),
  );
}

class _ControlledCareUiRepository implements CareUiRepository {
  final requests = <Completer<CareUiData>>[];

  @override
  Future<CareUiData> load() {
    final request = Completer<CareUiData>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  testWidgets('role selection separates warrior and clinician paths',
      (tester) async {
    await tester.pumpWidget(previewApp(const RoleSelectionScreen()));

    expect(
      find.text('I am a sickle-cell warrior', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('I am a healthcare professional', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Clinician onboarding is a UI preview', skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets('back from role selection returns to sign in', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your SickleCare path'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('role selection provides an explicit return to sign in',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
    );

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your SickleCare path'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sign in'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('doctor registration presents its professional form',
      (tester) async {
    await tester.pumpWidget(previewApp(const DoctorRegistrationScreen()));

    expect(find.text('Create clinician profile'), findsOneWidget);
    expect(
      find.text('Professional details', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('clinician onboarding clears the setup routes on completion',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      previewApp(
        DoctorRegistrationScreen(onSubmitted: (_) async {}),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Dr. Jordan M.');
    await tester.enterText(fields.at(1), 'jordan@example.test');
    await tester.enterText(fields.at(2), '+237 600 000 000');
    await tester.enterText(fields.at(3), 'MD');
    await tester.enterText(fields.at(4), 'CM-12345');
    await tester.enterText(fields.at(5), 'Preview Hospital');
    await tester.enterText(fields.at(6), '5');

    await tester.tap(find.byType(Checkbox).first);
    await tester.tap(find.text('Create professional profile'));
    await tester.pumpAndSettle();

    expect(find.byType(DoctorDashboardScreen), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(DoctorDashboardScreen))).canPop(),
      isFalse,
    );
  });

  testWidgets('doctor workspace renders its initial dashboard state',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false)
      ..updateDoctorProfile(
        const DoctorProfile(
          id: 'test-doctor',
          fullName: 'Dr. Jordan M.',
          specialty: 'Haematology',
          qualifications: ['MD'],
          facilityName: 'Preview Hospital',
          email: 'doctor@example.test',
          phoneNumber: '+237 600 000 000',
          availabilitySummary: 'Mon–Fri',
          isAvailable: true,
          verificationStatus: DoctorVerificationStatus.pending,
          credentials: [],
        ),
      );

    await tester.pumpWidget(
      previewApp(const DoctorDashboardScreen(), provider: provider),
    );

    expect(find.text('Care workspace'), findsOneWidget);
    expect(find.textContaining('Dr. Jordan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('2 remaining'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2 remaining'), findsOneWidget);
    expect(find.text('Due this week'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'doctor workspace stays usable with larger text on a narrow phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false)
      ..updateDoctorProfile(
        const DoctorProfile(
          id: 'large-text-doctor',
          fullName: 'Dr. Jordan M.',
          specialty: 'Haematology',
          qualifications: ['MD'],
          facilityName: 'Preview Hospital',
          email: 'doctor@example.test',
          phoneNumber: '+237 600 000 000',
          availabilitySummary: 'Mon–Fri',
          isAvailable: true,
          verificationStatus: DoctorVerificationStatus.pending,
          credentials: [],
        ),
      );

    await tester.pumpWidget(
      previewApp(
        const DoctorDashboardScreen(),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Today’s sessions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Today’s sessions'));
    await tester.pumpAndSettle();
    expect(find.text('Today’s sessions'), findsOneWidget);
    expect(find.text('Care-plan reviews'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('doctor workspace opens the care directory', (tester) async {
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();

    await tester.pumpWidget(
      previewApp(const DoctorDashboardScreen(), provider: provider),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Browse care facilities'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Browse care facilities'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Find care'), findsOneWidget);
    expect(find.text('SickleCare Preview Hospital'), findsOneWidget);
  });

  testWidgets('doctor dashboard opens an interactive schedule', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);

    await tester.pumpWidget(
      previewApp(
        const DoctorDashboardScreen(),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Today’s sessions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Today’s sessions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today’s sessions'));
    await tester.pumpAndSettle();

    expect(find.byType(DoctorScheduleScreen), findsOneWidget);
    await tester.tap(find.text('Thu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('No sessions on this day'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('doctor-schedule-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('No sessions on this day'), findsOneWidget);

    await tester.fling(
      find.byKey(const Key('doctor-schedule-list')),
      const Offset(0, 1000),
      1000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mon'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('New consultation'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('New consultation'), findsOneWidget);
    await tester.tap(find.text('New consultation'));
    await tester.pumpAndSettle();
    expect(find.text('Mark complete in preview'), findsOneWidget);
    await tester.tap(find.text('Mark complete in preview'));
    await tester.pumpAndSettle();

    expect(find.text('Complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('care directory updates from loading and retry states',
      (tester) async {
    final repository = _ControlledCareUiRepository();
    final provider = CareUiProvider(repository: repository, autoLoad: false);
    final firstLoad = provider.load();
    await tester.pump();

    await tester.pumpWidget(
      previewApp(const DoctorDashboardScreen(), provider: provider),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Browse care facilities'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Browse care facilities'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Finding care near you…'), findsOneWidget);
    expect(repository.requests, hasLength(1));

    repository.requests.first.completeError(StateError('Preview failure'));
    await firstLoad;
    await tester.pumpAndSettle();
    expect(find.text('Facilities are unavailable'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.text('Finding care near you…'), findsOneWidget);
    expect(repository.requests, hasLength(2));

    repository.requests[1].complete(await const MockCareUiRepository().load());
    await tester.pumpAndSettle();
    expect(find.text('SickleCare Preview Hospital'), findsOneWidget);
  });

  testWidgets('care hub exposes the new warrior health tools', (tester) async {
    await tester.pumpWidget(previewApp(const CareHubScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Health profile', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Pain & symptom tracker', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Medicines & hydration', skipOffstage: false),
      findsOneWidget,
    );
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Appointments'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Appointments'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Learning & support'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Learning & support'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Emergency information'),
      300,
      scrollable: scrollable,
    );
    expect(
      find.text('Emergency information'),
      findsOneWidget,
    );
  });

  testWidgets('learning library keeps topics local and ready for review',
      (tester) async {
    await tester.pumpWidget(previewApp(const EducationLibraryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Learning-library preview'), findsOneWidget);
    expect(find.text('Prepare for a visit'), findsOneWidget);

    await tester.tap(find.byKey(const Key('learning-category-visit')));
    await tester.pumpAndSettle();
    expect(find.text('Everyday check-ins', skipOffstage: false), findsNothing);

    final visitTopic = find.byKey(const Key('learning-topic-visit-prep'));
    await tester.scrollUntilVisible(
      visitTopic,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(visitTopic);
    await tester.pumpAndSettle();
    await tester.tap(visitTopic);
    await tester.pumpAndSettle();
    expect(find.text('What you can prepare'), findsOneWidget);
    expect(find.text('Editorial review required'), findsOneWidget);

    final markRead = find.byKey(const Key('learning-topic-read-visit-prep'));
    await tester.ensureVisible(markRead);
    await tester.pumpAndSettle();
    await tester.tap(markRead);
    await tester.pumpAndSettle();
    expect(
      find.text('Marked as reviewed for this preview session.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Sources & review'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sources & review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('appointment requests validate and stay in the local preview',
      (tester) async {
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();
    await tester.pumpWidget(
      previewApp(const AppointmentRequestScreen(), provider: provider),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('No appointment requests yet'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No appointment requests yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('appointment-request-cta')));
    await tester.pumpAndSettle();
    final submit = find.byKey(const Key('appointment-request-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Choose a facility.'), findsOneWidget);
    expect(find.text('Choose a care team.'), findsOneWidget);
    expect(find.text('Choose a preferred timing.'), findsOneWidget);

    final facility = find.byKey(const Key('appointment-facility-select'));
    await tester.ensureVisible(facility);
    await tester.tap(facility);
    await tester.pumpAndSettle();
    await tester.tap(find.text('SickleCare Preview Hospital').last);
    await tester.pumpAndSettle();

    final team = find.byKey(const Key('appointment-team-select'));
    await tester.ensureVisible(team);
    await tester.tap(team);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Care team · next available (preview)').last,
    );
    await tester.pumpAndSettle();

    final timing = find.byKey(const Key('appointment-timing-next-available'));
    await tester.ensureVisible(timing);
    await tester.tap(timing);
    await tester.pumpAndSettle();
    final note = find.byKey(const Key('appointment-note-field'));
    await tester.ensureVisible(note);
    await tester.enterText(note, 'Discuss next care visit');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Pending · preview'), findsOneWidget);
    expect(find.text('Discuss next care visit'), findsOneWidget);
    expect(
      find.text('Appointment request saved in this preview session.'),
      findsOneWidget,
    );
    expect(
      provider.timeline.any(
        (event) => event.type == HealthTimelineEventType.appointment,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'appointment request stays usable with larger text on a narrow phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();
    await tester.pumpWidget(
      previewApp(
        const AppointmentRequestScreen(),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();

    final request = find.byKey(const Key('appointment-request-cta'));
    await tester.scrollUntilVisible(
      request,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(request);
    await tester.pumpAndSettle();
    expect(request, findsOneWidget);
    await tester.tap(request);
    await tester.pumpAndSettle();
    expect(find.text('Preferred facility'), findsOneWidget);
    final submit = find.byKey(const Key('appointment-request-submit'));
    await tester.ensureVisible(submit);
    expect(submit, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'learning library stays usable with larger text on a narrow phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      previewApp(
        const EducationLibraryScreen(),
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();

    final sources = find.text('Sources & review');
    await tester.scrollUntilVisible(
      sources,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(sources, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'warrior health profile stays usable with larger text on a narrow phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();

    await tester.pumpWidget(
      previewApp(
        WarriorHealthProfileScreen(profile: provider.warriorProfile!),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Safety notes'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Known triggers (comma-separated)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'medication and hydration stays usable with larger text on a narrow phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();

    await tester.pumpWidget(
      previewApp(
        const MedicationHydrationScreen(),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();

    final hydrationInterval =
        find.byKey(const Key('hydration-reminder-interval'));
    await tester.scrollUntilVisible(
      hydrationInterval,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(hydrationInterval, findsOneWidget);

    final medicationName = provider.activeMedications.first.name;
    final medicationCard = find.text(medicationName);
    await tester.scrollUntilVisible(
      medicationCard,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(medicationCard, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medication dose statuses appear in medication history',
      (tester) async {
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();
    final medicationName = provider.activeMedications.first.name;

    await tester.pumpWidget(
      previewApp(
        const MedicationHydrationScreen(),
        provider: provider,
      ),
    );
    await tester.pumpAndSettle();

    final skippedButton = find.byKey(
      Key('medication-dose-${provider.activeMedications.first.id}-skipped'),
    );
    await tester.scrollUntilVisible(
      skippedButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(skippedButton);
    await tester.pump();

    expect(
      provider.timeline.any(
        (event) => event.title == '$medicationName marked as skipped',
      ),
      isTrue,
    );
    expect(find.text('Skipped recorded in this preview.'), findsOneWidget);

    final historyButton = find.byKey(
      Key('medication-history-${provider.activeMedications.first.id}'),
    );
    await tester.scrollUntilVisible(
      historyButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(historyButton);
    await tester.pumpAndSettle();

    expect(find.byType(HealthTimelineScreen), findsOneWidget);
    expect(find.text('$medicationName marked as skipped'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hydration reminder can be paused and reconfigured locally',
      (tester) async {
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();

    await tester.pumpWidget(
      previewApp(
        const MedicationHydrationScreen(),
        provider: provider,
      ),
    );
    await tester.pumpAndSettle();

    final reminderSwitch = find.byKey(const Key('hydration-reminder-switch'));
    expect(find.text('Every 2 hours in this UI preview'), findsOneWidget);
    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();

    expect(provider.hydrationReminderEnabled, isFalse);
    expect(find.text('Paused for this UI preview session'), findsOneWidget);

    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();
    final intervalButton = find.byKey(const Key('hydration-reminder-interval'));
    await tester.ensureVisible(intervalButton);
    await tester.pumpAndSettle();
    await tester.tap(intervalButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('hydration-reminder-3h')));
    await tester.pumpAndSettle();

    expect(provider.hydrationReminderIntervalHours, 3);
    expect(find.text('Every 3 hours in this UI preview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'professional profile stays usable with larger text on a narrow phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();
    final profile = provider.doctorProfile!;

    await tester.pumpWidget(
      previewApp(
        DoctorProfessionalProfileScreen(
          fullName: profile.fullName,
          specialty: profile.specialty,
          facilityName: profile.facilityName,
          verificationStatus: profile.verificationStatus,
          profile: profile,
        ),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Qualifications (comma-separated)'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Qualifications (comma-separated)'), findsOneWidget);
    expect(
      find.text('MD, Clinical Haematology Fellowship'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Availability & contact'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Professional email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('professional profile saves preview qualifications',
      (tester) async {
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();
    final profile = provider.doctorProfile!;

    await tester.pumpWidget(
      previewApp(
        DoctorProfessionalProfileScreen(
          fullName: profile.fullName,
          specialty: profile.specialty,
          facilityName: profile.facilityName,
          verificationStatus: profile.verificationStatus,
          profile: profile,
        ),
        provider: provider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Edit'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Save'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), 'MD, MPH');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(provider.doctorProfile!.qualifications, ['MD', 'MPH']);
    expect(find.text('MD, MPH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('facility discovery renders mock facility records',
      (tester) async {
    final data = await const MockCareUiRepository().load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: FacilitiesScreen(facilities: data.facilities),
      ),
    );

    expect(
      find.text('SickleCare Preview Hospital', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('SickleCare Preview Clinic', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets(
      'facility map preview follows filters and opens a selected facility',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final data = await const MockCareUiRepository().load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.3)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: FacilitiesScreen(facilities: data.facilities),
      ),
    );
    await tester.pumpAndSettle();

    final openMap = find.byKey(const Key('open-facility-map-preview'));
    await tester.scrollUntilVisible(
      openMap,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(openMap);
    await tester.pumpAndSettle();

    expect(find.text('Facility map preview'), findsOneWidget);
    expect(find.text('3 places from the current results'), findsOneWidget);
    final clinicPin =
        find.byKey(const Key('facility-map-pin-mock-facility-bonaberi-clinic'));
    await tester.ensureVisible(clinicPin);
    await tester.tap(clinicPin);
    await tester.pumpAndSettle();
    final openDetails = find.byKey(const Key('map-preview-open-details'));
    await tester.ensureVisible(openDetails);
    expect(find.text('SickleCare Preview Clinic'), findsWidgets);
    await tester.tap(openDetails);
    await tester.pumpAndSettle();
    expect(find.byType(FacilityDetailScreen), findsOneWidget);
    expect(find.text('SickleCare Preview Clinic'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const Key('facilities-list')),
      const Offset(0, 1000),
      1000,
    );
    await tester.pumpAndSettle();
    final emergencyFilter = find.widgetWithText(FilterChip, 'Emergency care');
    await tester.tap(emergencyFilter);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      openMap,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(openMap);
    await tester.pumpAndSettle();

    expect(find.text('1 place from the current results'), findsOneWidget);
    expect(
      find.byKey(
          const Key('facility-map-pin-mock-facility-community-hospital')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('facility-map-pin-mock-facility-bonaberi-clinic')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('facility detail stays usable on a narrow screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final data = await const MockCareUiRepository().load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: FacilityDetailScreen(facility: data.facilities.first),
      ),
    );

    expect(find.text('SickleCare Preview Hospital'), findsWidgets);
    expect(
      find.text('Available services', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Contact & hours', skipOffstage: false), findsOneWidget);
  });

  testWidgets('verification and emergency states present safety guidance',
      (tester) async {
    await tester.pumpWidget(
      previewApp(
        const DoctorVerificationStatusScreen(
          status: DoctorVerificationStatus.pending,
        ),
        provider: CareUiProvider(autoLoad: false),
      ),
    );
    expect(find.text('Professional verification'), findsOneWidget);
    expect(find.text('Awaiting review', skipOffstage: false), findsOneWidget);

    final provider = CareUiProvider(autoLoad: false);
    await provider.load();
    await tester.pumpWidget(
      previewApp(const EmergencyInformationScreen(), provider: provider),
    );
    expect(find.text('Emergency information'), findsOneWidget);
    expect(find.text('Emergency card', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'credential submission stays usable with larger text on a narrow phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();

    await tester.pumpWidget(
      previewApp(
        const CredentialSubmissionScreen(
          verificationStatus: DoctorVerificationStatus.pending,
        ),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();

    final attachDocument =
        find.widgetWithText(OutlinedButton, 'Attach preview document');
    await tester.dragUntilVisible(
      attachDocument,
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.ensureVisible(attachDocument);
    await tester.pumpAndSettle();
    expect(find.text('Reference number (optional)'), findsOneWidget);
    await tester.tap(attachDocument);
    await tester.pumpAndSettle();
    expect(find.text('Attach a preview document'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('verification opens the local credential submission flow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();
    provider.updateDoctorProfile(
      provider.doctorProfile!.copyWith(
        verificationStatus: DoctorVerificationStatus.pending,
        credentials: const [],
      ),
    );

    await tester.pumpWidget(
      previewApp(
        const DoctorVerificationStatusScreen(
          status: DoctorVerificationStatus.pending,
        ),
        provider: provider,
      ),
    );
    await tester.pumpAndSettle();

    final addCredentials = find.widgetWithText(FilledButton, 'Add credentials');
    await tester.scrollUntilVisible(
      addCredentials,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(addCredentials);
    await tester.pumpAndSettle();
    expect(find.text('Submit credentials'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Issuing organisation'),
      'Preview Medical Council',
    );
    final attachDocument =
        find.widgetWithText(OutlinedButton, 'Attach preview document');
    await tester.ensureVisible(attachDocument);
    await tester.tap(attachDocument);
    await tester.pumpAndSettle();
    await tester.tap(find.text('medical_licence.pdf'));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Add for review'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add for review'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(provider.doctorProfile!.credentials, hasLength(1));
    expect(find.text('Professional verification'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('emergency information opens prefiltered emergency care',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();

    await tester.pumpWidget(
      previewApp(
        const EmergencyInformationScreen(),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const Key('emergency-information-list')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    final findEmergencyCareButton = find.widgetWithText(
      OutlinedButton,
      'Find emergency-capable care',
    );
    await tester.ensureVisible(findEmergencyCareButton);
    await tester.pumpAndSettle();
    await tester.tap(findEmergencyCareButton);
    await tester.pumpAndSettle();

    expect(find.text('Find care'), findsOneWidget);
    expect(find.text('Emergency care'), findsWidgets);
    expect(find.text('SickleCare Preview Hospital'), findsOneWidget);
    expect(find.text('SickleCare Preview Clinic'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('emergency care directory handles loading, error and retry',
      (tester) async {
    final fixture = await const MockCareUiRepository().load();
    final repository = _ControlledCareUiRepository();
    final provider = CareUiProvider(repository: repository, autoLoad: false)
      ..updateWarriorProfile(fixture.warriorProfile);
    final firstLoad = provider.load();

    await tester.pumpWidget(
      previewApp(const EmergencyInformationScreen(), provider: provider),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('emergency-information-list')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    final findEmergencyCareButton = find.widgetWithText(
      OutlinedButton,
      'Find emergency-capable care',
    );
    await tester.ensureVisible(findEmergencyCareButton);
    await tester.pumpAndSettle();
    await tester.tap(findEmergencyCareButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Finding care near you…'), findsOneWidget);
    expect(repository.requests, hasLength(1));

    repository.requests.single.completeError(StateError('Preview failure'));
    await firstLoad;
    await tester.pumpAndSettle();
    expect(find.text('Facilities are unavailable'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.text('Finding care near you…'), findsOneWidget);
    expect(repository.requests, hasLength(2));

    repository.requests.last.complete(fixture);
    await tester.pumpAndSettle();
    expect(find.text('SickleCare Preview Hospital'), findsOneWidget);
    expect(find.text('SickleCare Preview Clinic'), findsNothing);
  });

  testWidgets('emergency hotline remains available when preview data fails',
      (tester) async {
    final repository = _ControlledCareUiRepository();
    final provider = CareUiProvider(repository: repository, autoLoad: false);
    final load = provider.load();

    await tester.pumpWidget(
      previewApp(const EmergencyInformationScreen(), provider: provider),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.requests.single.completeError(StateError('Preview failure'));
    await load;
    await tester.pumpAndSettle();

    expect(find.text('Emergency preview unavailable'), findsOneWidget);
    expect(find.text('Call emergency services (112)'), findsOneWidget);
  });

  testWidgets(
      'a flagged crisis links to emergency information on a narrow screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();
    provider.addPainCrisis(
      PainCrisis(
        id: 'needs-attention',
        startedAt: DateTime.now(),
        intensity: 8,
        symptoms: const ['Severe pain'],
        affectedAreas: const ['Chest'],
        notes: 'Preview-only safety-flow test.',
        requiresMedicalAttention: true,
      ),
    );

    await tester.pumpWidget(
      previewApp(
        const CrisisTrackingScreen(),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();
    final emergencyButton = find.widgetWithText(
      OutlinedButton,
      'View emergency information',
    );
    await tester.dragUntilVisible(
      emergencyButton,
      find.byKey(const Key('crisis-tracker-list')),
      const Offset(0, -300),
    );
    await tester.ensureVisible(emergencyButton);
    await tester.pumpAndSettle();
    await tester.tap(emergencyButton);
    await tester.pumpAndSettle();

    expect(find.text('Emergency information'), findsOneWidget);
    expect(find.text('Call emergency services (112)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'symptom check-in validates and adds a local timeline event on a narrow screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();

    await tester.pumpWidget(
      previewApp(
        const CrisisTrackingScreen(),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();

    final logSymptoms = find.widgetWithText(OutlinedButton, 'Log symptoms');
    await tester.fling(
      find.byKey(const Key('crisis-tracker-list')),
      const Offset(0, -900),
      1000,
    );
    await tester.pumpAndSettle();
    await tester.tap(logSymptoms);
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('save-symptoms-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    expect(find.text('Add at least one symptom to continue.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('symptom-input')),
      'fatigue, joint pain',
    );
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final event = provider.timeline.firstWhere(
      (item) => item.id.startsWith('symptom-'),
    );
    expect(event.type, HealthTimelineEventType.symptom);
    expect(event.severity, 4);
    expect(event.description, contains('fatigue · joint pain'));
    expect(find.text('Symptoms logged in this UI preview.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ending a crisis adds a local health timeline event',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = CareUiProvider(autoLoad: false);
    final startedAt = DateTime.now().subtract(const Duration(hours: 2));
    provider.addPainCrisis(
      PainCrisis(
        id: 'ongoing-crisis',
        startedAt: startedAt,
        intensity: 7,
        symptoms: const ['Joint pain'],
        affectedAreas: const ['Lower back'],
      ),
    );

    await tester.pumpWidget(
      previewApp(
        const CrisisTrackingScreen(),
        provider: provider,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();

    final endCrisis = find.widgetWithText(OutlinedButton, 'Mark as ended');
    await tester.dragUntilVisible(
      endCrisis,
      find.byKey(const Key('crisis-tracker-list')),
      const Offset(0, -300),
    );
    await tester.ensureVisible(endCrisis);
    await tester.pumpAndSettle();
    await tester.tap(endCrisis);
    await tester.pumpAndSettle();

    final crisis = provider.painCrises.firstWhere(
      (item) => item.id == 'ongoing-crisis',
    );
    expect(crisis.endedAt, isNotNull);
    final completedEvent = provider.timeline.firstWhere(
      (item) => item.id == 'crisis-ended-ongoing-crisis',
    );
    expect(completedEvent.title, 'Pain crisis marked as ended');
    expect(completedEvent.severity, 7);
    expect(find.text('Ended'), findsOneWidget);

    final timelineButton =
        find.widgetWithText(TextButton, 'View health timeline');
    await tester.ensureVisible(timelineButton);
    await tester.tap(timelineButton);
    await tester.pumpAndSettle();
    expect(find.text('Pain crisis marked as ended'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('mock care provider filters facilities and updates hydration', () async {
    final provider = CareUiProvider(autoLoad: false);
    await provider.load();

    expect(provider.visibleFacilities.length, 3);
    provider.setFacilityTypeFilter(FacilityType.clinic);
    expect(provider.visibleFacilities, hasLength(1));
    expect(provider.visibleFacilities.single.name, 'SickleCare Preview Clinic');

    final before = provider.hydrationTodayMl;
    expect(provider.logHydration(250), isTrue);
    expect(provider.hydrationTodayMl, before + 250);
  });

  test('clinician preview state survives a fixture load', () async {
    const profile = DoctorProfile(
      id: 'new-clinician',
      fullName: 'Dr. Taylor N.',
      specialty: 'Paediatrics',
      qualifications: ['MD'],
      facilityName: 'Preview Clinic',
      email: 'taylor@example.test',
      phoneNumber: '+237 600 000 001',
      availabilitySummary: 'Tue–Sat',
      isAvailable: true,
      verificationStatus: DoctorVerificationStatus.pending,
      credentials: [],
    );
    final provider = CareUiProvider(autoLoad: false)
      ..updateDoctorProfile(profile);

    await provider.load();

    expect(provider.doctorProfile?.fullName, 'Dr. Taylor N.');
    expect(provider.doctorProfile?.credentials, isEmpty);
    expect(provider.hasLoaded, isTrue);
  });
}
