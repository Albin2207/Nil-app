// Basic Flutter widget test for NIL App
// To run tests: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:nil_app/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app builds successfully
    expect(find.byType(MyApp), findsOneWidget);
  });
}
