import 'package:sample_flutter_lib/sample_flutter_lib.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';

/// Entry point for the background isolate spawned via [compute].
///
/// Must be a top-level function. Flutter's [compute] passes the function
/// reference and the message through a [SendPort], so no closure is created
/// and the widget's `this` is never captured.
Future<int> _addOnIsolate(({int left, int right}) args) async {
  // Each isolate starts with a blank heap – re-initialize the native library.
  await SampleFlutterLibBundled.initBundled();
  return add(left: args.left, right: args.right);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SampleFlutterLibBundled.initBundled();
  runApp(const SampleApp());
}

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sample Flutter App',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const AdditionScreen(),
    );
  }
}

/// Displays two hardcoded integers, their synchronous sum, and the result of
/// adding them on a background isolate.
class AdditionScreen extends StatefulWidget {
  const AdditionScreen({super.key});

  @override
  AdditionScreenState createState() => AdditionScreenState();
}

class AdditionScreenState extends State<AdditionScreen> {
  static const _left = 2;
  static const _right = 3;

  late final int _sum;
  int? _isolateResult;
  bool _computing = false;

  /// The in-flight isolate computation, exposed so that tests can await it
  /// directly via [GlobalKey] instead of polling.
  @visibleForTesting
  Future<void>? pendingCompute;

  @override
  void initState() {
    super.initState();
    _sum = add(left: _left, right: _right);
  }

  Future<void> _computeOnIsolate() async {
    setState(() {
      _computing = true;
      _isolateResult = null;
    });
    try {
      final result = await compute(_addOnIsolate, (left: _left, right: _right));
      setState(() {
        _isolateResult = result;
        _computing = false;
      });
    } catch (_) {
      setState(() => _computing = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Integer Addition')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_left', style: theme.headlineMedium),
            Text('+', style: theme.headlineMedium),
            Text('$_right', style: theme.headlineMedium),
            const Divider(indent: 40, endIndent: 40),
            Text('$_sum', key: const Key('sum'), style: theme.headlineLarge),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('isolate_button'),
              onPressed: _computing
                  ? null
                  : () => pendingCompute = _computeOnIsolate(),
              child: const Text('Add on background isolate'),
            ),
            const SizedBox(height: 16),
            if (_computing)
              const CircularProgressIndicator(key: Key('isolate_loading'))
            else if (_isolateResult != null)
              Text(
                '$_isolateResult',
                key: const Key('isolate_result'),
                style: theme.headlineLarge,
              ),
          ],
        ),
      ),
    );
  }
}
