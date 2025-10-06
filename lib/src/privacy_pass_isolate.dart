/// Isolate-based Privacy Pass client for background processing
library;

import 'dart:async';
import 'dart:isolate';

import 'privacy_pass_client.dart';
import 'types.dart';

/// Privacy Pass client that runs crypto operations in background isolates
///
/// This prevents UI blocking during expensive cryptographic operations.
/// Uses Dart's built-in Isolate.spawn for background processing.
///
/// Example:
/// ```dart
/// final client = PrivacyPassIsolate();
///
/// // Operations run in background isolates
/// final request = await client.generateTokenRequest(...);
/// final tokens = await client.finalizeTokens(...);
///
/// await client.dispose();
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
  }) async {
    final request = _IsolateRequest(
      action: _IsolateAction.generateTokenRequest,
      wwwAuthenticateHeader: wwwAuthenticateHeader,
      tokenCount: tokenCount,
    );

    final result = await _runInIsolate(request);

    if (result is Map<String, dynamic>) {
      return TokenRequestResult(
        clientState: result['clientState'] as String,
        tokenRequest: result['tokenRequest'] as String,
      );
    } else {
      throw PrivacyPassException('Invalid response type from isolate');
    }
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
  }) async {
    final request = _IsolateRequest(
      action: _IsolateAction.finalizeTokens,
      wwwAuthenticateHeader: wwwAuthenticateHeader,
      clientState: clientState,
      tokenResponse: tokenResponse,
    );

    final result = await _runInIsolate(request);

    if (result is List) {
      return result.cast<String>();
    } else {
      throw PrivacyPassException('Invalid response type from isolate');
    }
  }

  /// Get the library version
  ///
  /// This is a lightweight operation that doesn't need to run in an isolate
  String getVersion() {
    return PrivacyPassClient().getVersion();
  }

  /// Run a request in a new isolate
  Future<dynamic> _runInIsolate(_IsolateRequest request) async {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();

    try {
      // Spawn isolate with our worker function
      await Isolate.spawn(
        _isolateWorker,
        _IsolateMessage(request: request, sendPort: receivePort.sendPort),
        onError: errorPort.sendPort,
        errorsAreFatal: true,
      );

      // Wait for either result or error
      final completer = Completer<dynamic>();

      late StreamSubscription resultSubscription;
      late StreamSubscription errorSubscription;

      resultSubscription = receivePort.listen((message) {
        if (!completer.isCompleted) {
          if (message is _IsolateResponse) {
            if (message.error != null) {
              completer.completeError(PrivacyPassException(message.error!));
            } else {
              completer.complete(message.result);
            }
          } else {
            completer.completeError(PrivacyPassException('Invalid message type from isolate'));
          }
        }
        resultSubscription.cancel();
        errorSubscription.cancel();
      });

      errorSubscription = errorPort.listen((errorList) {
        if (!completer.isCompleted) {
          final error = errorList[0];
          final stackTrace = errorList[1] as String?;
          completer.completeError(
            PrivacyPassException('Isolate error: $error'),
            stackTrace != null ? StackTrace.fromString(stackTrace) : null,
          );
        }
        resultSubscription.cancel();
        errorSubscription.cancel();
      });

      return await completer.future;
    } finally {
      receivePort.close();
      errorPort.close();
    }
  }
}

/// Action types for isolate operations
enum _IsolateAction { generateTokenRequest, finalizeTokens }

/// Request message sent to isolate
class _IsolateRequest {
  final _IsolateAction action;
  final String wwwAuthenticateHeader;
  final int? tokenCount;
  final String? clientState;
  final String? tokenResponse;

  _IsolateRequest({
    required this.action,
    required this.wwwAuthenticateHeader,
    this.tokenCount,
    this.clientState,
    this.tokenResponse,
  });
}

/// Message container for isolate communication
class _IsolateMessage {
  final _IsolateRequest request;
  final SendPort sendPort;

  _IsolateMessage({required this.request, required this.sendPort});
}

/// Response from isolate
class _IsolateResponse {
  final dynamic result;
  final String? error;

  _IsolateResponse({this.result, this.error});
}

/// Worker function that runs in the spawned isolate
///
/// This function is the entry point for each background isolate.
/// It receives requests, processes them using PrivacyPassClient,
/// and sends results back to the main isolate.
void _isolateWorker(_IsolateMessage message) {
  try {
    // Create a client instance for this isolate
    final client = PrivacyPassClient();

    final request = message.request;
    dynamic result;

    switch (request.action) {
      case _IsolateAction.generateTokenRequest:
        final tokenRequest = client.generateTokenRequest(
          wwwAuthenticateHeader: request.wwwAuthenticateHeader,
          tokenCount: request.tokenCount!,
        );

        result = {'clientState': tokenRequest.clientState, 'tokenRequest': tokenRequest.tokenRequest};
        break;

      case _IsolateAction.finalizeTokens:
        final tokens = client.finalizeTokens(
          wwwAuthenticateHeader: request.wwwAuthenticateHeader,
          clientState: request.clientState!,
          tokenResponse: request.tokenResponse!,
        );

        result = tokens;
        break;
    }

    // Send successful result back
    message.sendPort.send(_IsolateResponse(result: result));
  } catch (e) {
    // Send error back
    message.sendPort.send(_IsolateResponse(error: e.toString()));
  }
}
