/// Integration tests for the sample app.
///
/// These tests run inside the real app on a simulator or physical device,
/// exercising the full native-library bundling and loading path for the target
/// platform — something the host-machine widget tests in test/ cannot cover.
///
/// Run with:
///   flutter test integration_test/ -d DEVICE_ID
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sample_flutter_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native library loads and sum is displayed correctly', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byKey(const Key('sum')), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets(
    'background isolate re-initializes the library and returns the correct result',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('isolate_button')));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );

      expect(find.byKey(const Key('isolate_loading')), findsNothing);
      expect(find.byKey(const Key('isolate_result')), findsOneWidget);
      expect(find.text('5'), findsNWidgets(2));
    },
  );
}
