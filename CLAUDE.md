# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Dart FFI package (`privacypass_ffi`) exposing Kagi's Privacy Pass protocol implementation (VOPRF/Ristretto255, RFC 9578) written in Rust. The Rust source lives in the `rust/` git submodule ([kagisearch/privacypass-lib](https://github.com/kagisearch/privacypass-lib)); this repo wraps its compiled output for Android, iOS, and macOS. It follows the Flutter `package_ffi` template architecture (build hooks + code assets, standard since Flutter 3.38): there are **no platform folders, podspecs, or gradle files** — `hook/build.dart` registers a prebuilt library as a code asset per build target, and Dart resolves the `@Native` bindings by asset id at runtime.

Prebuilt binaries are committed under `prebuilt/` (Android `.so` per ABI, iOS `.dylib` per SDK/arch, macOS universal `.dylib`), so Dart-only changes do not require a Rust toolchain.

## Commands

```bash
dart test                                         # run unit tests (build hook loads the prebuilt macOS dylib)
dart test --plain-name "generateTokenRequest"     # run a single test by name
dart analyze                                      # lint (flutter_lints)
cd example && flutter run                         # run the demo app
dart run ffigen --config ffigen.yaml              # regenerate bindings from src/kagipp_ffi.h
bash scripts/update_prebuilt_libs.sh              # rebuild all native libs from the rust/ submodule
```

Rebuilding native libraries requires rustup targets for Android/iOS/macOS, `cargo install cargo-ndk cbindgen`, the Android NDK, and Xcode. The script also refreshes `src/kagipp_ffi.h` (cbindgen output); regenerate the Dart bindings afterwards if the FFI surface changed.

## Architecture

### Build & bundling flow

1. `hook/build.dart` (package:hooks + package:code_assets) runs on every `flutter build`/`flutter run`/`dart test`. It picks the right file from `prebuilt/` based on `targetOS`, `targetArchitecture`, and iOS `targetSdk`, and registers it as a `CodeAsset` with `DynamicLoadingBundled`.
2. The `CodeAsset` **name** (`src/privacypass_ffi_bindings_generated.dart`) must match the default asset id of the `@Native` declarations in `lib/src/privacypass_ffi_bindings_generated.dart` (i.e. the bindings file's path under `lib/`). If you move or rename the bindings file, update the hook.
3. Flutter bundles the library (wrapped into `kagipp_ffi.framework` on Apple platforms, jniLibs on Android) and resolves symbols at runtime — no `DynamicLibrary.open`, no `-force_load`/symbol-retention tricks.

### Dart layers (`lib/src/`)

- `privacypass_ffi_bindings_generated.dart` — ffigen-generated `@Native` externals. DO NOT EDIT; regenerate via ffigen from `src/kagipp_ffi.h`.
- `privacy_pass_client.dart` — synchronous API (`PrivacyPassClient`). Handles marshalling and memory: every pointer returned by Rust must be freed with `privacy_pass_free_string`; every Dart-allocated native string with `malloc.free` (both done in `finally` blocks).
- `privacy_pass_isolate.dart` — async API (`PrivacyPassIsolate`), one `Isolate.run` per call. Errors are rethrown as `PrivacyPassException` (which is sendable across isolates).
- `types.dart` — `TokenRequestResult` and `PrivacyPassException`.

### FFI contract

Strings across the boundary are JSON envelopes, and errors are reported **in-band** via an `error` field rather than null returns — e.g. input `{"header": "...", "error": ""}`, output objects with `state`/`token_request`/`tokens` plus an `error` string. `PrivacyPassClient` checks each `error` field and throws `PrivacyPassException` when non-empty. The Rust side is the `kagipp_ffi` crate (`rust/src/ffi/`), built as `cdylib`, wrapping the `kagippcore` crate.

### Prebuilt library invariants

- iOS libraries must be **dynamic** (`.dylib`) — code assets do not support static linking — with the same file name across device and simulator SDKs (Flutter combines them into an xcframework).
- Dylibs get `install_name_tool -id @rpath/libkagipp_ffi.dylib` and an ad-hoc codesign (`scripts/update_prebuilt_libs.sh` does this).
- All dylibs are **thin** (one per architecture), including macOS. The hook runs once per target architecture and Flutter lipo-combines the per-arch outputs into a universal framework itself — handing it a fat dylib for multiple architectures makes release builds fail (`lipo: ... have the same architectures`).
- On universal macOS builds, flutter_tools (as of 3.44) prints a spurious warning — `Code asset ... has different framework names for different architectures. Picking "kagipp_ffi.framework" and ignoring "kagipp_ffi1.framework"` — even with consistent filenames. It's an upstream bug in `fatAssetTargetLocations` (the per-arch `frameworkUri` call collides with itself in `alreadyTakenNames`); the build output is correct and the warning can be ignored.
