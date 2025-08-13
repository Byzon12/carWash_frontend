import 'dart:convert';
import 'package:flutter_application_1/models/cars.dart';
import 'package:flutter_application_1/services/carwash_service.dart';

void main() async {// Test JSON parsing with your actual API response format
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

  try {final Map<String, dynamic> responseData = jsonDecode(testApiResponse);

    if (responseData['success'] == true && responseData['data'] != null) {
      final Map<String, dynamic> data = responseData['data'];
      final List<dynamic> locationsData = data['locations'] ?? [];if (locationsData.isNotEmpty) {
        final firstLocation = locationsData[0];// Test CarWash model parsing
        final carWash = CarWash.fromJson(firstLocation);for (var service in carWash.services) {if (service.description.isNotEmpty) {}
        }}
    }try {
      final carWashes = await CarWashService.fetchCarWashes();for (var carWash in carWashes) {}
    } catch (e) {
      print('❌ Live API call failed (expected if backend is not running):');}
  } catch (e, stackTrace) {}}
