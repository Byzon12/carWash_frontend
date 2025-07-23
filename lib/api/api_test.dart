import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_connect.dart';

class ApiTest {
  /// Test basic connectivity to the backend server
  static Future<bool> testConnection() async {
    try {
      // Remove '/user/' from base URL to test root endpoint
      final baseUrlWithoutUser = ApiConnect.baseUrl.replaceAll('/user/', '/');
      final url = Uri.parse(
        '${baseUrlWithoutUser}health/',
      ); // Assuming a health check endpoint

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      print('Connection test - Status: ${response.statusCode}');
      print('Connection test - Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  /// Test the user endpoints specifically
  static Future<Map<String, dynamic>> testUserEndpoints() async {
    final results = <String, dynamic>{};

    try {
      // Test register endpoint with invalid data (should get validation error)
      final registerUrl = Uri.parse('${ApiConnect.baseUrl}register/');
      final registerResponse = await http
          .post(
            registerUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({}), // Empty body should trigger validation
          )
          .timeout(const Duration(seconds: 5));

      results['register_endpoint'] = {
        'status_code': registerResponse.statusCode,
        'reachable': true,
        'response_preview':
            registerResponse.body.length > 100
                ? '${registerResponse.body.substring(0, 100)}...'
                : registerResponse.body,
      };
    } catch (e) {
      results['register_endpoint'] = {
        'reachable': false,
        'error': e.toString(),
      };
    }

    try {
      // Test login endpoint with invalid data
      final loginUrl = Uri.parse('${ApiConnect.baseUrl}login/');
      final loginResponse = await http
          .post(
            loginUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({}), // Empty body should trigger validation
          )
          .timeout(const Duration(seconds: 5));

      results['login_endpoint'] = {
        'status_code': loginResponse.statusCode,
        'reachable': true,
        'response_preview':
            loginResponse.body.length > 100
                ? '${loginResponse.body.substring(0, 100)}...'
                : loginResponse.body,
      };
    } catch (e) {
      results['login_endpoint'] = {'reachable': false, 'error': e.toString()};
    }

    return results;
  }

  /// Print detailed connection diagnostics
  static Future<void> runDiagnostics() async {
    print('🔍 Running Backend Connection Diagnostics...\n');

    print('📍 Backend URL: ${ApiConnect.baseUrl}');
    print('📱 Testing from Flutter app...\n');

    // Test basic connection
    print('1️⃣ Testing basic connection...');
    final isConnected = await testConnection();
    print('   Result: ${isConnected ? "✅ Connected" : "❌ Failed"}\n');

    // Test user endpoints
    print('2️⃣ Testing user endpoints...');
    final endpointResults = await testUserEndpoints();

    endpointResults.forEach((endpoint, result) {
      print('   📋 $endpoint:');
      if (result['reachable'] == true) {
        print('      ✅ Reachable');
        print('      📊 Status: ${result['status_code']}');
        print('      📄 Response: ${result['response_preview']}');
      } else {
        print('      ❌ Not reachable');
        print('      🚫 Error: ${result['error']}');
      }
      print('');
    });

    print('🏁 Diagnostics complete!');

    // Provide recommendations
    print('\n💡 Recommendations:');
    if (!isConnected) {
      print(
        '   • Check if your backend server is running on ${ApiConnect.baseUrl}',
      );
      print('   • Verify the IP address is correct for your network');
      print('   • Try using 10.0.2.2:8000 if testing on Android emulator');
      print('   • Check firewall settings');
    }

    endpointResults.forEach((endpoint, result) {
      if (result['reachable'] != true) {
        print('   • $endpoint is not reachable - check backend routing');
      }
    });
  }
}
