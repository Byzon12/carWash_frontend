import 'dart:convert';
import '../api/api_connect.dart';
import '../models/cars.dart';

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

        // Check if response has the expected structure from Django backend
        if (responseData['message'] != null && responseData['data'] != null) {
          final Map<String, dynamic> data = responseData['data'];
          final List<dynamic> locationsData = data['locations'] ?? [];

          print('[DEBUG] CarWashService: Message: ${responseData['message']}');
          print(
            '[DEBUG] CarWashService: Found ${locationsData.length} locations in Django response',
          );

          final List<CarWash> carWashes =
              locationsData.map((json) {
                return CarWash.fromDjangoJson(json);
              }).toList();

          print(
            '[DEBUG] CarWashService: Converted to ${carWashes.length} CarWash objects',
          );
          return carWashes;
        } else {
          print('[ERROR] CarWashService: Unexpected response structure');
          print(
            '[ERROR] CarWashService: Expected Django format with message and data fields',
          );
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
    // Create fallback business info
    final fallbackBusinessInfo = BusinessInfo(
      contactNumber: '+254712345678',
      email: 'contact@sparklewash.co.ke',
      operatingHours: {
        'monday': '8:00 AM - 6:00 PM',
        'tuesday': '8:00 AM - 6:00 PM',
        'wednesday': '8:00 AM - 6:00 PM',
        'thursday': '8:00 AM - 6:00 PM',
        'friday': '8:00 AM - 6:00 PM',
        'saturday': '9:00 AM - 5:00 PM',
        'sunday': '10:00 AM - 4:00 PM',
      },
      paymentMethods: ['Cash', 'M-Pesa', 'Credit Card'],
      languages: ['English', 'Swahili'],
      parking: 'Available',
      accessibility: 'Wheelchair accessible',
    );

    final fallbackBusinessInfo2 = BusinessInfo(
      contactNumber: '+254712345679',
      email: 'info@cleanride.co.ke',
      operatingHours: {
        'monday': '7:00 AM - 7:00 PM',
        'tuesday': '7:00 AM - 7:00 PM',
        'wednesday': '7:00 AM - 7:00 PM',
        'thursday': '7:00 AM - 7:00 PM',
        'friday': '7:00 AM - 7:00 PM',
        'saturday': '8:00 AM - 6:00 PM',
        'sunday': '9:00 AM - 5:00 PM',
      },
      paymentMethods: ['Cash', 'M-Pesa'],
      languages: ['English', 'Swahili'],
      parking: 'Available',
      accessibility: 'Wheelchair accessible',
    );

    // Create fallback location services
    final sparkleServices = [
      LocationService(
        id: '1',
        name: 'Exterior Wash Package',
        description:
            'Thorough cleaning of the vehicle exterior with premium soap',
        duration: '45 minutes',
        totalPrice: 1500.0,
        servicesIncluded: [
          Service(
            id: '1a',
            name: 'Exterior Wash',
            description: 'Full exterior cleaning',
            price: 800.0,
          ),
          Service(
            id: '1b',
            name: 'Wheel Cleaning',
            description: 'Rim and tire cleaning',
            price: 400.0,
          ),
          Service(
            id: '1c',
            name: 'Basic Wax',
            description: 'Protective wax coating',
            price: 300.0,
          ),
        ],
        serviceCount: 3,
        isPopular: true,
        averageRating: 4.5,
        bookingCount: 150,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      LocationService(
        id: '2',
        name: 'Full Detail Package',
        description: 'Complete interior and exterior detail service',
        duration: '2 hours',
        totalPrice: 3500.0,
        servicesIncluded: [
          Service(
            id: '2a',
            name: 'Interior Cleaning',
            description: 'Complete interior cleaning',
            price: 1200.0,
          ),
          Service(
            id: '2b',
            name: 'Exterior Detail',
            description: 'Premium exterior detailing',
            price: 1500.0,
          ),
          Service(
            id: '2c',
            name: 'Engine Clean',
            description: 'Engine bay cleaning',
            price: 800.0,
          ),
        ],
        serviceCount: 3,
        isPopular: false,
        averageRating: 4.8,
        bookingCount: 89,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final cleanrideServices = [
      LocationService(
        id: '3',
        name: 'Basic Wash',
        description: 'Quick and efficient exterior wash',
        duration: '30 minutes',
        totalPrice: 1000.0,
        servicesIncluded: [
          Service(
            id: '3a',
            name: 'Quick Wash',
            description: 'Fast exterior cleaning',
            price: 700.0,
          ),
          Service(
            id: '3b',
            name: 'Dry & Polish',
            description: 'Drying and basic polish',
            price: 300.0,
          ),
        ],
        serviceCount: 2,
        isPopular: true,
        averageRating: 4.2,
        bookingCount: 200,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

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
        address: '123 Demo Street, Nairobi - Backend Offline',
        contactNumber: '+254712345678',
        email: 'contact@sparklewash.co.ke',
        locationServices: sparkleServices,
        totalServices: 2,
        priceRange: PriceRange(min: 1500.0, max: 3500.0, currency: 'KES'),
        popularServices: [sparkleServices[0]], // First service is popular
        distance: null,
        averageRating: 4.6,
        totalBookings: 239,
        completionRate: 95.0,
        isOpen: true,
        businessInfo: fallbackBusinessInfo,
        features: [
          'Free WiFi',
          'Waiting Area',
          'Restrooms',
          'Coffee Service',
          'Covered Parking',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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
        address: '456 Demo Avenue, Nairobi - Backend Offline',
        contactNumber: '+254712345679',
        email: 'info@cleanride.co.ke',
        locationServices: cleanrideServices,
        totalServices: 1,
        priceRange: PriceRange(min: 1000.0, max: 1000.0, currency: 'KES'),
        popularServices: cleanrideServices, // All services are popular
        distance: null,
        averageRating: 4.2,
        totalBookings: 200,
        completionRate: 88.0,
        isOpen: true,
        businessInfo: fallbackBusinessInfo2,
        features: [
          'Free WiFi',
          'Quick Service',
          'Mobile Payment',
          'Air Conditioning',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
