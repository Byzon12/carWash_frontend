import 'package:flutter/material.dart';
import '../api/api_connect.dart';
import '../api/api_test.dart';
import 'dart:convert';

class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({super.key});

  @override
  State<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _testResults = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _logResult(String message) {
    setState(() {
      _testResults += '$message\n';
    });
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    _logResult('🔍 Starting Backend Connection Diagnostics...\n');

    try {
      await ApiTest.runDiagnostics();
      _logResult('✅ Diagnostics completed successfully');
    } catch (e) {
      _logResult('❌ Diagnostics failed: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testLogin() async {
    if (_passwordController.text.isEmpty) {
      _logResult('❌ Password is required for login test');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _logResult('🔐 Testing login...');

    try {
      final response = await ApiConnect.login(
        username:
            _usernameController.text.isNotEmpty
                ? _usernameController.text
                : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        password: _passwordController.text,
      );

      _logResult('📊 Login Response:');
      _logResult('   Status Code: ${response.statusCode}');
      _logResult('   Headers: ${response.headers}');

      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          _logResult('   Body (JSON): ${jsonEncode(data)}');
        } catch (e) {
          _logResult('   Body (Raw): ${response.body}');
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logResult('✅ Login successful!');
      } else {
        _logResult('❌ Login failed with status ${response.statusCode}');
      }
    } catch (e) {
      _logResult('❌ Login error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testRegister() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _logResult(
        '❌ Username, email, and password are required for register test',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _logResult('📝 Testing registration...');

    try {
      final response = await ApiConnect.register(
        _usernameController.text,
        _emailController.text,
        'Test', // firstName
        'User', // lastName
        _passwordController.text,
        _passwordController.text, // confirmPassword
      );

      _logResult('📊 Register Response:');
      _logResult('   Status Code: ${response.statusCode}');
      _logResult('   Headers: ${response.headers}');

      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          _logResult('   Body (JSON): ${jsonEncode(data)}');
        } catch (e) {
          _logResult('   Body (Raw): ${response.body}');
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logResult('✅ Registration successful!');
      } else {
        _logResult('❌ Registration failed with status ${response.statusCode}');
      }
    } catch (e) {
      _logResult('❌ Registration error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend URL',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ApiConnect.baseUrl,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test credentials
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Credentials',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runDiagnostics,
                    icon: const Icon(Icons.network_check),
                    label: const Text('Run Diagnostics'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('Test Login'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testRegister,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Test Register'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Clear button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _testResults = '';
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Results'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child:
                              _isLoading
                                  ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('Running tests...'),
                                      ],
                                    ),
                                  )
                                  : SingleChildScrollView(
                                    child: Text(
                                      _testResults.isEmpty
                                          ? 'No test results yet. Run a test to see output here.'
                                          : _testResults,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
