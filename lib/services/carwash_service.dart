import 'dart:convert';
import 'package:flutter_application_1/api/api_connect.dart';
import 'package:flutter_application_1/models/cars.dart';

class CarWashService {
  // Fetch car wash locations from backend API
  static Future<List<CarWash>> fetchCarWashes() async {
    try {
      print('[DEBUG] CarWashService: Starting to fetch car washes...');

      final response = await ApiConnect.getLocations();

      if (response != null && response.statusCode == 200) {
        print('[DEBUG] CarWashService: Successfully fetched car washes');
        print('[DEBUG] CarWashService: Response body: ${response.body}');

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check if response has the expected structure
        if (responseData['success'] == true && responseData['data'] != null) {
          final Map<String, dynamic> data = responseData['data'];
          final List<dynamic> locationsData = data['locations'] ?? [];

          print(
            '[DEBUG] CarWashService: Found ${locationsData.length} locations in nested response',
          );

          final List<CarWash> carWashes =
              locationsData.map((json) {
                return CarWash.fromJson(json);
              }).toList();

          print(
            '[DEBUG] CarWashService: Converted to ${carWashes.length} CarWash objects',
          );
          return carWashes;
        } else {
          print('[ERROR] CarWashService: Unexpected response structure');
          print('[ERROR] CarWashService: Response: ${responseData.toString()}');
          return _getFallbackCarWashes();
        }
      } else {
        print(
          '[ERROR] CarWashService: Failed to fetch car washes - Status: ${response?.statusCode}',
        );

        // Return fallback data if API fails
        print('[DEBUG] CarWashService: Returning fallback data');
        return _getFallbackCarWashes();
      }
    } catch (e, stackTrace) {
      print('[ERROR] CarWashService: Exception fetching car washes: $e');
      print('[ERROR] CarWashService: Stack trace: $stackTrace');

      // Return fallback data if there's an exception
      print('[DEBUG] CarWashService: Returning fallback data due to exception');
      return _getFallbackCarWashes();
    }
  }

  // Fallback car wash data (subset of original data for emergency use)
  static List<CarWash> _getFallbackCarWashes() {
    return [
      CarWash(
        id: 'fallback_1',
        name: 'Sparkle Wash (Offline)',
        imageUrl:
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80',
        services: [
          Service(
            id: '1',
            name: 'Exterior Car Washing',
            description: 'Thorough cleaning of the vehicle exterior.',
            price: 1500.0,
          ),
          Service(
            id: '2',
            name: 'Interior Cleaning',
            description: 'Complete interior cleaning and vacuuming.',
            price: 2000.0,
          ),
          Service(
            id: '3',
            name: 'Full Detail',
            description: 'Complete interior and exterior detail.',
            price: 3500.0,
          ),
        ],
        location: 'Demo Location - Backend Offline',
        openHours: '8:00 AM - 6:00 PM',
        latitude: -1.2921,
        longitude: 36.8219,
      ),
      CarWash(
        id: 'fallback_2',
        name: 'CleanRide (Offline)',
        imageUrl:
            'https://images.unsplash.com/photo-1549924231-f129b911e442?auto=format&fit=crop&w=800&q=80',
        services: [
          Service(
            id: '1',
            name: 'Basic Wash',
            description: 'Quick exterior wash.',
            price: 1000.0,
          ),
          Service(
            id: '2',
            name: 'Premium Wash',
            description: 'Exterior and interior cleaning.',
            price: 2500.0,
          ),
        ],
        location: 'Demo Location - Backend Offline',
        openHours: '7:00 AM - 7:00 PM',
        latitude: -1.2833,
        longitude: 36.8167,
      ),
    ];
  }
}
