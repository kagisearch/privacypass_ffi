#!/bin/bash
# Copy macOS dylib to Flutter plugin

set -e

echo "🍎 Copying macOS libraries..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
RUST_DIR="$PLUGIN_DIR/../privacypass-lib/src/target"

# Source paths
DYLIB_SRC="$RUST_DIR/release/libkagipp_ffi.dylib"

# Destination
DYLIB_DEST="$PLUGIN_DIR/macos/Frameworks/libkagipp_ffi.dylib"

# Check if source exists
if [ ! -f "$DYLIB_SRC" ]; then
    echo "❌ Error: dylib not found at $DYLIB_SRC"
    echo "   Run build_macos.sh first"
    exit 1
fi

# Copy dylib
mkdir -p "$(dirname "$DYLIB_DEST")"
cp "$DYLIB_SRC" "$DYLIB_DEST"

echo "✅ Copied libkagipp_ffi.dylib"
echo "   From: $DYLIB_SRC"
echo "   To:   $DYLIB_DEST"

# Fix the install name to use @rpath
echo ""
echo "🔧 Fixing install name to use @rpath..."
install_name_tool -id @rpath/libkagipp_ffi.dylib "$DYLIB_DEST"
echo "✅ Install name fixed"

# Show info
echo ""
echo "📊 Library info:"
file "$DYLIB_DEST"
ls -lh "$DYLIB_DEST"
echo ""
echo "🔍 Install name verification:"
otool -L "$DYLIB_DEST" | head -3

