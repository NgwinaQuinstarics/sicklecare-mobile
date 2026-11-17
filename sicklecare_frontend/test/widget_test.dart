import 'package:flutter_test/flutter_test.dart';
import 'package:sicklecare_app/main.dart';
import 'package:sicklecare_app/screens/splash_screen.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const SickleCareApp(),
    );

    // Verify that SplashScreen is displayed and app initiates successfully
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the first animation frame settle without crossing the splash
    // navigation timer.
    await tester.pump(const Duration(milliseconds: 450));
  });

  testWidgets('Firebase startup failure shows a retryable error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      FirebaseStartupErrorApp(
        onRetry: () async => throw StateError('Firebase unavailable'),
      ),
    );

    expect(find.text('SickleCare could not connect'), findsOneWidget);
    await tester.tap(find.text('Retry connection'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Connection still unavailable. Check your internet connection and try again.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
