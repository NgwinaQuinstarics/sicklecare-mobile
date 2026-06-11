import 'package:flutter_test/flutter_test.dart';
import 'package:sicklecare_app/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const SickleCareApp(),
    );

    await tester.pumpAndSettle();
  });
}