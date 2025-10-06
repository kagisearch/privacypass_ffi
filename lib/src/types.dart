/// Type definitions for Privacy Pass FFI
library;

/// Result from token request generation
class TokenRequestResult {
  /// Client state that must be preserved for token finalization
  final String clientState;

  /// Base64-encoded token request to send to the issuer
  final String tokenRequest;

  TokenRequestResult({required this.clientState, required this.tokenRequest});

  @override
  String toString() => 'TokenRequestResult(tokenRequest: ${tokenRequest.substring(0, 20)}...)';
}

/// Exception thrown when Privacy Pass operations fail
class PrivacyPassException implements Exception {
  final String message;

  PrivacyPassException(this.message);

  @override
  String toString() => 'PrivacyPassException: $message';
}
