/// Isolate-based Privacy Pass client for background processing
library;

import 'dart:isolate';

import 'privacy_pass_client.dart';
import 'types.dart';

/// Privacy Pass client that runs crypto operations in background isolates
///
/// This prevents UI blocking during expensive cryptographic operations.
/// Each call runs in a short-lived isolate via [Isolate.run]; the native
/// library is resolved by its code asset id, so it is available in every
/// isolate without manual loading.
///
/// Example:
/// ```dart
/// final client = PrivacyPassIsolate();
///
/// // Operations run in background isolates
/// final request = await client.generateTokenRequest(...);
/// final tokens = await client.finalizeTokens(...);
/// ```
class PrivacyPassIsolate {
  /// Generate a Privacy Pass token request (in background isolate)
  ///
  /// This operation runs in a background isolate to avoid blocking the UI.
  ///
  /// Parameters:
  /// - [wwwAuthenticateHeader]: The WWW-Authenticate header from the origin
  /// - [tokenCount]: Number of tokens to request
  ///
  /// Returns: A [TokenRequestResult] with client state and token request
  ///
  /// Throws:
  /// - [PrivacyPassException] if the operation fails
  Future<TokenRequestResult> generateTokenRequest({
    required String wwwAuthenticateHeader,
    required int tokenCount,
  }) {
    return _run(
      () => PrivacyPassClient().generateTokenRequest(
        wwwAuthenticateHeader: wwwAuthenticateHeader,
        tokenCount: tokenCount,
      ),
    );
  }

  /// Finalize Privacy Pass tokens (in background isolate)
  ///
  /// This operation runs in a background isolate to avoid blocking the UI.
  ///
  /// Parameters:
  /// - [wwwAuthenticateHeader]: The original WWW-Authenticate header
  /// - [clientState]: Client state from [generateTokenRequest]
  /// - [tokenResponse]: Token response from the issuer
  ///
  /// Returns: List of base64-encoded finalized tokens
  ///
  /// Throws:
  /// - [PrivacyPassException] if the operation fails
  Future<List<String>> finalizeTokens({
    required String wwwAuthenticateHeader,
    required String clientState,
    required String tokenResponse,
  }) {
    return _run(
      () => PrivacyPassClient().finalizeTokens(
        wwwAuthenticateHeader: wwwAuthenticateHeader,
        clientState: clientState,
        tokenResponse: tokenResponse,
      ),
    );
  }

  /// Run [computation] in a background isolate, rethrowing failures as
  /// [PrivacyPassException] (exceptions do not cross isolate boundaries
  /// as their original type).
  Future<T> _run<T>(T Function() computation) async {
    try {
      return await Isolate.run(computation);
    } on PrivacyPassException {
      rethrow;
    } catch (e) {
      throw PrivacyPassException(e.toString());
    }
  }
}
