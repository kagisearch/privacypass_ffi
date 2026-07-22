import 'package:privacypass_ffi/privacypass_ffi.dart';
import 'package:test/test.dart';

void main() {
  group('PrivacyPassClient', () {
    test('can be instantiated', () {
      expect(() => PrivacyPassClient(), returnsNormally);
    });

    test('generateTokenRequest throws on invalid input', () {
      final client = PrivacyPassClient();

      // Invalid token count
      expect(
        () => client.generateTokenRequest(wwwAuthenticateHeader: 'test', tokenCount: 0),
        throwsA(isA<PrivacyPassException>()),
      );
    });

    test('nativeLibraryVersion returns a version string', () {
      final client = PrivacyPassClient();
      expect(client.nativeLibraryVersion, matches(RegExp(r'^\d+\.\d+\.\d+')));
    });

    test('generateTokenRequest throws on invalid header', () {
      final client = PrivacyPassClient();

      // Invalid header format
      expect(
        () => client.generateTokenRequest(wwwAuthenticateHeader: 'invalid', tokenCount: 5),
        throwsA(isA<PrivacyPassException>()),
      );
    });
  });

  group('PrivacyPassIsolate', () {
    test('can be instantiated', () {
      expect(() => PrivacyPassIsolate(), returnsNormally);
    });

    test('generateTokenRequest works in isolate', () async {
      final client = PrivacyPassIsolate();
      // This will fail with invalid input, but it tests the isolate mechanism
      expect(
        client.generateTokenRequest(wwwAuthenticateHeader: 'invalid', tokenCount: 5),
        throwsA(isA<PrivacyPassException>()),
      );
    });
  });

  group('TokenRequestResult', () {
    test('can be created', () {
      final result = TokenRequestResult(clientState: 'state', tokenRequest: 'request');

      expect(result.clientState, equals('state'));
      expect(result.tokenRequest, equals('request'));
    });

    test('toString includes truncated request', () {
      final result = TokenRequestResult(clientState: 'x' * 100, tokenRequest: 'y' * 100);

      final str = result.toString();
      expect(str, contains('TokenRequestResult'));
      expect(str, contains('yyyyyyyyyyyyyyyyyyyy'));
    });
  });

  group('PrivacyPassException', () {
    test('can be created with message', () {
      final exception = PrivacyPassException('test error');
      expect(exception.message, equals('test error'));
    });

    test('toString includes message', () {
      final exception = PrivacyPassException('test error');
      expect(exception.toString(), contains('test error'));
      expect(exception.toString(), contains('PrivacyPassException'));
    });
  });
}
