import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiConnect {
  // Dynamic base URL based on platform and debug mode
  static String get baseUrl {
    if (kIsWeb) {
      // For web development, use localhost
      return 'http://192.168.137.137:8000/';
    } else {
      // For mobile development - check if debugging wirelessly
      if (kDebugMode) {
        // For wireless debugging, use your computer's IP address
        return 'http://$_wirelessDebugIP:8000/';
      } else {
        // For production or emulator
        return 'https://69bf1260a484.ngrok-free.app/';
      }
    }
  }

  static String get bookingBaseUrl {
    if (kIsWeb) {
      // For web development, use localhost
      return 'http://127.0.0.1:8000/';
    } else {
      // For mobile development - check if debugging wirelessly
      if (kDebugMode) {
        // For wireless debugging, use your computer's IP address
        return 'http://$_wirelessDebugIP:8000/';
      } else {
        // For production or emulator
        return 'http://192.168.137.10:8000/';
      }
    }
  }

  // Configuration for wireless debugging
  // TODO: Update this IP address to match your computer's IP address
  static const String _wirelessDebugIP =
      '192.168.0.108'; // Your actual WiFi IP!

  // Helper method to get your computer's IP for wireless debugging
  static void printNetworkInstructions() {
    print('Current base URL: $baseUrl');
    print('Current platform: ${kIsWeb ? "Web" : "Mobile"}');
    print('Debug mode: $kDebugMode');
    print('Configured IP: $_wirelessDebugIP:8000');
    print('TROUBLESHOOTING STEPS:');
    print('1. Open Command Prompt and run: ipconfig');
    print('2. Find your WiFi adapter IPv4 Address (usually 192.168.x.x)');
    print('3. Update _wirelessDebugIP in api_connect.dart with that IP');
    print('4. Make sure your phone and computer are on the same WiFi network');
    print('5. Ensure your backend server is running on port 8000');
    print('6. Check Windows Firewall settings');
    print('COMMON IPs to try:');
    print('- 192.168.1.x (most common home routers)');
    print('- 192.168.0.x (some routers)');
    print('- 10.0.0.x (some networks)');
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

    final url = Uri.parse('${userBaseUrl}login/');

    // Create body map with conditional logic
    Map<String, dynamic> body = {'password': password};
    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    } else if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    print('🔍 Login request body: ${jsonEncode(body)}'); // Debug log

    try {
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
              throw Exception(
                'Connection timeout - Unable to connect to server',
              );
            },
          );

      print(
        '[DEBUG] ApiConnect: Login response status: ${response.statusCode}',
      );

      // Log detailed error information for debugging
      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
          '[ERROR] ApiConnect: Login failed - Status: ${response.statusCode}',
        );
        try {
          final errorData = jsonDecode(response.body);
        } catch (e) {
        }
      }

      // Handle successful login response
      if (response.statusCode == 200 || response.statusCode == 201) {
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

        } catch (e) {
        }
      } else {
        print(
          '[ERROR] ApiConnect: Login failed with status: ${response.statusCode}',
        );
      }

      return response;
    } catch (e) {
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

  // Logout method - calls backend logout API then clears local storage
  static Future<bool> logout() async {
    try {

      // Get the current access token
      final token = await getAccessToken();

      if (token != null && token.isNotEmpty) {

        // Call backend logout endpoint
        final url = Uri.parse('${userBaseUrl}logout/');

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        print(
          '[DEBUG] ApiConnect: Logout response status: ${response.statusCode}',
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          print('[SUCCESS] ApiConnect: Backend logout successful');
        } else {
          print(
            '[WARNING] ApiConnect: Backend logout failed with status: ${response.statusCode}',
          );
          // Continue with local logout even if backend fails
        }
      } else {
        print(
          '[DEBUG] ApiConnect: No access token found, skipping backend logout',
        );
      }
    } catch (e) {
      // Continue with local logout even if backend call fails
    }

    try {
      // Always clear local storage regardless of backend response
      await storage.deleteAll();
      print('[SUCCESS] ApiConnect: Local storage cleared successfully');

      return true; // Return true if local storage is cleared successfully
    } catch (e) {
      return false;
    }
  }

  // Get stored access token
  static Future<String?> getAccessToken() async {
    return await storage.read(key: 'access');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getAccessToken();

      if (token == null || token.isEmpty) {
        return false;
      }


      // Try to make a simple API call to verify token validity
      final response = await getUserProfile();
      if (response != null && response.statusCode == 200) {
        return true;
      } else if (response != null && response.statusCode == 401) {

        // Try to refresh the token
        final refreshResponse = await refreshToken();
        if (refreshResponse != null && refreshResponse.statusCode == 200) {
          return true;
        } else {
          print(
            '[DEBUG] ApiConnect: Token refresh failed, user needs to login',
          );
          await logout(); // Clear invalid tokens
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Password reset method
  static Future<http.Response> passwordReset(String email) async {
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

    // Log detailed error information for debugging
    if (response.statusCode != 200 && response.statusCode != 201) {
      print(
        '[ERROR] ApiConnect: Password reset failed - Status: ${response.statusCode}',
      );
      try {
        final errorData = jsonDecode(response.body);
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
      if (token == null) {
        return null;
      }

      final url = Uri.parse('${userBaseUrl}profile/');
      final requestBody = {
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        if (address != null) 'address': address,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };


      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print(
        '[DEBUG] ApiConnect: Profile update response status: ${response.statusCode}',
      );
      print(
        '[DEBUG] ApiConnect: Profile update response body: ${response.body}',
      );

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
          .put(
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

      // Get the authentication token
      final token = await getAccessToken();
      if (token == null) {
        print(
          '[ERROR] ApiConnect: No access token available for locations request',
        );
        return null;
      }

      final url = Uri.parse('${userBaseUrl}locations/');

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

      // Log detailed error information for debugging
      if (response.statusCode != 200) {
        print(
          '[ERROR] ApiConnect: Failed to fetch locations - Status: ${response.statusCode}',
        );
        try {
          final errorData = jsonDecode(response.body);
        } catch (e) {
          print(
            '[ERROR] ApiConnect: Could not parse locations error response: $e',
          );
        }
      }

      return response;
    } catch (e, stackTrace) {
      return null;
    }
  }

  // Loyalty Points API Methods

  // Get loyalty dashboard data
  static Future<http.Response?> getLoyaltyDashboard() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return null;
      }

      final url = Uri.parse('${userBaseUrl}loyalty/dashboard/');

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
        '[DEBUG] ApiConnect: Loyalty dashboard response status: ${response.statusCode}',
      );
      print(
        '[DEBUG] ApiConnect: Loyalty dashboard response body: ${response.body}',
      );

      return response;
    } catch (e, stackTrace) {
      return null;
    }
  }

  // Get loyalty points history
  static Future<http.Response?> getLoyaltyHistory() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return null;
      }

      final url = Uri.parse('${userBaseUrl}loyalty/history/');
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
        '[DEBUG] ApiConnect: Loyalty history response status: ${response.statusCode}',
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  // Redeem loyalty points
  static Future<http.Response?> redeemLoyaltyPoints({
    required int points,
    required String rewardType,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return null;
      }

      final url = Uri.parse('${userBaseUrl}loyalty/redeem/');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'points': points, 'reward_type': rewardType}),
          )
          .timeout(const Duration(seconds: 15));

      print(
        '[DEBUG] ApiConnect: Loyalty redemption response status: ${response.statusCode}',
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  // Get loyalty tier information
  static Future<http.Response?> getLoyaltyTierInfo() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return null;
      }

      final url = Uri.parse('${userBaseUrl}loyalty/tier-info/');
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
        '[DEBUG] ApiConnect: Loyalty tier info response status: ${response.statusCode}',
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  // Test network connectivity to backend
  static Future<bool> testConnectivity() async {

    try {
      // Test multiple endpoints to see which one responds
      final testUrls = [
        baseUrl, // Base URL
        '${baseUrl}ping/', // Ping endpoint
        userBaseUrl, // User endpoint
        '${userBaseUrl}login/', // Login endpoint
      ];

      for (String testUrl in testUrls) {
        try {
          final url = Uri.parse(testUrl);
          final response = await http
              .get(url)
              .timeout(
                const Duration(seconds: 3),
                onTimeout: () {
                  print('[TIMEOUT] ApiConnect: $testUrl timed out');
                  throw Exception('Timeout');
                },
              );

          print(
            '[SUCCESS] ApiConnect: $testUrl responded with status ${response.statusCode}',
          );
          if (response.statusCode < 500) {
            return true;
          }
        } catch (e) {
          print('[FAILED] ApiConnect: $testUrl failed: $e');
        }
      }

      return false;
    } catch (e) {
      print('  ✓ Backend server running? Check terminal/console');
      print('  ✓ Correct IP in _wirelessDebugIP? Run ipconfig');
      print('  ✓ Same WiFi network? Check phone and computer WiFi');
      print('  ✓ Windows Firewall? Try temporarily disabling');
      print('  ✓ Port 8000 open? Try: telnet $_wirelessDebugIP 8000');
      return false;
    }
  }

  // Test logout API directly - for debugging purposes
  static Future<void> testLogoutAPI() async {

    try {
      final token = await getAccessToken();
      print(
        '[DEBUG] ApiConnect: Current token: ${token?.substring(0, 20) ?? 'null'}...',
      );

      if (token == null || token.isEmpty) {
        return;
      }

      final url = Uri.parse('${userBaseUrl}logout/');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('  Status: ${response.statusCode}');
      print('  Headers: ${response.headers}');
      print('  Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[SUCCESS] ApiConnect: Logout API test successful!');
      } else {
        print(
          '[ERROR] ApiConnect: Logout API test failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
    }
  }

  // Get user booking history
  static Future<http.Response?> getUserBookingHistory() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return null;
      }

      final url = Uri.parse('$bookingBaseUrl/booking/history/');

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
        '[DEBUG] ApiConnect: Booking history response status: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        print('[SUCCESS] ApiConnect: Booking history fetched successfully');
      } else {
        print(
          '[ERROR] ApiConnect: Booking history fetch failed: ${response.statusCode}',
        );
      }

      return response;
    } catch (e) {
      return null;
    }
  }

  // Favorite Locations API Methods

  // Add a location to favorites
  static Future<http.Response?> addFavoriteLocation({
    required String locationId,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return null;
      }

      final url = Uri.parse('${userBaseUrl}favorites/add/');
      print(
        '[DEBUG] ApiConnect: Adding location ID: $locationId (type: ${locationId.runtimeType})',
      );

      final requestBody = jsonEncode({'location_id': locationId});

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      print(
        '[DEBUG] ApiConnect: Add favorite response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[SUCCESS] ApiConnect: Location added to favorites successfully');
      } else {
        print(
          '[ERROR] ApiConnect: Failed to add favorite - Status: ${response.statusCode}',
        );
        try {
          final errorData = jsonDecode(response.body);

          // Check if it's a location not found error
          if (errorData.toString().contains('DoesNotExist') ||
              errorData.toString().contains(
                'Location matching query does not exist',
              )) {
            print(
              '[ERROR] ApiConnect: LOCATION ID MISMATCH - The location ID "$locationId" does not exist in the backend Location table',
            );
            print(
              '[ERROR] ApiConnect: This suggests the car wash IDs from /locations/ endpoint don\'t match the Location model IDs',
            );
          }
        } catch (e) {
          print(
            '[ERROR] ApiConnect: Could not parse add favorite error response: $e',
          );
        }
      }

      return response;
    } catch (e, stackTrace) {
      return null;
    }
  }

  // Remove a location from favorites
  static Future<http.Response?> removeFavoriteLocation({
    required String locationId,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return null;
      }

      final url = Uri.parse('${userBaseUrl}favorites/remove/');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'location_id': locationId}),
          )
          .timeout(const Duration(seconds: 15));

      print(
        '[DEBUG] ApiConnect: Remove favorite response status: ${response.statusCode}',
      );
      print(
        '[DEBUG] ApiConnect: Remove favorite response body: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print(
          '[SUCCESS] ApiConnect: Location removed from favorites successfully',
        );
      } else {
        print(
          '[ERROR] ApiConnect: Failed to remove favorite - Status: ${response.statusCode}',
        );
        try {
          final errorData = jsonDecode(response.body);
          print(
            '[ERROR] ApiConnect: Remove favorite error details: $errorData',
          );
        } catch (e) {
          print(
            '[ERROR] ApiConnect: Could not parse remove favorite error response: $e',
          );
        }
      }

      return response;
    } catch (e, stackTrace) {
      return null;
    }
  }

  // Get list of user's favorite locations
  static Future<http.Response?> getFavoriteLocations() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return null;
      }

      final url = Uri.parse('${userBaseUrl}favorites/');

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
        '[DEBUG] ApiConnect: Get favorites response status: ${response.statusCode}',
      );
      print(
        '[DEBUG] ApiConnect: Get favorites response body: ${response.body}',
      );

      if (response.statusCode == 200) {
        print('[SUCCESS] ApiConnect: Favorite locations fetched successfully');
        try {
          final data = jsonDecode(response.body);
          final favoritesCount =
              data is List
                  ? data.length
                  : (data is Map && data['data'] is List)
                  ? data['data'].length
                  : 0;
        } catch (e) {
        }
      } else {
        print(
          '[ERROR] ApiConnect: Failed to fetch favorites - Status: ${response.statusCode}',
        );
        try {
          final errorData = jsonDecode(response.body);
        } catch (e) {
          print(
            '[ERROR] ApiConnect: Could not parse get favorites error response: $e',
          );
        }
      }

      return response;
    } catch (e, stackTrace) {
      return null;
    }
  }

  // Check if a location is in user's favorites (helper method)
  static Future<bool> isLocationFavorite({required String locationId}) async {
    try {
      final response = await getFavoriteLocations();

      if (response == null || response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);
      List<dynamic> favorites = [];

      // Handle different response formats
      if (data is List) {
        favorites = data;
      } else if (data is Map && data['data'] is List) {
        favorites = data['data'];
      } else if (data is Map && data['favorites'] is List) {
        favorites = data['favorites'];
      }

      // Check if locationId exists in favorites
      for (var favorite in favorites) {
        String favoriteId;
        if (favorite is Map) {
          favoriteId =
              favorite['id']?.toString() ??
              favorite['location_id']?.toString() ??
              favorite['location']?.toString() ??
              '';
        } else {
          favoriteId = favorite.toString();
        }

        if (favoriteId == locationId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Toggle favorite status (add if not favorite, remove if favorite)
  static Future<bool> toggleFavoriteLocation({
    required String locationId,
  }) async {
    try {
      print(
        '[DEBUG] ApiConnect: Toggling favorite status for location $locationId',
      );

      final isFavorite = await isLocationFavorite(locationId: locationId);

      http.Response? response;
      if (isFavorite) {
        response = await removeFavoriteLocation(locationId: locationId);
      } else {
        response = await addFavoriteLocation(locationId: locationId);
      }

      if (response != null &&
          (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 204)) {
        print('[SUCCESS] ApiConnect: Favorite status toggled successfully');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
