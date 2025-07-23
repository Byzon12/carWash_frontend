import 'package:flutter_application_1/api/api_connect.dart';

Future<void> main() async {
  print('[TEST] Starting comprehensive login test...');

  // Test 1: Network connectivity
  print('\n[TEST 1] Testing network connectivity...');
  try {
    final response = await ApiConnect.login(
      username: 'invalid_user', // Intentionally wrong credentials
      password: 'invalid_pass',
    );

    print('[TEST 1] Response status: ${response.statusCode}');
    print('[TEST 1] Response body: ${response.body}');

    if (response.statusCode == 401) {
      print(
        '[TEST 1] ✅ Network working - got expected 401 for wrong credentials',
      );
    } else if (response.statusCode == 400) {
      print('[TEST 1] ✅ Network working - got 400 bad request');
    } else {
      print('[TEST 1] ⚠️ Unexpected status code: ${response.statusCode}');
    }
  } catch (e) {
    print('[TEST 1] ❌ Network error: $e');
    print(
      '[TEST 1] Make sure backend server is running on http://127.0.0.1:8000/',
    );
    return; // Exit if network fails
  }

  // Test 2: Test with valid credentials (if you have any)
  print('\n[TEST 2] Test with your actual credentials...');
  print(
    '[TEST 2] Replace "your_username" and "your_password" with real values',
  );

  try {
    final response = await ApiConnect.login(
      username: 'your_username', // Replace with actual username
      password: 'your_password', // Replace with actual password
    );

    print('[TEST 2] Response status: ${response.statusCode}');
    print('[TEST 2] Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('[TEST 2] ✅ Login successful with valid credentials!');

      // Test token retrieval
      final token = await ApiConnect.getAccessToken();
      print('[TEST 2] Token retrieved: ${token != null ? 'Yes' : 'No'}');

      // Test login status
      final isLoggedIn = await ApiConnect.isLoggedIn();
      print('[TEST 2] Is logged in: $isLoggedIn');
    } else {
      print('[TEST 2] ❌ Login failed - check your credentials');
    }
  } catch (e) {
    print('[TEST 2] ❌ Error: $e');
  }

  print('\n[TEST] Complete!');
}
