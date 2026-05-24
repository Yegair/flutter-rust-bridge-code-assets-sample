import 'dart:convert';
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'rust/frb_generated.dart';

const _packageName = 'sample_flutter_lib';
const _assetId = 'package:$_packageName/src/rust/frb_generated.io.dart';

extension SampleFlutterLibBundled on SampleFlutterLib {
  /// Initializes [SampleFlutterLib] using the dylib compiled by the code-asset
  /// build hook (`hook/build.dart` / `native_toolchain_rust`).
  ///
  /// This is a temporary bridge until flutter_rust_bridge natively understands
  /// code assets (planned for FRB v3, which will use `@Native` bindings and
  /// won't need `DynamicLibrary.open` at all).
  ///
  /// The Dart VM does not currently resolve `package:` URIs in
  /// `DynamicLibrary.open` on any platform. We use a per-platform strategy:
  /// * **iOS** – framework-relative path (`name.framework/name`); the Dart VM
  ///   probes `Runner.app/Frameworks/` automatically.
  /// * **Android** – bare `.so` filename; extracted by the OS at install time.
  /// * **Desktop / `flutter test`** – absolute path read from the hook
  ///   runner's `output.json` in `.dart_tool/hooks_runner/`.
  static Future<void> initBundled({SampleFlutterLibApi? api}) async {
    // Guard against double-initialization. This can happen in integration tests
    // where app.main() is called more than once in the same process, or when
    // hot-restart re-executes main() without restarting the Dart VM.
    if (SampleFlutterLib.instance.initialized) {
      return;
    }

    await SampleFlutterLib.init(
      externalLibrary: _openBundledLibrary(),
      api: api,
    );
  }

  static ExternalLibrary _openBundledLibrary() {
    if (Platform.isIOS) {
      // On iOS the code asset is bundled as a .framework inside
      // Runner.app/Frameworks/. Dart's DynamicLibrary.open probes
      // @executable_path/../Frameworks/<path> among its search paths, so the
      // framework-relative path resolves correctly. Passing the raw package:
      // URI to dlopen does not work: the Dart VM does not intercept it for
      // DynamicLoadingBundled assets in the current Flutter/Dart runtime.
      return ExternalLibrary.open('$_packageName.framework/$_packageName');
    }

    if (Platform.isAndroid) {
      // On Android the .so is extracted into the app's lib directory at install
      // time and is therefore reachable by its bare filename.
      return ExternalLibrary.open('lib$_packageName.so');
    }

    // Desktop (macOS, Linux, Windows) and flutter test:
    // The build hook places the compiled library at a path recorded in
    // .dart_tool/hooks_runner/<pkg>/<hash>/output.json. Read that file to get
    // the absolute path, bypassing the unresolved package: URI issue in
    // DynamicLibrary.open.
    final hookDir = Directory('.dart_tool/hooks_runner/$_packageName');
    if (hookDir.existsSync()) {
      for (final entry in hookDir.listSync()) {
        if (entry is! Directory) continue;
        final outputJson = File('${entry.path}/output.json');
        if (!outputJson.existsSync()) continue;
        try {
          final json = jsonDecode(outputJson.readAsStringSync()) as Map<String, dynamic>;
          for (final raw in (json['assets'] as List? ?? [])) {
            final asset = raw as Map<String, dynamic>;
            final encoding = asset['encoding'] as Map<String, dynamic>? ?? {};
            if (encoding['id'] == _assetId) {
              final file = encoding['file'] as String?;
              if (file != null) return ExternalLibrary.open(file);
            }
          }
        } catch (_) {
          // Malformed output.json – skip and try next entry.
        }
      }
    }

    // Last-resort fallback: attempt to let the Flutter runtime resolve the
    // code-asset URI. This is expected to work once the Dart VM natively
    // supports DynamicLoadingBundled asset resolution (tracked in FRB v3).
    return ExternalLibrary.open(_assetId);
  }
}
