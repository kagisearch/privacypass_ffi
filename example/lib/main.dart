import 'package:flutter/material.dart';
import 'package:privacypass_ffi/privacypass_ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _client = PrivacyPassClient();
  final _asyncClient = PrivacyPassIsolate();
  bool _initialized = false;
  String _status = 'Initializing...';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    try {
      setState(() {
        _initialized = true;
        _status = 'Ready';
      });
      _addLog('✅ Initialized Privacy Pass FFI');
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      _addLog('❌ Initialization failed: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 20) _logs.removeLast();
    });
  }

  void _testTokenFlow() {
    if (!_initialized) return;

    setState(() => _status = 'Testing Privacy Pass flow...');
    _addLog('🔄 Starting Privacy Pass flow test...');

    try {
      // Sample WWW-Authenticate header
      const header =
          'PrivateToken challenge=-RoAHHByaXZhY3ktcGFzcy1pc3N1ZXIua2FnaS5jb20AABxwcml2YWN5LXBhc3Mtb3JpZ2luLmthZ2kuY29t, token-key=MM3WWx7w6TuQXCHqGc9yaTz3CCDW3QXTTYmwqLOypBI=';

      _addLog('📝 Generating token request (5 tokens)...');

      // Step 1: Generate token request
      final request = _client.generateTokenRequest(wwwAuthenticateHeader: header, tokenCount: 5);

      _addLog('✅ Token request generated');
      _addLog('   Request: ${request.tokenRequest}...');
      _addLog('   State: ${request.clientState}...');

      setState(() => _status = 'Token request generated!');

      // In a real app, you would:
      // 1. Send request.tokenRequest to the issuer server
      // 2. Receive a token response
      // 3. Call finalizeTokens with the response

      // For demonstration, we'll show what the next step would be:
      _addLog('');
      _addLog('ℹ️  Next steps in production:');
      _addLog('   1. POST token request to issuer');
      _addLog('   2. Receive token response');
      _addLog('   3. Call finalizeTokens()');
      _addLog('   4. Use tokens to access protected resources');

      // Example of how to use the response (commented out):
      /*
      const serverResponse = '...base64 token response from issuer...';

      _addLog('🔐 Finalizing tokens...');

      final tokens = _client.finalizeTokens(
        wwwAuthenticateHeader: header,
        clientState: request.clientState,
        tokenResponse: serverResponse,
      );

      _addLog('✅ Finalized ${tokens.length} tokens');
      for (int i = 0; i < tokens.length; i++) {
        _addLog('   Token $i: ${tokens[i].substring(0, 40)}...');
      }
      */

      setState(() => _status = 'Test completed successfully');
      _addLog('✅ Privacy Pass flow test completed');
    } catch (e) {
      setState(() => _status = 'Error: $e');
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _testAsyncTokenFlow() async {
    if (!_initialized) return;

    setState(() => _status = 'Testing async Privacy Pass flow...');
    _addLog('🔄 Starting async Privacy Pass flow test...');

    try {
      // Sample WWW-Authenticate header
      const header =
          'PrivateToken challenge=-RoAHHByaXZhY3ktcGFzcy1pc3N1ZXIua2FnaS5jb20AABxwcml2YWN5LXBhc3Mtb3JpZ2luLmthZ2kuY29t, token-key=MM3WWx7w6TuQXCHqGc9yaTz3CCDW3QXTTYmwqLOypBI=';

      _addLog('📝 Generating token request (5 tokens) in isolate...');

      // Step 1: Generate token request
      final request = await _asyncClient.generateTokenRequest(
        wwwAuthenticateHeader: header,
        tokenCount: 5,
      );

      _addLog('✅ Token request generated in isolate');
      _addLog('   Request: ${request.tokenRequest}...');
      _addLog('   State: ${request.clientState}...');

      setState(() => _status = 'Async token request generated!');

      _addLog('');
      _addLog('ℹ️  Next steps in production:');
      _addLog('   1. POST token request to issuer');
      _addLog('   2. Receive token response');
      _addLog('   3. Call finalizeTokens()');
      _addLog('   4. Use tokens to access protected resources');

      setState(() => _status = 'Async test completed successfully');
      _addLog('✅ Async Privacy Pass flow test completed');
    } catch (e) {
      setState(() => _status = 'Error: $e');
      _addLog('❌ Async error: $e');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Privacy Pass FFI Example',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Privacy Pass FFI Example'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Status card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _initialized ? Icons.check_circle : Icons.pending,
                            color: _initialized ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text('Status: $_status', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _initialized ? _testTokenFlow : null,
                        icon: const Icon(Icons.security),
                        label: const Text('Test Privacy Pass Flow (Sync)'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _initialized ? _testAsyncTokenFlow : null,
                        icon: const Icon(Icons.sync),
                        label: const Text('Test Privacy Pass Flow (Async)'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logs.isNotEmpty ? _clearLogs : null,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear Logs'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Logs section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),

              // Logs list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _logs.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16), child: Text('No logs yet. Run a test to see logs.'))
                    : Column(
                        children: _logs
                            .map(
                              (log) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(log, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
