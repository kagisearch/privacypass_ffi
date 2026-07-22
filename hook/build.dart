import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

/// Registers the prebuilt Rust library (libkagipp_ffi) as a code asset for
/// the current build target.
///
/// The libraries under `prebuilt/` are compiled from the Rust FFI crate in
/// the `rust/` submodule. Refresh them with `bash scripts/update_prebuilt_libs.sh`.
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }

    final code = input.config.code;
    final os = code.targetOS;
    final arch = code.targetArchitecture;
    final prebuilt = input.packageRoot.resolve('prebuilt/');

    final Uri library;
    switch (os) {
      case OS.android:
        final abi = switch (arch) {
          Architecture.arm64 => 'arm64-v8a',
          Architecture.arm => 'armeabi-v7a',
          Architecture.x64 => 'x86_64',
          _ => throw UnsupportedError('Unsupported Android architecture: $arch'),
        };
        library = prebuilt.resolve('android/$abi/libkagipp_ffi.so');
      case OS.iOS:
        final sdk = switch (code.iOS.targetSdk) {
          IOSSdk.iPhoneOS => 'iphoneos',
          IOSSdk.iPhoneSimulator => 'iphonesimulator',
          _ => throw UnsupportedError('Unsupported iOS SDK: ${code.iOS.targetSdk}'),
        };
        final archDir = switch (arch) {
          Architecture.arm64 => 'arm64',
          Architecture.x64 => 'x64',
          _ => throw UnsupportedError('Unsupported iOS architecture: $arch'),
        };
        library = prebuilt.resolve('ios/$sdk/$archDir/libkagipp_ffi.dylib');
      case OS.macOS:
        // Thin per-architecture dylibs: the hook runs once per architecture
        // and Flutter lipo-combines the outputs into a universal binary, so
        // handing it a fat dylib for both architectures would fail.
        final archDir = switch (arch) {
          Architecture.arm64 => 'arm64',
          Architecture.x64 => 'x64',
          _ => throw UnsupportedError('Unsupported macOS architecture: $arch'),
        };
        library = prebuilt.resolve('macos/$archDir/libkagipp_ffi.dylib');
      default:
        throw UnsupportedError('Unsupported OS: $os');
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        // Must match the asset id of the @Native bindings in
        // lib/src/privacypass_ffi_bindings_generated.dart.
        name: 'src/privacypass_ffi_bindings_generated.dart',
        linkMode: DynamicLoadingBundled(),
        file: library,
      ),
    );
  });
}
