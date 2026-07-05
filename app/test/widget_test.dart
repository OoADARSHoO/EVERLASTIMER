import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everlastimer/main.dart';

void main() {
  testWidgets('Everlastimer App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EverlastimerApp(),
      ),
    );

    // Verify that the EverlastimerApp widget is present.
    expect(find.byType(EverlastimerApp), findsOneWidget);
  });
}
