/// Privacy Pass protocol implementation via Rust FFI
///
/// This package provides a Dart interface to the Privacy Pass protocol
/// implementation written in Rust, using FFI for native performance.
///
/// ## Features
///
/// - Generate Privacy Pass token requests
/// - Finalize tokens from issuer responses
/// - Background processing via Isolate.spawn (no external dependencies)
/// - Memory-safe FFI bindings
/// - Support for Android, iOS, and macOS
///
/// ## Usage
///
/// ### Basic Usage (Synchronous)
///
/// ```dart
/// import 'package:privacypass_ffi/privacypass_ffi.dart';
///
/// final client = PrivacyPassClient();
///
/// // Generate token request
/// final request = client.generateTokenRequest(
///   wwwAuthenticateHeader: 'PrivateToken challenge=..., token-key=...',
///   tokenCount: 5,
/// );
///
/// // Send request.tokenRequest to issuer, receive response
///
/// // Finalize tokens
/// final tokens = client.finalizeTokens(
///   wwwAuthenticateHeader: 'PrivateToken challenge=..., token-key=...',
///   clientState: request.clientState,
///   tokenResponse: issuerResponse,
/// );
/// ```
///
/// ### Background Processing (Recommended)
///
/// ```dart
/// import 'package:privacypass_ffi/privacypass_ffi.dart';
///
/// final client = PrivacyPassIsolate();
///
/// // Operations run in background isolates
/// final request = await client.generateTokenRequest(
///   wwwAuthenticateHeader: header,
///   tokenCount: 5,
/// );
///
/// final tokens = await client.finalizeTokens(
///   wwwAuthenticateHeader: header,
///   clientState: request.clientState,
///   tokenResponse: response,
/// );
/// ```
library;

export 'src/privacy_pass_client.dart';
export 'src/privacy_pass_isolate.dart';
export 'src/types.dart';
