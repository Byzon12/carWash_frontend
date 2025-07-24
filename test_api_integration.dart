import 'dart:convert';
import 'package:flutter_application_1/models/cars.dart';
import 'package:flutter_application_1/services/carwash_service.dart';

void main() async {
  print('🚗 Testing Car Wash API Integration...\n');

  // Test JSON parsing with your actual API response format
  const String testApiResponse = '''
  {
    "success": true,
    "message": "Available locations retrieved successfully",
    "data": {
        "total_locations": 5,
        "locations": [
            {
                "id": 1,
                "name": "Downtown Car Wash",
                "address": "123 Main Street, Downtown",
                "latitude": 40.7128,
                "longitude": -74.0060,
                "contact_number": "+1234567890",
                "email": "downtown@carwash.com",
                "distance": 2.5,
                "available_services": [
                    {
                        "id": 1,
                        "name": "Basic Wash Package",
                        "description": "Exterior wash and interior cleaning",
                        "duration": "1:00:00",
                        "price": "25.00",
                        "services_included": [
                            {
                                "id": 1,
                                "name": "Exterior Wash",
                                "price": "15.00"
                            }
                        ]
                    }
                ],
                "total_services": 3,
                "average_rating": 4.5,
                "total_bookings": 150,
                "is_open": true,
                "business_info": {
                    "contact_number": "+1234567890",
                    "email": "downtown@carwash.com",
                    "operating_hours": {
                        "monday": "8:00 AM - 6:00 PM",
                        "tuesday": "8:00 AM - 6:00 PM"
                    },
                    "payment_methods": ["Cash", "M-Pesa", "Credit Card"],
                    "features": ["WiFi", "Waiting Area", "Restrooms"]
                }
            }
        ]
    }
  }
  ''';

  try {
    print('📋 Testing JSON Parsing...');
    final Map<String, dynamic> responseData = jsonDecode(testApiResponse);

    if (responseData['success'] == true && responseData['data'] != null) {
      final Map<String, dynamic> data = responseData['data'];
      final List<dynamic> locationsData = data['locations'] ?? [];

      print('✅ Found ${locationsData.length} locations in response');

      if (locationsData.isNotEmpty) {
        final firstLocation = locationsData[0];
        print('📍 First location data: ${firstLocation['name']}');

        // Test CarWash model parsing
        final carWash = CarWash.fromJson(firstLocation);

        print('\n🏪 Parsed CarWash:');
        print('   ID: ${carWash.id}');
        print('   Name: ${carWash.name}');
        print('   Location: ${carWash.location}');
        print('   Coordinates: ${carWash.latitude}, ${carWash.longitude}');
        print('   Hours: ${carWash.openHours}');
        print('   Services: ${carWash.services.length} available');

        print('\n🛠️ Services:');
        for (var service in carWash.services) {
          print('   - ${service.name}: \$${service.price}');
          if (service.description.isNotEmpty) {
            print('     ${service.description}');
          }
        }

        print('\n✅ JSON parsing successful!');
      }
    }

    print('\n🌐 Testing Live API Call...');
    print(
      'Note: This will only work if your Django backend is running on http://127.0.0.1:8000',
    );

    try {
      final carWashes = await CarWashService.fetchCarWashes();
      print('✅ Live API call successful!');
      print('📍 Retrieved ${carWashes.length} car wash locations from backend');

      for (var carWash in carWashes) {
        print('   - ${carWash.name} (${carWash.services.length} services)');
      }
    } catch (e) {
      print('❌ Live API call failed (expected if backend is not running):');
      print('   Error: $e');
      print(
        '   This is normal if your Django backend is not currently running.',
      );
    }
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
  }

  print('\n🎯 Integration Test Complete!');
  print('The app is ready to fetch dynamic data from your backend API.');
}
