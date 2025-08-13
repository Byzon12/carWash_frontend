import 'package:http/http.dart' as http;

void main() async {
  // Test the booking API endpoints directly
  final baseUrl = 'http://192.168.0.108:8000';

  // Test endpoints
  final testUrls = [
    '$baseUrl/',
    '$baseUrl/booking/',
    '$baseUrl/booking/list/',
    '$baseUrl/booking/create/',
    '$baseUrl/user/',
    '$baseUrl/user/login/',
  ];

  for (String testUrl in testUrls) {
    try {
      final url = Uri.parse(testUrl);
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Timeout');
            },
          );
      if (response.statusCode < 500) {
        print(
          '[BODY] ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}',
        );
      }
    } catch (e) {}
  }
  print('1. Authentication (JWT token)');
}
