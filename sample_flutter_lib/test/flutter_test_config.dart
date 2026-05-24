import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_flutter_lib/sample_flutter_lib.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() async {
    await SampleFlutterLibBundled.initBundled();
  });

  await testMain();
}
