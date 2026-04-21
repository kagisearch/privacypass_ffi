# Privacy Pass FFI

Privacy Pass protocol implementation for Flutter using Rust FFI. Provides native performance for cryptographic
operations.

## Features

- ✅ **Native Performance**: Rust-powered cryptography via FFI
- ✅ **Background Processing**: Operations run in isolates (via Isolate.spawn) to prevent UI blocking
- ✅ **Memory Safe**: Automatic memory management with proper FFI bindings
- ✅ **Cross-Platform**: Supports Android (arm64-v8a, armeabi-v7a, x86_64), iOS (arm64 + simulators), and macOS
- ✅ **Easy to Use**: Simple Dart API with comprehensive documentation

## What is Privacy Pass?

Privacy Pass is a protocol that allows users to prove they're trustworthy without revealing their identity. It uses
cryptographic tokens to provide anonymous authentication, implementing:

- **VOPRF** (Verifiable Oblivious Pseudorandom Function) using Ristretto255 curve
- **RFC 9578** Privacy Pass Issuance Protocol
- **Batched token** issuance for efficiency

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  privacypass_ffi:
    path: ../privacypass_ffi  # Update with your path
```

Then run:

```bash
flutter pub get
```

## Building Native Libraries

**Prerequisites:**

1. **Rust toolchain** (via [rustup](https://rustup.rs/))
2. **Android NDK** (via Android Studio SDK Manager)
3. **Xcode** (for iOS, macOS only)
4. **Build tools**:
   ```bash
   cargo install cargo-ndk cargo-lipo cbindgen
   ```

**Build for all platforms:**

Build the Rust FFI library from the `rust/` directory, then copy the compiled libraries to the plugin:

```bash
# Copy libraries after building
bash scripts/copy_android_libs.sh
bash scripts/copy_ios_libs.sh
bash scripts/copy_macos_libs.sh
```

## Usage

### Option 1: Background Processing (Recommended)

Use `PrivacyPassIsolate` to run crypto operations in background isolates:

```dart
import 'package:privacypass_ffi/privacypass_ffi.dart';

final client = PrivacyPassIsolate();

try {
  // Step 1: Get challenge from origin server
  final response = await http.get(Uri.parse('https://origin.com/protected'));
  final wwwAuthHeader = response.headers['www-authenticate']!;

  // Step 2: Generate token request
  final request = await client.generateTokenRequest(
    wwwAuthenticateHeader: wwwAuthHeader,
    tokenCount: 5,
  );

  // Step 3: Send to issuer
  final issuerResponse = await http.post(
    Uri.parse('https://issuer.com/token'),
    body: request.tokenRequest,
  );

  // Step 4: Finalize tokens
  final tokens = await client.finalizeTokens(
    wwwAuthenticateHeader: wwwAuthHeader,
    clientState: request.clientState,
    tokenResponse: issuerResponse.body,
  );

  // Step 5: Use tokens
  final protectedResponse = await http.get(
    Uri.parse('https://origin.com/protected'),
    headers: {'Authorization': 'PrivateToken token=${tokens.first}'},
  );

  print('Success: ${protectedResponse.body}');
} catch (e) {
  print('Error: $e');
}
```

### Option 2: Synchronous (For Simple Cases)

Use `PrivacyPassClient` for synchronous operations:

```dart
import 'package:privacypass_ffi/privacypass_ffi.dart';

final client = PrivacyPassClient();

// Generate token request (blocks current isolate)
final request = client.generateTokenRequest(
  wwwAuthenticateHeader: header,
  tokenCount: 5,
);

