# Minimal flutter_rust_bridge + Code Assets Sample

This repository demonstrates how to expose a small Rust library to Flutter using
[`flutter_rust_bridge`](https://cjycode.com/flutter_rust_bridge/) 2.12, Dart/Flutter
code assets, and build hooks.

The sample intentionally uses toy logic (`add(left, right)`) so the interesting
parts are the package layout, native build hook, bundled library loading, and
integration-test setup.

## Architecture

```
sample_rust_lib/       Pure Rust library (rlib), no flutter_rust_bridge dependency
sample_flutter_lib/    Flutter package, FRB bridge crate, generated bindings, build hook
sample_flutter_app/    Root-level Flutter app consuming sample_flutter_lib
```

The important pieces are:

- `sample_rust_lib/src/lib.rs` contains the Rust-only API.
- `sample_flutter_lib/rust/src/api.rs` contains the thin FRB wrapper around the Rust-only library.
- `sample_flutter_lib/hook/build.dart` compiles the Rust bridge crate as a code asset using `native_toolchain_rust`.
- `sample_flutter_lib/lib/src/sample_flutter_lib_bundled.dart` loads the generated native library for tests, apps, and worker isolates.

## Prerequisites

- [mise](https://mise.jdx.dev/) for pinned `flutter`, `dart`, `rust`, `flutter_rust_bridge_codegen`, and `jq`.
- Android SDK for Android integration tests.
- Xcode for iOS/macOS integration tests.

CocoaPods is not required. The sample app uses Flutter's Swift Package Manager
integration for iOS/macOS.

## Setup

```bash
mise install
mise build
```

`mise install` also runs the postinstall hook, which fetches Cargo dependencies
and runs `flutter pub get` in both Dart/Flutter packages.

## Commands

```bash
mise tasks            # list available tasks
mise build            # regenerate FRB bindings and build the Rust bridge crate
mise check            # rust fmt/clippy + Dart format/analyze
mise test             # Rust tests + Flutter package/app widget tests
mise integration-test # interactive device picker for integration tests
```

## Integration tests

Integration tests require a real device or simulator. The task supports Android,
iOS, and macOS devices.

```bash
mise integration-test              # interactive device picker
mise integration-test -d DEVICE_ID # specific device/simulator
```

Platform-specific behavior:

- Android uses Flutter's standard debug signing configuration.
- iOS writes a local `sample_flutter_app/ios/Flutter/LocalSigning.xcconfig` file with the selected Apple team and a derived bundle identifier. That file is ignored by Git.
- macOS runs without extra signing setup for the sample.
- Web/Chrome is rejected because this sample is native-library only (`web: false` in `flutter_rust_bridge.yaml`).

## Regenerating Bindings

After changing `sample_flutter_lib/rust/src/api.rs`, run:

```bash
mise build
```

Generated files under `sample_flutter_lib/lib/src/rust/` and
`sample_flutter_lib/rust/src/frb_generated.rs` are committed to the repo so the
sample can be cloned and tested without requiring users to inspect generated
output manually.

## How This Differs From A Normal FRB Setup

A very small `flutter_rust_bridge` project often has one Flutter package with a
`rust/` crate inside it. The Rust code, FRB API surface, and Flutter package all
live together. This sample intentionally splits those responsibilities:

- `sample_rust_lib` is a plain Rust library. It can be tested with `cargo test`
  and has no dependency on Flutter or FRB.
- `sample_flutter_lib/rust` is only the native bridge crate. It builds as
  `cdylib`/`staticlib`, depends on `sample_rust_lib`, and exposes thin
  `#[frb(...)]` wrapper functions.
- `sample_flutter_lib` is the reusable Dart/Flutter package containing the build
  hook, generated Dart bindings, and bundled native-library loader.
- `sample_flutter_app` is just a consumer app, kept separate from the bindings
  package to show how another Flutter project depends on it.

The second important difference is native library loading. With code assets,
`hook/build.dart` compiles the Rust bridge crate during Flutter builds/tests and
records the resulting dynamic library as a native asset. FRB 2.x still expects an
`ExternalLibrary`, so `SampleFlutterLibBundled.initBundled()` explicitly opens
the right library:

- iOS uses the bundled framework-relative path.
- Android uses the extracted `.so` filename.
- Desktop and `flutter test` read the hook runner's `output.json` to find the
  absolute dylib path.

The sample app also tests background isolates. A worker spawned with
`compute()` calls `SampleFlutterLibBundled.initBundled()` again before using the
generated API, because each isolate has its own Dart heap and initialization
state.
