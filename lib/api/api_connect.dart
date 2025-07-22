import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConnect {
  static const String baseUrl = 'http://192.168.137.43:8000/user/';

  static get storage => const FlutterSecureStorage();

  static Future<http.Response> register(
    String username,
    String email,
    String FirstName,
    String LastName,
    String password,
    String confirm_password,
  ) async {
    final url = Uri.parse('${baseUrl}register/');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'first_name': FirstName,
        'last_name': LastName,
        'password': password,
        'confirm_password': confirm_password
      }),
    );
  }

  // Login user with either username or email and get JWT token
  static Future<http.Response> login({String? username, String? email, required String password}) async {
    final url = Uri.parse('${baseUrl}login/'); // <-- change to token/
    Map<String, dynamic> body = {'password': password};
    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    } else if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    // You can handle the response here if needed, for example:
     if (response.statusCode == 200 || response.statusCode == 201) {
       final data = jsonDecode(response.body);
       await storage.write(key:'access', value: data['access']);
       await storage.write(key: 'refresh', value: data['refresh']);
     }

    return response;

  }
}