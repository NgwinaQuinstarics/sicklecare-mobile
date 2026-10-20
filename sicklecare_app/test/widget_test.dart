import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sicklecare_app/data/care_ui_repository.dart';
import 'package:sicklecare_app/login.dart';
import 'package:sicklecare_app/models/doctor_profile.dart';
import 'package:sicklecare_app/models/healthcare_facility.dart';
import 'package:sicklecare_app/providers/care_ui_provider.dart';
import 'package:sicklecare_app/screens/auth/role_selection_screen.dart';
import 'package:sicklecare_app/screens/care/care_hub_screen.dart';
import 'package:sicklecare_app/screens/care/emergency_information_screen.dart';
import 'package:sicklecare_app/screens/doctor/doctor_dashboard_screen.dart';
import 'package:sicklecare_app/screens/doctor/doctor_registration_screen.dart';
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
      find.text('Pain crisis tracker', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Medicines & hydration', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Emergency information', skipOffstage: false),
      findsOneWidget,
    );
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
