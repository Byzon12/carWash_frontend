import 'package:flutter/material.dart';
import '../api/api_connect.dart';
import '../services/connection_service.dart';

class LoginDebugScreen extends StatefulWidget {
  const LoginDebugScreen({super.key});

  @override
  State<LoginDebugScreen> createState() => _LoginDebugScreenState();
}

class _LoginDebugScreenState extends State<LoginDebugScreen> {
  final TextEditingController _usernameController = TextEditingController(
    text: 'test',
  ); // Default for testing
  final TextEditingController _passwordController = TextEditingController(
    text: 'test123',
  ); // Default for testing

  bool _isLoading = false;
  Map<String, dynamic>? _networkStatus;
  Map<String, dynamic>? _loginTestResult;
  String _debugLog = '';

  @override
  void initState() {
    super.initState();
    _runNetworkDiagnostics();
  }

  void _addToLog(String message) {
    setState(() {
      _debugLog += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
    print('[DEBUG_SCREEN] $message');
  }

  Future<void> _runNetworkDiagnostics() async {
    setState(() {
      _isLoading = true;
      _debugLog = '';
    });

    _addToLog('Starting network diagnostics...');

    try {
      // Test network connectivity
      _addToLog('Testing backend connectivity...');
      final networkStatus = await ConnectionService.getNetworkStatus();

      setState(() {
        _networkStatus = networkStatus;
      });

      _addToLog('Network test completed');

      if (networkStatus['isConnected']) {
        _addToLog('✅ Backend is accessible at: ${networkStatus['backendUrl']}');
      } else {
        _addToLog('❌ Backend is not accessible');
      }
    } catch (e) {
      _addToLog('❌ Network diagnostics failed: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _addToLog('❌ Username and password are required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _addToLog('Starting login test...');

    try {
      // Test using our connection service
      final testResult = await ConnectionService.testLogin(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      setState(() {
        _loginTestResult = testResult;
      });

      // Log all steps
      for (String step in testResult['steps']) {
        _addToLog(step);
      }

      if (testResult['success']) {
        _addToLog('✅ Connection Service Login Test: SUCCESS');

        // Also test with the regular API
        _addToLog('Testing with regular ApiConnect...');
        final apiResponse = await ApiConnect.login(
          username: _usernameController.text,
          password: _passwordController.text,
        );

        _addToLog('ApiConnect response status: ${apiResponse.statusCode}');
        _addToLog('ApiConnect response body: ${apiResponse.body}');

        if (apiResponse.statusCode == 200 || apiResponse.statusCode == 201) {
          _addToLog('✅ ApiConnect Login Test: SUCCESS');
        } else {
          _addToLog('❌ ApiConnect Login Test: FAILED');
        }
      } else {
        _addToLog('❌ Connection Service Login Test: FAILED');
        _addToLog('Error: ${testResult['error']}');
      }
    } catch (e) {
      _addToLog('❌ Login test exception: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testStoredData() async {
    _addToLog('Checking stored data...');

    try {
      final accessToken = await ApiConnect.getAccessToken();
      _addToLog('Stored access token: ${accessToken ?? 'NONE'}');

      final isLoggedIn = await ApiConnect.isLoggedIn();
      _addToLog('Is logged in: $isLoggedIn');

      final username = await ApiConnect.storage.read(key: 'username');
      _addToLog('Stored username: ${username ?? 'NONE'}');
    } catch (e) {
      _addToLog('❌ Error checking stored data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Debug Tool'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login Debug Tool',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool helps diagnose login connectivity issues between the frontend and backend.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Network Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Network Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _runNetworkDiagnostics,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_networkStatus != null) ...[
                      _buildStatusRow(
                        'Backend Connected:',
                        _networkStatus!['isConnected'] ? 'YES' : 'NO',
                        _networkStatus!['isConnected'],
                      ),
                      if (_networkStatus!['backendUrl'] != null)
                        _buildStatusRow(
                          'Working URL:',
                          _networkStatus!['backendUrl'],
                          true,
                        ),
                      _buildStatusRow(
                        'Platform:',
                        _networkStatus!['platform'],
                        true,
                      ),
                    ] else if (_isLoading) ...[
                      const CircularProgressIndicator(),
                    ] else ...[
                      const Text('Click Refresh to test network connectivity'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Login Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Test Login'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testStoredData,
                          child: const Text('Check Stored Data'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Debug Log
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Debug Log',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _debugLog = '';
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 300,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _debugLog.isEmpty
                              ? 'No debug information yet...'
                              : _debugLog,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await ApiConnect.logout();
                            _addToLog('✅ Logged out and cleared stored data');
                          },
                          child: const Text('Clear Storage'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text('Go to Login'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/dashboard',
                            );
                          },
                          child: const Text('Go to Dashboard'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
