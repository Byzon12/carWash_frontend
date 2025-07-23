import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConnect {
  // TODO: Move this to environment configuration or config file
  // For development - use your local IP
  // For production - use your deployed backend URL
  static const String baseUrl = 'http://127.0.0.1:8000/user/';

  // Alternative: Use localhost for Android emulator
  // static const String baseUrl = 'http://10.0.2.2:8000/user/';

  // For production, use:
  // static const String baseUrl = 'https://your-backend-domain.com/user/';

  static FlutterSecureStorage get storage => const FlutterSecureStorage();

  static Future<http.Response> register(
    String username,
    String email,
    String firstName,
    String lastName,
    String password,
    String confirmPassword,
  ) async {
    final url = Uri.parse('${baseUrl}register/');
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
    final url = Uri.parse('${baseUrl}login/');

    // Create body map with conditional logic
    Map<String, dynamic> body = {'password': password};
    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    } else if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    print('🔍 Login request body: ${jsonEncode(body)}'); // Debug log

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body), // Use the conditional body
        )
        .timeout(const Duration(seconds: 10));

    print('[DEBUG] ApiConnect: Login response status: ${response.statusCode}');
    print('[DEBUG] ApiConnect: Login response body: ${response.body}');

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
  }

  // Token refresh method
  static Future<http.Response?> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh');
      if (refreshToken == null) return null;

      final url = Uri.parse('${baseUrl}refresh/');
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
    final url = Uri.parse('${baseUrl}password-reset/');
    return await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 10));
  }

  // Get user profile method
  static Future<http.Response?> getUserProfile() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final url = Uri.parse('${baseUrl}profile/');
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

      final url = Uri.parse('${baseUrl}profile/');
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

      final url = Uri.parse('${baseUrl}change-password/');
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
}
