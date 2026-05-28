import 'package:chime_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChimeApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChimeApp());

    // Verify the app renders without throwing.
    expect(find.byType(ChimeApp), findsOneWidget);
  });
}
