#!/bin/bash
# Copy compiled Rust libraries to iOS Frameworks directory
# Run this after building the Rust FFI library

set -e

echo "📋 Copying iOS libraries to Flutter plugin..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
RUST_DIR="$PLUGIN_DIR/../privacypass-lib/src/target"
IOS_FRAMEWORKS="$PLUGIN_DIR/ios/Frameworks"
MISSING=0

# Check if Rust build output exists
if [ ! -d "$RUST_DIR" ]; then
    echo "❌ Error: Rust target directory not found at $RUST_DIR"
    echo "   Please build the Rust FFI library first:"
    echo "   cd ../privacypass-lib/src/ffi && bash build_ios.sh"
    exit 1
fi

# Create Frameworks directory
mkdir -p "$IOS_FRAMEWORKS"

# Copy device library (arm64)
echo "  • Copying device library (arm64)..."
if [ -f "$RUST_DIR/aarch64-apple-ios/release/libkagipp_ffi.a" ]; then
    cp "$RUST_DIR/aarch64-apple-ios/release/libkagipp_ffi.a" \
       "$IOS_FRAMEWORKS/"
    echo "    ✓ Device library (arm64)"
else
    echo "    ⚠️  Device library not found"
    MISSING=1
fi

# Copy universal simulator library
echo "  • Copying simulator library (universal)..."
if [ -f "$RUST_DIR/universal-ios-sim/libkagipp_ffi.a" ]; then
    cp "$RUST_DIR/universal-ios-sim/libkagipp_ffi.a" \
       "$IOS_FRAMEWORKS/libkagipp_ffi_sim.a"
    echo "    ✓ Simulator library (universal: x86_64 + arm64)"
else
    echo "    ⚠️  Simulator library not found"
    echo "       Note: Simulator library should be built by build_ios.sh"
    MISSING=1
fi

if [ "$MISSING" -ne 0 ]; then
    echo ""
    echo "⚠️  Some libraries were not found"
    exit 1
fi

echo ""
echo "✅ iOS libraries copied successfully!"
echo "   Location: $IOS_FRAMEWORKS"
echo ""
echo "📱 Device library:    libkagipp_ffi.a"
echo "🖥️  Simulator library: libkagipp_ffi_sim.a"
echo ""
