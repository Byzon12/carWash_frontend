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

class CarWash {
  final String id;
  final String name;
  final String imageUrl;
  final List<Service> services;
  final String location;
  final String openHours;

  final double latitude;
  final double longitude;

  CarWash({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.services,
    required this.location,
    required this.openHours,
    required this.latitude,
    required this.longitude,
  });

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
