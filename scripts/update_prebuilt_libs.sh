#!/bin/bash
# Build the Rust FFI library from the rust/ submodule for all supported
# targets and refresh the prebuilt libraries consumed by hook/build.dart.
#
# Prerequisites:
#   - rustup targets: aarch64-linux-android armv7-linux-androideabi
#     x86_64-linux-android aarch64-apple-ios aarch64-apple-ios-sim
#     x86_64-apple-ios aarch64-apple-darwin x86_64-apple-darwin
#   - cargo install cargo-ndk cbindgen
#   - Android NDK (for Android), Xcode (for iOS/macOS)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
FFI_DIR="$PLUGIN_DIR/rust/src/ffi"
TARGET_DIR="$PLUGIN_DIR/rust/src/target"
PREBUILT_DIR="$PLUGIN_DIR/prebuilt"

IOS_MIN_VERSION="${IPHONEOS_DEPLOYMENT_TARGET:-13.0}"

if [ ! -d "$FFI_DIR" ]; then
    echo "❌ Rust submodule not initialized. Run: git submodule update --init"
    exit 1
fi

cd "$FFI_DIR"

echo "🤖 Building Android (arm64-v8a, armeabi-v7a, x86_64)..."
cargo ndk \
    --target aarch64-linux-android \
    --target armv7-linux-androideabi \
    --target x86_64-linux-android \
    --platform 24 \
    -- build --release

echo "🍎 Building iOS (device arm64, simulator arm64 + x86_64)..."
IPHONEOS_DEPLOYMENT_TARGET="$IOS_MIN_VERSION" cargo build --release --target aarch64-apple-ios
IPHONEOS_DEPLOYMENT_TARGET="$IOS_MIN_VERSION" cargo build --release --target aarch64-apple-ios-sim
IPHONEOS_DEPLOYMENT_TARGET="$IOS_MIN_VERSION" cargo build --release --target x86_64-apple-ios

echo "🖥️  Building macOS (arm64 + x86_64)..."
cargo build --release --target aarch64-apple-darwin
cargo build --release --target x86_64-apple-darwin

echo "📋 Copying libraries to $PREBUILT_DIR..."
mkdir -p "$PREBUILT_DIR"/android/{arm64-v8a,armeabi-v7a,x86_64} \
         "$PREBUILT_DIR"/ios/iphoneos/arm64 \
         "$PREBUILT_DIR"/ios/iphonesimulator/{arm64,x64} \
         "$PREBUILT_DIR"/macos/{arm64,x64}

cp "$TARGET_DIR/aarch64-linux-android/release/libkagipp_ffi.so"  "$PREBUILT_DIR/android/arm64-v8a/"
cp "$TARGET_DIR/armv7-linux-androideabi/release/libkagipp_ffi.so" "$PREBUILT_DIR/android/armeabi-v7a/"
cp "$TARGET_DIR/x86_64-linux-android/release/libkagipp_ffi.so"   "$PREBUILT_DIR/android/x86_64/"

cp "$TARGET_DIR/aarch64-apple-ios/release/libkagipp_ffi.dylib"     "$PREBUILT_DIR/ios/iphoneos/arm64/"
cp "$TARGET_DIR/aarch64-apple-ios-sim/release/libkagipp_ffi.dylib" "$PREBUILT_DIR/ios/iphonesimulator/arm64/"
cp "$TARGET_DIR/x86_64-apple-ios/release/libkagipp_ffi.dylib"      "$PREBUILT_DIR/ios/iphonesimulator/x64/"

# Thin per-arch dylibs: Flutter's build lipo-combines per-architecture hook
# outputs itself, so a fat dylib here would make universal builds fail.
cp "$TARGET_DIR/aarch64-apple-darwin/release/libkagipp_ffi.dylib" "$PREBUILT_DIR/macos/arm64/"
cp "$TARGET_DIR/x86_64-apple-darwin/release/libkagipp_ffi.dylib"  "$PREBUILT_DIR/macos/x64/"

echo "🔧 Normalizing dylib install names and signing..."
for dylib in \
    "$PREBUILT_DIR/ios/iphoneos/arm64/libkagipp_ffi.dylib" \
    "$PREBUILT_DIR/ios/iphonesimulator/arm64/libkagipp_ffi.dylib" \
    "$PREBUILT_DIR/ios/iphonesimulator/x64/libkagipp_ffi.dylib" \
    "$PREBUILT_DIR/macos/arm64/libkagipp_ffi.dylib" \
    "$PREBUILT_DIR/macos/x64/libkagipp_ffi.dylib"; do
    install_name_tool -id @rpath/libkagipp_ffi.dylib "$dylib"
    codesign -f -s - "$dylib"
done

echo "📄 Refreshing C header (src/kagipp_ffi.h)..."
if command -v cbindgen &> /dev/null; then
    (cd "$FFI_DIR" && cbindgen --config cbindgen.toml --output "$PLUGIN_DIR/src/kagipp_ffi.h")
    echo "   Regenerate Dart bindings with: dart run ffigen --config ffigen.yaml"
else
    echo "⚠️  cbindgen not installed, skipping header refresh (cargo install cbindgen)"
fi

echo ""
echo "✅ Prebuilt libraries updated."
find "$PREBUILT_DIR" -type f -exec ls -lh {} \; | awk '{print "   " $5 "\t" $9}'
