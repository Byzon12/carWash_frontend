class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  CarWash? carWash;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.carWash,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description, 'price': price};
  }
}

// Enhanced LocationService class to match backend structure
class LocationService {
  final String id;
  final String name;
  final String description;
  final String duration;
  final double totalPrice;
  final List<Service> servicesIncluded;
  final int serviceCount;
  final bool isPopular;
  final double averageRating;
  final int bookingCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationService({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.totalPrice,
    required this.servicesIncluded,
    required this.serviceCount,
    required this.isPopular,
    required this.averageRating,
    required this.bookingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationService.fromJson(Map<String, dynamic> json) {
    List<Service> includedServices = [];
    if (json['services_included'] != null) {
      for (var serviceData in json['services_included']) {
        includedServices.add(Service.fromJson(serviceData));
      }
    }

    return LocationService(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      totalPrice:
          double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      servicesIncluded: includedServices,
      serviceCount: json['service_count'] ?? 0,
      isPopular: json['is_popular'] ?? false,
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      bookingCount: json['booking_count'] ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// Enhanced BusinessInfo class
class BusinessInfo {
  final String contactNumber;
  final String email;
  final Map<String, String> operatingHours;
  final List<String> paymentMethods;
  final List<String> languages;
  final String parking;
  final String accessibility;

  BusinessInfo({
    required this.contactNumber,
    required this.email,
    required this.operatingHours,
    required this.paymentMethods,
    required this.languages,
    required this.parking,
    required this.accessibility,
  });

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    Map<String, String> hours = {};
    if (json['operating_hours'] != null) {
      final hoursData = json['operating_hours'] as Map<String, dynamic>;
      hoursData.forEach((key, value) {
        hours[key] = value?.toString() ?? '';
      });
    }

    return BusinessInfo(
      contactNumber: json['contact_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      operatingHours: hours,
      paymentMethods: List<String>.from(json['payment_methods'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      parking: json['parking']?.toString() ?? '',
      accessibility: json['accessibility']?.toString() ?? '',
    );
  }
}

// Enhanced PriceRange class
class PriceRange {
  final double min;
  final double max;
  final String currency;

  PriceRange({required this.min, required this.max, this.currency = 'KES'});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: double.tryParse(json['min']?.toString() ?? '0') ?? 0.0,
      max: double.tryParse(json['max']?.toString() ?? '0') ?? 0.0,
      currency: json['currency']?.toString() ?? 'KES',
    );
  }
}

class CarWash {
  final String id;
  final String name;
  final String imageUrl;
  final List<Service> services;
  final String location;
  final String openHours;
  final double latitude;
  final double longitude;

  // Enhanced properties from backend
  final String address;
  final String contactNumber;
  final String email;
  final List<LocationService> locationServices;
  final int totalServices;
  final PriceRange? priceRange;
  final List<LocationService> popularServices;
  final double? distance;
  final double averageRating;
  final int totalBookings;
  final double completionRate;
  final bool isOpen;
  final BusinessInfo? businessInfo;
  final List<String> features;
  final DateTime createdAt;
  final DateTime updatedAt;

  CarWash({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.services,
    required this.location,
    required this.openHours,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.contactNumber,
    required this.email,
    required this.locationServices,
    required this.totalServices,
    this.priceRange,
    required this.popularServices,
    this.distance,
    required this.averageRating,
    required this.totalBookings,
    required this.completionRate,
    required this.isOpen,
    this.businessInfo,
    required this.features,
    required this.createdAt,
    required this.updatedAt,
  });

  // Enhanced method specifically for comprehensive Django API response format
  factory CarWash.fromDjangoJson(Map<String, dynamic> json) {
    print('[DEBUG] CarWash.fromDjangoJson: Parsing comprehensive Django JSON');

    // Extract location services
    List<LocationService> locationServices = [];
    List<Service> allServices = [];
    if (json['location_services'] != null) {
      for (var serviceData in json['location_services']) {
        final locationService = LocationService.fromJson(serviceData);
        locationServices.add(locationService);

        // Also add to the main services list for backward compatibility
        allServices.add(
          Service(
            id: locationService.id,
            name: locationService.name,
            description: locationService.description,
            price: locationService.totalPrice,
          ),
        );

        // Add included services
        allServices.addAll(locationService.servicesIncluded);
      }
    }

    // Extract business info
    BusinessInfo? businessInfo;
    if (json['business_info'] != null) {
      businessInfo = BusinessInfo.fromJson(json['business_info']);
    }

    // Extract price range
    PriceRange? priceRange;
    if (json['price_range'] != null) {
      priceRange = PriceRange.fromJson(json['price_range']);
    }

    // Extract popular services
    List<LocationService> popularServices = [];
    if (json['popular_services'] != null) {
      for (var serviceData in json['popular_services']) {
        popularServices.add(LocationService.fromJson(serviceData));
      }
    }

    // Extract features
    List<String> features = [];
    if (json['features'] != null) {
      features = List<String>.from(json['features']);
    }

    // Determine primary operating hours
    String operatingHours = '8:00 AM - 6:00 PM'; // default
    if (businessInfo?.operatingHours.isNotEmpty == true) {
      // Use Monday's hours as primary, or first available
      operatingHours =
          businessInfo!.operatingHours['monday'] ??
          businessInfo.operatingHours.values.first;
    }

    return CarWash(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Car Wash',
      imageUrl:
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80',
      services: allServices,
      location: json['address']?.toString() ?? 'Unknown Location',
      openHours: operatingHours,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      locationServices: locationServices,
      totalServices: json['total_services'] ?? 0,
      priceRange: priceRange,
      popularServices: popularServices,
      distance: json['distance']?.toDouble(),
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      totalBookings: json['total_bookings'] ?? 0,
      completionRate:
          double.tryParse(json['completion_rate']?.toString() ?? '0') ?? 0.0,
      isOpen: json['is_open'] ?? true,
      businessInfo: businessInfo,
      features: features,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory CarWash.fromJson(Map<String, dynamic> json) {
    // Handle nested response structure
    print('[DEBUG] CarWash.fromJson: Parsing JSON: ${json.toString()}');

    // Extract services from available_services array
    List<Service> parsedServices = [];
    if (json['available_services'] != null) {
      final servicesList = json['available_services'] as List<dynamic>;
      for (var servicePackage in servicesList) {
        // Add the main service package
        parsedServices.add(Service.fromJson(servicePackage));

        // Add individual services from services_included if available
        if (servicePackage['services_included'] != null) {
          final includedServices =
              servicePackage['services_included'] as List<dynamic>;
          for (var includedService in includedServices) {
            parsedServices.add(Service.fromJson(includedService));
          }
        }
      }
    }

    // Extract operating hours (use first available day as primary hours)
    String operatingHours = '8:00 AM - 6:00 PM'; // default
    if (json['business_info']?['operating_hours'] != null) {
      final hours =
          json['business_info']['operating_hours'] as Map<String, dynamic>;
      if (hours.isNotEmpty) {
        operatingHours = hours.values.first?.toString() ?? operatingHours;
      }
    }

    return CarWash(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Car Wash',
      imageUrl:
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80', // Default image
      services: parsedServices,
      location: json['address']?.toString() ?? 'Unknown Location',
      openHours: operatingHours,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      locationServices: [],
      totalServices: parsedServices.length,
      priceRange: null,
      popularServices: [],
      distance: null,
      averageRating: 0.0,
      totalBookings: 0,
      completionRate: 0.0,
      isOpen: true,
      businessInfo: null,
      features: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'services': services.map((service) => service.toJson()).toList(),
      'location': location,
      'openHours': openHours,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
      'totalServices': totalServices,
      'averageRating': averageRating,
      'totalBookings': totalBookings,
      'completionRate': completionRate,
      'isOpen': isOpen,
      'features': features,
    };
  }
}

class Booking {
  final String id;
  final CarWash carWash;
  final Service service;
  final DateTime dateTime;
  final String paymentMethod;
  final int quantity;

  Booking({
    required this.id,
    required this.carWash,
    required this.service,
    required this.dateTime,
    required this.paymentMethod,
    this.quantity = 1,
  });
}
