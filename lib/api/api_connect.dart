import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiConnect {
  // Dynamic base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      // For web development, use localhost
      return 'http://localhost:8000/';
    } else {
      // For mobile development
      return 'http://127.0.0.1:8000/';
    }
  }

  // User authentication base URL
  static String get userBaseUrl {
    return '${baseUrl}user/';
  }

  // Users data base URL
  static String get usersBaseUrl {
    return '${baseUrl}users/';
  }

  // Alternative configurations for different scenarios:
  // For Android emulator: 'http://10.0.2.2:8000/user/'
  // For production: 'https://your-backend-domain.com/user/'

  static FlutterSecureStorage get storage => const FlutterSecureStorage();

  static Future<http.Response> register(
    String username,
    String email,
    String firstName,
    String lastName,
    String password,
    String confirmPassword,
  ) async {
    final url = Uri.parse('${userBaseUrl}register/');
    return await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'password': password,
            'confirm_password': confirmPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));
  }

  // Login user with either username or email and get JWT token
  static Future<http.Response> login({
    String? username,
    String? email,
    required String password,
  }) async {
    print('[DEBUG] ApiConnect: Starting login request');
    print('[DEBUG] ApiConnect: Using user base URL: $userBaseUrl');
    print('[DEBUG] ApiConnect: Platform - Web: $kIsWeb');

    final url = Uri.parse('${userBaseUrl}login/');
    print('[DEBUG] ApiConnect: Full login URL: $url');

    // Create body map with conditional logic
    Map<String, dynamic> body = {'password': password};
    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    } else if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    print('🔍 Login request body: ${jsonEncode(body)}'); // Debug log

    try {
      print('[DEBUG] ApiConnect: Sending HTTP POST request...');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body), // Use the conditional body
          )
          .timeout(
            const Duration(seconds: 30), // Increased timeout
            onTimeout: () {
              print('[ERROR] ApiConnect: Request timed out after 30 seconds');
              throw Exception(
                'Connection timeout - Unable to connect to server',
              );
            },
          );

      print('[DEBUG] ApiConnect: HTTP request completed successfully');
      print(
        '[DEBUG] ApiConnect: Login response status: ${response.statusCode}',
      );
      print('[DEBUG] ApiConnect: Login response body: ${response.body}');

      // Log detailed error information for debugging
      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
          '[ERROR] ApiConnect: Login failed - Status: ${response.statusCode}',
        );
        try {
          final errorData = jsonDecode(response.body);
          print('[ERROR] ApiConnect: Server error details: $errorData');
        } catch (e) {
          print('[ERROR] ApiConnect: Could not parse error response: $e');
        }
      }

      // Handle successful login response
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[DEBUG] ApiConnect: Login successful, storing user data');
        try {
          final data = jsonDecode(response.body);

          // Store tokens
          await storage.write(key: 'access', value: data['access']);
          await storage.write(key: 'refresh', value: data['refresh']);

          // Store user profile data if available
          if (data['username'] != null) {
            await storage.write(key: 'username', value: data['username']);
          }
          if (data['email'] != null) {
            await storage.write(key: 'email', value: data['email']);
          }
          if (data['first_name'] != null) {
            await storage.write(key: 'first_name', value: data['first_name']);
          }
          if (data['last_name'] != null) {
            await storage.write(key: 'last_name', value: data['last_name']);
          }

          print('[DEBUG] ApiConnect: User data stored successfully');
        } catch (e) {
          print('[ERROR] ApiConnect: Error parsing/storing login response: $e');
        }
      } else {
        print(
          '[ERROR] ApiConnect: Login failed with status: ${response.statusCode}',
        );
      }

      return response;
    } catch (e) {
      print('[ERROR] ApiConnect: Network error during login: $e');
      // Create a mock response for network errors
      final errorResponse = http.Response(
        jsonEncode({
          'error': 'Connection failed',
          'detail':
              'Unable to connect to server. Please check your connection.',
          'message': e.toString(),
        }),
        500,
      );
      return errorResponse;
    }
  }

  // Token refresh method
  static Future<http.Response?> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh');
      if (refreshToken == null) return null;

      final url = Uri.parse('${userBaseUrl}refresh/');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'access', value: data['access']);
      }

      return response;
    } catch (e) {
      return null;
    }
  }

  // Logout method
  static Future<void> logout() async {
    await storage.deleteAll();
  }

  // Get stored access token
  static Future<String?> getAccessToken() async {
    return await storage.read(key: 'access');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      print('[DEBUG] ApiConnect: Checking if user is logged in...');
      final token = await getAccessToken();

      if (token == null || token.isEmpty) {
        print('[DEBUG] ApiConnect: No access token found');
        return false;
      }

      print('[DEBUG] ApiConnect: Access token found, checking validity...');

      // Try to make a simple API call to verify token validity
      final response = await getUserProfile();
      if (response != null && response.statusCode == 200) {
        print('[DEBUG] ApiConnect: Token is valid, user is logged in');
        return true;
      } else if (response != null && response.statusCode == 401) {
        print('[DEBUG] ApiConnect: Token expired, trying to refresh...');

        // Try to refresh the token
        final refreshResponse = await refreshToken();
        if (refreshResponse != null && refreshResponse.statusCode == 200) {
          print('[DEBUG] ApiConnect: Token refreshed successfully');
          return true;
        } else {
          print(
            '[DEBUG] ApiConnect: Token refresh failed, user needs to login',
          );
          await logout(); // Clear invalid tokens
          return false;
        }
      } else {
        print('[DEBUG] ApiConnect: Token validation failed');
        return false;
      }
    } catch (e) {
      print('[ERROR] ApiConnect: Exception checking login status: $e');
      return false;
    }
  }

  // Password reset method
  static Future<http.Response> passwordReset(String email) async {
    print('[DEBUG] ApiConnect: Sending password reset for email: $email');
    final url = Uri.parse('${userBaseUrl}password-reset/');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 10));

    print(
      '[DEBUG] ApiConnect: Password reset response status: ${response.statusCode}',
    );
    print('[DEBUG] ApiConnect: Password reset response body: ${response.body}');

    // Log detailed error information for debugging
    if (response.statusCode != 200 && response.statusCode != 201) {
      print(
        '[ERROR] ApiConnect: Password reset failed - Status: ${response.statusCode}',
      );
      try {
        final errorData = jsonDecode(response.body);
        print('[ERROR] ApiConnect: Password reset error details: $errorData');
      } catch (e) {
        print(
          '[ERROR] ApiConnect: Could not parse password reset error response: $e',
        );
      }
    }

    return response;
  }

  // Get user profile method
  static Future<http.Response?> getUserProfile() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final url = Uri.parse('${userBaseUrl}profile/');
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response;
    } catch (e) {
      return null;
    }
  }

  // Update user profile method
  static Future<http.Response?> updateProfile({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    String? address,
    String? phoneNumber,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final url = Uri.parse('${userBaseUrl}profile/');
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'username': username,
              'email': email,
              'first_name': firstName,
              'last_name': lastName,
              if (address != null) 'address': address,
              if (phoneNumber != null) 'phone_number': phoneNumber,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response;
    } catch (e) {
      return null;
    }
  }

  // Change password method
  static Future<http.Response?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final url = Uri.parse('${userBaseUrl}password-reset-change/');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
              'confirm_password': confirmPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response;
    } catch (e) {
      return null;
    }
  }

  // Get car wash locations method
  static Future<http.Response?> getLocations() async {
    try {
      print('[DEBUG] ApiConnect: Fetching car wash locations...');
      print('[DEBUG] ApiConnect: Using user base URL: $userBaseUrl');

      // Get the authentication token
      final token = await getAccessToken();
      if (token == null) {
        print(
          '[ERROR] ApiConnect: No access token available for locations request',
        );
        return null;
      }

      final url = Uri.parse('${userBaseUrl}locations/');
      print('[DEBUG] ApiConnect: Full locations URL: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      print(
        '[DEBUG] ApiConnect: Locations response status: ${response.statusCode}',
      );
      print('[DEBUG] ApiConnect: Locations response body: ${response.body}');

      // Log detailed error information for debugging
      if (response.statusCode != 200) {
        print(
          '[ERROR] ApiConnect: Failed to fetch locations - Status: ${response.statusCode}',
        );
        try {
          final errorData = jsonDecode(response.body);
          print('[ERROR] ApiConnect: Locations error details: $errorData');
        } catch (e) {
          print(
            '[ERROR] ApiConnect: Could not parse locations error response: $e',
          );
        }
      }

      return response;
    } catch (e, stackTrace) {
      print('[ERROR] ApiConnect: Exception fetching locations: $e');
      print('[ERROR] ApiConnect: Stack trace: $stackTrace');
      return null;
    }
  }
}
