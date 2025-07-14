// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:random_mtg_card/main.dart';
import 'package:random_mtg_card/services/config_service.dart';

void main() {
  testWidgets('MTG Card Display App smoke test', (WidgetTester tester) async {
    // Initialize ConfigService before running the test
    await ConfigService.initialize();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MTGCardDisplayApp());

    // Verify that the app loads
    expect(find.byType(MTGCardDisplayApp), findsOneWidget);

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // The app should have loaded without errors
    expect(tester.takeException(), isNull);
  });
}
