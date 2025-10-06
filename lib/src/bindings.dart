/// FFI bindings for Privacy Pass native library
library;

import 'dart:ffi' as ffi;
import 'dart:io';

/// Native library bindings
class PrivacyPassBindings {
  late final ffi.DynamicLibrary _lib;

  PrivacyPassBindings() {
    _lib = _loadLibrary();
  }

  /// Load the native library
  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('libkagipp_ffi.so');
    } else if (Platform.isIOS) {
      // On iOS, use process() for statically linked libraries
      return ffi.DynamicLibrary.process();
    } else if (Platform.isMacOS) {
      // For testing on macOS, try multiple paths
      const paths = [
        'macos/Frameworks/libkagipp_ffi.dylib',
        'libkagipp_ffi.dylib',
      ];
      for (final path in paths) {
        try {
          return ffi.DynamicLibrary.open(path);
        } catch (_) {
          continue;
        }
      }
      throw UnsupportedError('Could not find libkagipp_ffi.dylib in any expected location');
    } else {
      throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
    }
  }

  /// Function: privacy_pass_token_request
  ///
  /// Generates a Privacy Pass token request from a WWW-Authenticate header
  ///
  /// Parameters:
  /// - www_authenticate_header: JSON string with header
  /// - token_count: Number of tokens to request
  ///
  /// Returns: Pointer to JSON string (must be freed with privacyPassFreeString)
  late final _tokenRequest = _lib
      .lookupFunction<
        ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>, ffi.Uint16),
        ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>, int)
      >('privacy_pass_token_request');

  ffi.Pointer<ffi.Char> privacyPassTokenRequest(ffi.Pointer<ffi.Char> header, int count) {
    return _tokenRequest(header, count);
  }

  /// Function: privacy_pass_token_finalization
  ///
  /// Finalizes Privacy Pass tokens from server response
  ///
  /// Parameters:
  /// - www_authenticate_header: JSON string with original header
  /// - client_state: JSON string with client state from token_request
  /// - token_response: JSON string with server's token response
  ///
  /// Returns: Pointer to JSON string with finalized tokens (must be freed)
  late final _tokenFinalization = _lib
      .lookupFunction<
        ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>),
        ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)
      >('privacy_pass_token_finalization');

  ffi.Pointer<ffi.Char> privacyPassTokenFinalization(
    ffi.Pointer<ffi.Char> header,
    ffi.Pointer<ffi.Char> state,
    ffi.Pointer<ffi.Char> response,
  ) {
    return _tokenFinalization(header, state, response);
  }

  /// Function: privacy_pass_free_string
  ///
  /// Frees a string allocated by the Rust library
  ///
  /// CRITICAL: Must be called on every pointer returned by other functions
  late final _freeString = _lib
      .lookupFunction<ffi.Void Function(ffi.Pointer<ffi.Char>), void Function(ffi.Pointer<ffi.Char>)>(
        'privacy_pass_free_string',
      );

  void privacyPassFreeString(ffi.Pointer<ffi.Char> ptr) {
    if (ptr.address != 0) {
      _freeString(ptr);
    }
  }

  /// Function: privacy_pass_version
  ///
  /// Returns the library version string (does not need to be freed)
  late final _version = _lib.lookupFunction<ffi.Pointer<ffi.Char> Function(), ffi.Pointer<ffi.Char> Function()>(
    'privacy_pass_version',
  );

  ffi.Pointer<ffi.Char> privacyPassVersion() {
    return _version();
  }
}
