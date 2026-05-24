import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_flutter_app/main.dart';
import 'package:sample_flutter_lib/sample_flutter_lib.dart';

/// Widget tests for [AdditionScreen].
///
/// These tests run inside the app context of the sample project, so they
/// exercise the full library-bundling path for host-machine widget tests —
/// the same code path that would execute on a physical iOS or Android device.
void main() {
  setUpAll(() async {
    await SampleFlutterLibBundled.initBundled();
  });

  testWidgets('AdditionScreen displays the correct sum', (tester) async {
    await tester.pumpWidget(const SampleApp());

    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byKey(const Key('sum')), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.byKey(const Key('isolate_button')), findsOneWidget);
  });

  testWidgets(
    'compute() re-initializes the library in a background isolate and returns the correct result',
    (tester) async {
      final key = GlobalKey<AdditionScreenState>();
      await tester.pumpWidget(MaterialApp(home: AdditionScreen(key: key)));

      expect(find.text('5'), findsOneWidget);
      expect(find.byKey(const Key('isolate_button')), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('isolate_button')));
        await key.currentState!.pendingCompute;
      });

      await tester.pump();

      expect(find.byKey(const Key('isolate_loading')), findsNothing);
      expect(find.byKey(const Key('isolate_result')), findsOneWidget);
      expect(find.text('5'), findsNWidgets(2));
    },
  );
}
