#!/bin/bash
# Copy compiled Rust libraries to Android jniLibs directory
# Run this after building the Rust FFI library

set -e

echo "📋 Copying Android libraries to Flutter plugin..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
RUST_DIR="$PLUGIN_DIR/../privacypass-lib/src/target"
ANDROID_JNILIBS="$PLUGIN_DIR/android/src/main/jniLibs"
MISSING=0

# Check if Rust build output exists
if [ ! -d "$RUST_DIR" ]; then
    echo "❌ Error: Rust target directory not found at $RUST_DIR"
    echo "   Please build the Rust FFI library first:"
    echo "   cd ../privacypass-lib/src/ffi && bash build_android.sh"
    exit 1
fi

# Create jniLibs directories
mkdir -p "$ANDROID_JNILIBS"/{arm64-v8a,armeabi-v7a,x86_64}

# Copy libraries
echo "  • Copying arm64-v8a..."
if [ -f "$RUST_DIR/aarch64-linux-android/release/libkagipp_ffi.so" ]; then
    cp "$RUST_DIR/aarch64-linux-android/release/libkagipp_ffi.so" \
       "$ANDROID_JNILIBS/arm64-v8a/"
    echo "    ✓ arm64-v8a"
else
    echo "    ⚠️  arm64-v8a library not found"
    MISSING=1
fi

echo "  • Copying armeabi-v7a..."
if [ -f "$RUST_DIR/armv7-linux-androideabi/release/libkagipp_ffi.so" ]; then
    cp "$RUST_DIR/armv7-linux-androideabi/release/libkagipp_ffi.so" \
       "$ANDROID_JNILIBS/armeabi-v7a/"
    echo "    ✓ armeabi-v7a"
else
    echo "    ⚠️  armeabi-v7a library not found"
    MISSING=1
fi

echo "  • Copying x86_64..."
if [ -f "$RUST_DIR/x86_64-linux-android/release/libkagipp_ffi.so" ]; then
    cp "$RUST_DIR/x86_64-linux-android/release/libkagipp_ffi.so" \
       "$ANDROID_JNILIBS/x86_64/"
    echo "    ✓ x86_64"
else
    echo "    ⚠️  x86_64 library not found"
    MISSING=1
fi

if [ "$MISSING" -ne 0 ]; then
    echo ""
    echo "⚠️  Some libraries were not found"
    exit 1
fi

echo ""
echo "✅ Android libraries copied successfully!"
echo "   Location: $ANDROID_JNILIBS"
echo ""
