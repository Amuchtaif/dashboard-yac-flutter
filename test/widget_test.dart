// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:dashboard_yac/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Pass isSessionValid: false to force Login Screen
    await tester.pumpWidget(const MyApp(isSessionValid: false));

    // Verify that Login Screen appears (Find "Sign In" button or text)
    expect(find.text('Sign In'), findsOneWidget);
  });
}
