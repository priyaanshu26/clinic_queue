// Basic widget test for ClinicQueueApp
import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_queue/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const ClinicQueueApp());
    // Verify it starts without crashing
    expect(find.byType(ClinicQueueApp), findsOneWidget);
  });
}
