import 'dart:io';
import 'lib/api/api_connect.dart';

void main() async {
  print('🧪 Testing API Connectivity...\n');

  // Test 1: Check if server is reachable
  print('1️⃣ Testing server connectivity...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://127.0.0.1:8000/'));
    final response = await request.close();
    print('✅ Server is reachable (Status: ${response.statusCode})');
    client.close();
  } catch (e) {
    print('❌ Server not reachable: $e');
    return;
  }

  // Test 2: Test login functionality
  print('\n2️⃣ Testing login functionality...');
  try {
    final loginResponse = await ApiConnect.login(
      'your_test_email@example.com',
      'your_test_password',
    );
    if (loginResponse.statusCode == 200) {
      print('✅ Login successful');

      // Test 3: Test locations API with authentication
      print('\n3️⃣ Testing locations API...');
      final locationsResponse = await ApiConnect.getLocations();
      if (locationsResponse != null && locationsResponse.statusCode == 200) {
        print('✅ Locations API working properly');
        print('📍 Response: ${locationsResponse.body}');
      } else {
        print('❌ Locations API failed');
        if (locationsResponse != null) {
          print('Status: ${locationsResponse.statusCode}');
          print('Response: ${locationsResponse.body}');
        }
      }
    } else {
      print('❌ Login failed');
      print('Status: ${loginResponse.statusCode}');
      print('Response: ${loginResponse.body}');
    }
  } catch (e) {
    print('❌ Test failed with exception: $e');
  }

  print('\n🏁 Test completed!');
}
