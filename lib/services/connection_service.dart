import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ConnectionService {
  static const Duration _defaultTimeout = Duration(
    seconds: 10,
  ); // Reduced timeout
  static DateTime? _lastSuccessfulCheck;
  static const Duration _cacheValidDuration = Duration(
    minutes: 2,
  ); // Cache results for 2 minutes

  // Test multiple backend URLs to find the working one
  static List<String> get _testUrls {
    if (kIsWeb) {
      return [
        'http://localhost:8000/',
        'http://127.0.0.1:8000/',
        'http://0.0.0.0:8000/',
      ];
    } else {
      return [
        'http://127.0.0.1:8000/',
        'http://localhost:8000/',
        'http://10.0.2.2:8000/', // Android emulator
      ];
    }
  }

  /// Test connectivity to the backend server
  static Future<String?> findWorkingBackendUrl() async {
    print('[DEBUG] ConnectionService: Testing backend connectivity...');

    for (String baseUrl in _testUrls) {
      try {
        print('[DEBUG] ConnectionService: Testing URL: $baseUrl');

        final response = await http
            .get(
              Uri.parse(baseUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(_defaultTimeout);

        print(
          '[DEBUG] ConnectionService: Response from $baseUrl: ${response.statusCode}',
        );

        // If we get any response (even 404), the server is reachable
        if (response.statusCode < 500) {
          print(
            '[SUCCESS] ConnectionService: Found working backend at: $baseUrl',
          );
          return baseUrl;
        }
      } catch (e) {
        print('[ERROR] ConnectionService: Failed to connect to $baseUrl: $e');
        continue;
      }
    }

    print('[ERROR] ConnectionService: No working backend URL found');
    return null;
  }

  /// Check if the backend is running and accessible
  static Future<bool> isBackendAvailable() async {
    // Use cached result if recent check was successful
    if (_lastSuccessfulCheck != null &&
        DateTime.now().difference(_lastSuccessfulCheck!) <
            _cacheValidDuration) {
      print(
        '[DEBUG] ConnectionService: Using cached successful connection result',
      );
      return true;
    }

    final workingUrl = await findWorkingBackendUrl();
    final isAvailable = workingUrl != null;

    if (isAvailable) {
      _lastSuccessfulCheck = DateTime.now();
      print('[DEBUG] ConnectionService: Backend available, caching result');
    }

    return isAvailable;
  }

  /// Get the current network status
  static Future<Map<String, dynamic>> getNetworkStatus() async {
    Map<String, dynamic> status = {
      'isConnected': false,
      'backendUrl': null,
      'platform': kIsWeb ? 'web' : 'mobile',
      'testResults': <Map<String, dynamic>>[],
    };

    for (String baseUrl in _testUrls) {
      Map<String, dynamic> testResult = {
        'url': baseUrl,
        'success': false,
        'statusCode': null,
        'error': null,
        'responseTime': null,
      };

      try {
        final stopwatch = Stopwatch()..start();

        final response = await http
            .get(
              Uri.parse(baseUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(_defaultTimeout);

        stopwatch.stop();

        testResult['success'] = response.statusCode < 500;
        testResult['statusCode'] = response.statusCode;
        testResult['responseTime'] = stopwatch.elapsedMilliseconds;

        if (response.statusCode < 500 && status['backendUrl'] == null) {
          status['isConnected'] = true;
          status['backendUrl'] = baseUrl;
        }
      } catch (e) {
        testResult['error'] = e.toString();
      }

      status['testResults'].add(testResult);
    }

    return status;
  }

  /// Test login functionality with detailed logging
  static Future<Map<String, dynamic>> testLogin({
    required String username,
    required String password,
    String? customBackendUrl,
  }) async {
    print('[DEBUG] ConnectionService: Starting login test...');

    Map<String, dynamic> result = {
      'success': false,
      'error': null,
      'statusCode': null,
      'response': null,
      'backendUrl': null,
      'steps': <String>[],
    };

    try {
      // Step 1: Find working backend URL
      result['steps'].add('Finding working backend URL...');
      String? backendUrl = customBackendUrl ?? await findWorkingBackendUrl();

      if (backendUrl == null) {
        result['error'] = 'No accessible backend server found';
        result['steps'].add('❌ No backend server accessible');
        return result;
      }

      result['backendUrl'] = backendUrl;
      result['steps'].add('✅ Found working backend: $backendUrl');

      // Step 2: Prepare login request
      result['steps'].add('Preparing login request...');
      final loginUrl = Uri.parse('${backendUrl}user/login/');
      final requestBody = {'username': username, 'password': password};

      // Step 3: Send login request
      result['steps'].add('Sending login request to: $loginUrl');
      final response = await http
          .post(
            loginUrl,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_defaultTimeout);

      // Step 4: Process response
      result['statusCode'] = response.statusCode;
      result['steps'].add(
        'Received response with status: ${response.statusCode}',
      );

      try {
        final responseData = jsonDecode(response.body);
        result['response'] = responseData;
        result['steps'].add('Successfully parsed response JSON');
      } catch (e) {
        result['response'] = response.body;
        result['steps'].add('Response is not valid JSON: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        result['success'] = true;
        result['steps'].add('✅ Login successful!');
      } else {
        result['error'] = 'Login failed with status ${response.statusCode}';
        result['steps'].add('❌ Login failed');
      }
    } catch (e) {
      result['error'] = e.toString();
      result['steps'].add('❌ Exception occurred: $e');
    }

    return result;
  }
}
