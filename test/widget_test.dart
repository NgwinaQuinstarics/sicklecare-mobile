import 'package:flutter_test/flutter_test.dart';
import 'package:sicklecare_app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SickleCareApp());

    expect(find.byType(SickleCareApp), findsOneWidget);
  });
}