// Finalize tokens
final tokens = client.finalizeTokens(
  wwwAuthenticateHeader: header,
  clientState: request.clientState,
  tokenResponse: serverResponse,
);
```

## API Reference

### `PrivacyPassIsolate`

Background processing client using Dart's built-in `Isolate.spawn`.

#### Methods

**`Future<TokenRequestResult> generateTokenRequest({required String wwwAuthenticateHeader, required int tokenCount})`**

- Generate a Privacy Pass token request in a background isolate
- Returns: `TokenRequestResult` with `clientState` and `tokenRequest`

**`Future<List<String>> finalizeTokens({required String wwwAuthenticateHeader, required String clientState, required String tokenResponse})`**

- Finalize tokens from issuer response in a background isolate
- Returns: List of base64-encoded tokens

### `PrivacyPassClient`

Synchronous client (operations block current isolate).

#### Methods

**`TokenRequestResult generateTokenRequest({required String wwwAuthenticateHeader, required int tokenCount})`**

- Synchronous token request generation

**`List<String> finalizeTokens({required String wwwAuthenticateHeader, required String clientState, required String tokenResponse})`**

- Synchronous token finalization

### Types

**`TokenRequestResult`**

```dart
class TokenRequestResult {
  final String clientState; // Preserve for finalization
  final String tokenRequest; // Send to issuer
}
```

**`PrivacyPassException`**

- Exception thrown when operations fail

## Development

### Project Structure

```
privacypass_ffi/
├── lib/
│   ├── src/
│   │   ├── bindings.dart              # FFI bindings
│   │   ├── privacy_pass_client.dart   # Synchronous API
│   │   ├── privacy_pass_isolate.dart  # Async isolate API
│   │   └── types.dart                 # Dart types
│   └── privacypass_ffi.dart           # Main export
├── android/
│   └── src/main/jniLibs/              # Native .so files
├── ios/
│   └── Frameworks/                    # Native .a files
├── macos/
│   └── Frameworks/                    # Native .dylib files
├── rust/                              # Rust FFI source & build
├── scripts/
│   ├── copy_android_libs.sh
│   ├── copy_ios_libs.sh
│   └── copy_macos_libs.sh
├── test/                              # Unit tests
└── example/                           # Demo app
```

### Running the Example

```bash
cd privacypass_ffi/example
flutter run
```

### Testing

Run unit tests:

```bash
cd privacypass_ffi
flutter test
```

### Debugging

**Enable Rust debug symbols:**

In the Rust FFI crate's `Cargo.toml`:

```toml
[profile.release]
debug = true
```

**Check library loading:**

```dart
try {
final client = PrivacyPassClient();
print('Library loaded successfully');
} catch (e) {
print('Failed to load library: $e');
}
```

## Architecture

```
┌─────────────────────────────────┐
│   Flutter/Dart Application      │
└───────────┬─────────────────────┘
            │ dart:ffi
            ↓
┌─────────────────────────────────┐
│   FFI Bridge (Dart)             │
│   - String marshalling          │
│   - Memory management           │
└───────────┬─────────────────────┘
            │ C ABI
            ↓
┌─────────────────────────────────┐
│   Rust FFI Wrapper              │
│   - privacy_pass_token_request      │
│   - privacy_pass_token_finalization │
│   - privacy_pass_free_string        │
└───────────┬─────────────────────┘
            │
            ↓
┌─────────────────────────────────┐
│   Core Crypto Library (Rust)    │
│   - VOPRF / Ristretto255        │
│   - Privacy Pass Protocol       │
└─────────────────────────────────┘
```

## Performance

Crypto operations are CPU-intensive. Benchmarks on iPhone 14 Pro:

- **Token Request** (5 tokens): ~15ms
- **Token Finalization** (5 tokens): ~20ms

Using `PrivacyPassIsolate` prevents UI jank during these operations.

## Security Considerations

1. **Memory Safety**: All FFI calls properly manage memory to prevent leaks
2. **String Lifetime**: Input strings are copied; output strings are owned by Rust
3. **Error Handling**: All errors propagate as `PrivacyPassException`
4. **Thread Safety**: Each isolate has its own client instance (no shared state)

## Troubleshooting

### Android

**Issue**: `java.lang.UnsatisfiedLinkError: dlopen failed: library "libkagipp_ffi.so" not found`

**Solution**: Rebuild native libraries and copy them to `jniLibs`:

```bash
bash scripts/copy_android_libs.sh
```

### iOS

**Issue**: `Symbol not found: _privacy_pass_token_request`

**Solution**: Clean and rebuild:

```bash
cd privacypass_ffi/example/ios
rm -rf Pods Podfile.lock
flutter clean
flutter pub get
cd ios && pod install
```

### Build Failures

**Issue**: Rust targets not installed

**Solution**:

```bash
rustup target add aarch64-linux-android armv7-linux-androideabi \
                  x86_64-linux-android aarch64-apple-ios \
                  aarch64-apple-ios-sim x86_64-apple-ios
```

## License

See [LICENSE](LICENSE) file.

## Contributing

This is a Kagi internal project. For issues or questions, contact the Privacy Pass team.

## References

- [Privacy Pass RFC 9578](https://www.rfc-editor.org/rfc/rfc9578.html)
- [VOPRF RFC 9497](https://www.rfc-editor.org/rfc/rfc9497.html)
- [Ristretto255](https://ristretto.group/)
- [Kagi Privacy Pass](https://blog.kagi.com/kagi-privacy-pass)
