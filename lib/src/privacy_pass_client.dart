/// High-level Privacy Pass client API
library;

import 'dart:convert';

import 'package:ffi/ffi.dart';

import 'privacypass_ffi_bindings_generated.dart' as bindings;
import 'types.dart';

/// Privacy Pass client for generating and finalizing tokens
///
/// This class provides a high-level Dart API over the generated FFI bindings.
/// All memory management is handled automatically. The native library is
/// resolved via its code asset id — no manual `DynamicLibrary` loading.
///
/// Example:
/// ```dart
/// final client = PrivacyPassClient();
///
/// // Generate token request
/// final request = client.generateTokenRequest(
///   wwwAuthenticateHeader: 'PrivateToken challenge=..., token-key=...',
///   tokenCount: 5,
/// );
///
/// // Send request.tokenRequest to issuer, get response
///
/// // Finalize tokens
/// final tokens = client.finalizeTokens(
///   wwwAuthenticateHeader: 'PrivateToken challenge=..., token-key=...',
///   clientState: request.clientState,
///   tokenResponse: serverResponse,
/// );
/// ```
class PrivacyPassClient {
  /// Generate a Privacy Pass token request
  ///
  /// Parameters:
  /// - [wwwAuthenticateHeader]: The WWW-Authenticate header from the origin server
  ///   Format: "PrivateToken challenge=`<base64>`, token-key=`<base64>`"
  /// - [tokenCount]: Number of tokens to request (typically 1-10)
  ///
  /// Returns: A [TokenRequestResult] containing the client state and token request
  ///
  /// Throws: [PrivacyPassException] if the operation fails
  TokenRequestResult generateTokenRequest({required String wwwAuthenticateHeader, required int tokenCount}) {
    if (tokenCount <= 0 || tokenCount > 65535) {
      throw PrivacyPassException('Token count must be between 1 and 65535');
    }

    // Convert Dart string to C string
    final headerJson = jsonEncode({'header': wwwAuthenticateHeader, 'error': ''});
    final headerPtr = headerJson.toNativeUtf8();

    try {
      // Call Rust function
      final resultPtr = bindings.privacy_pass_token_request(headerPtr.cast(), tokenCount);

      if (resultPtr.address == 0) {
        throw PrivacyPassException('Native function returned null');
      }

      try {
        // Convert result back to Dart
        final resultJson = resultPtr.cast<Utf8>().toDartString();

        // Parse JSON response
        final result = jsonDecode(resultJson);

        // Response is an object: {clientState, tokenRequest}
        if (result is! Map<String, dynamic> || result.length != 2) {
          throw PrivacyPassException('Invalid response format: expected object of 2 elements');
        }

        final clientStateObj = result['client_state'] as Map<String, dynamic>;
        final tokenRequestObj = result['token_request'] as Map<String, dynamic>;

        // Check for errors
        final clientStateError = clientStateObj['error']?.toString() ?? '';
        if (clientStateError.isNotEmpty) {
          throw PrivacyPassException(clientStateError);
        }

        final tokenRequestError = tokenRequestObj['error']?.toString() ?? '';
        if (tokenRequestError.isNotEmpty) {
          throw PrivacyPassException(tokenRequestError);
        }

        return TokenRequestResult(
          clientState: clientStateObj['state'] as String,
          tokenRequest: tokenRequestObj['token_request'] as String,
        );
      } finally {
        // Always free the Rust-allocated string
        bindings.privacy_pass_free_string(resultPtr);
      }
    } finally {
      // Free Dart-allocated UTF-8 string
      malloc.free(headerPtr);
    }
  }

  /// Finalize Privacy Pass tokens from server response
  ///
  /// Parameters:
  /// - [wwwAuthenticateHeader]: The original WWW-Authenticate header
  /// - [clientState]: The client state from [generateTokenRequest]
  /// - [tokenResponse]: Base64-encoded token response from the issuer
  ///
  /// Returns: List of base64-encoded finalized tokens
  ///
  /// Throws: [PrivacyPassException] if the operation fails
  List<String> finalizeTokens({
    required String wwwAuthenticateHeader,
    required String clientState,
    required String tokenResponse,
  }) {
    // Convert inputs to JSON format expected by FFI
    final headerJson = jsonEncode({'header': wwwAuthenticateHeader, 'error': ''});

    final stateJson = jsonEncode({'state': clientState, 'error': ''});

    final responseJson = jsonEncode({'token_response': tokenResponse, 'error': ''});

    // Convert to C strings
    final headerPtr = headerJson.toNativeUtf8();
    final statePtr = stateJson.toNativeUtf8();
    final responsePtr = responseJson.toNativeUtf8();

    try {
      // Call Rust function
      final resultPtr = bindings.privacy_pass_token_finalization(
        headerPtr.cast(),
        statePtr.cast(),
        responsePtr.cast(),
      );

      if (resultPtr.address == 0) {
        throw PrivacyPassException('Native function returned null');
      }

      try {
        // Convert result back to Dart
        final resultJson = resultPtr.cast<Utf8>().toDartString();

        // Parse JSON response
        final result = jsonDecode(resultJson) as Map<String, dynamic>;

        // Check for errors
        final error = result['error']?.toString() ?? '';
        if (error.isNotEmpty) {
          throw PrivacyPassException(error);
        }

        // Extract tokens
        final tokens = result['tokens'];
        if (tokens is! List) {
          throw PrivacyPassException('Invalid response: tokens must be an array');
        }

        return tokens.cast<String>();
      } finally {
        // Always free the Rust-allocated string
        bindings.privacy_pass_free_string(resultPtr);
      }
    } finally {
      // Free all Dart-allocated UTF-8 strings
      malloc.free(headerPtr);
      malloc.free(statePtr);
      malloc.free(responsePtr);
    }
  }

  /// The version of the native Privacy Pass library (e.g. "0.1.0")
  String get nativeLibraryVersion {
    final ptr = bindings.privacy_pass_version();
    if (ptr.address == 0) {
      throw PrivacyPassException('Native function returned null');
    }
    try {
      return ptr.cast<Utf8>().toDartString();
    } finally {
      bindings.privacy_pass_free_string(ptr);
    }
  }
}
