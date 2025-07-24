import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_connect.dart';
import 'dart:convert';

class BackendConnectivityTest extends StatefulWidget {
  const BackendConnectivityTest({super.key});

  @override
  State<BackendConnectivityTest> createState() =>
      _BackendConnectivityTestState();
}

class _BackendConnectivityTestState extends State<BackendConnectivityTest> {
  String _testResult = '';
  bool _isLoading = false;

  Future<void> _testBackendConnectivity() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing backend connectivity...';
    });

    try {
      // Test 1: Check if user is logged in
      print('[TEST] Step 1: Checking login status...');
      final isLoggedIn = await ApiConnect.isLoggedIn();

      String result = 'TEST RESULTS:\n\n';
      result +=
          '1. Login Status: ${isLoggedIn ? '✅ Logged in' : '❌ Not logged in'}\n\n';

      if (!isLoggedIn) {
        result +=
            '⚠️ WARNING: User is not logged in. The locations API requires authentication.\n';
        result += 'Please login first before testing locations API.\n\n';
      }

      // Test 2: Check access token
      print('[TEST] Step 2: Checking access token...');
      final token = await ApiConnect.getAccessToken();
      result +=
          '2. Access Token: ${token != null ? '✅ Available (${token.substring(0, 20)}...)' : '❌ Missing'}\n\n';

      // Test 3: Test base URL connectivity
      print('[TEST] Step 3: Testing base URL...');
      result += '3. Base URLs:\n';
      result += '   - Base URL: ${ApiConnect.baseUrl}\n';
      result += '   - User Base URL: ${ApiConnect.userBaseUrl}\n';
      result += '   - Users Base URL: ${ApiConnect.usersBaseUrl}\n\n';

      // Test 4: Test locations API
      print('[TEST] Step 4: Testing locations API...');
      result += '4. Locations API Test:\n';

      try {
        final response = await ApiConnect.getLocations();
        if (response != null) {
          result += '   - Status Code: ${response.statusCode}\n';
          result +=
              '   - Response Length: ${response.body.length} characters\n';

          if (response.statusCode == 200) {
            try {
              final data = jsonDecode(response.body);
              if (data is Map && data.containsKey('results')) {
                final locations = data['results'] as List;
                result += '   - Locations Found: ${locations.length}\n';
                result +=
                    '   - ✅ SUCCESS: Backend data retrieved successfully!\n';
              } else if (data is List) {
                result += '   - Locations Found: ${data.length}\n';
                result +=
                    '   - ✅ SUCCESS: Backend data retrieved successfully!\n';
              } else {
                result += '   - ⚠️ Unexpected response format\n';
              }
              result +=
                  '   - Raw Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...\n';
            } catch (e) {
              result += '   - ❌ JSON Parse Error: $e\n';
              result += '   - Raw Response: ${response.body}\n';
            }
          } else {
            result += '   - ❌ HTTP Error: ${response.statusCode}\n';
            result += '   - Error Body: ${response.body}\n';
          }
        } else {
          result += '   - ❌ NULL Response - Network/Connection Error\n';
          result += '   - Possible causes:\n';
          result += '     • Backend server not running\n';
          result += '     • Wrong URL configuration\n';
          result += '     • Network connectivity issues\n';
          result += '     • CORS issues (for web)\n';
        }
      } catch (e) {
        result += '   - ❌ Exception: $e\n';
      }

      setState(() {
        _testResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Test failed with exception: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connectivity Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Backend API Connectivity Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This will test the backend API connectivity and diagnose why locations are not being fetched.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testBackendConnectivity,
              child:
                  _isLoading
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Testing...'),
                        ],
                      )
                      : const Text('Test Backend Connectivity'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult.isEmpty
                        ? 'Click the button above to run the connectivity test.'
                        : _testResult,
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
    );
  }
}
