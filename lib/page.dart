import 'package:flutter_application_1/models/cars.dart';
import 'package:flutter_application_1/services/carwash_service.dart';

// Function to get car washes dynamically from API
Future<List<CarWash>> getCarWashes() async {
  print('[DEBUG] page.dart: Starting to fetch car washes from API...');
  return await CarWashService.fetchCarWashes();
}

// Legacy hardcoded data for reference/testing (can be removed later)
List<CarWash> getLegacyCarWashes() {
  print('[DEBUG] page.dart: Using legacy hardcoded car wash data');

  final List<Service> SparkleWashServices = [
    Service(
      id: '1',
      name: 'Exterior Car Washing',
      description: 'Thorough cleaning of the vehicle exterior.',
      price: 1500.0,
    ),
    Service(
      id: '2',
      name: 'Interior Vacuuming & Cleaning',
      description: 'Vacuum and clean interior surfaces.',
      price: 2500.0,
    ),
    Service(
      id: '3',
      name: 'Engine Cleaning',
      description: 'Degrease and clean engine bay.',
      price: 3500.0,
    ),
    Service(
      id: '4',
      name: 'Undercarriage Cleaning',
      description: 'Clean vehicle undercarriage.',
      price: 3000.0,
    ),
    Service(
      id: '5',
      name: 'Car Detailing',
      description: 'Complete interior and exterior detailing.',
      price: 1200.0,
    ),
    Service(
      id: '6',
      name: 'Air Purge (Dash & Console)',
      description: 'Clean and freshen air vents and dash.',
      price: 2000.0,
    ),
    Service(
      id: '7',
      name: 'Carpet Shampoo',
      description: 'Deep clean carpets and upholstery.',
      price: 3500.0,
    ),
    Service(
      id: '8',
      name: 'Seat & Upholstery Shampoo',
      description: 'Clean seats and upholstery fabrics.',
      price: 3500.0,
    ),
    Service(
      id: '9',
      name: 'Interior Detail',
      description: 'Detailed cleaning and conditioning of interior.',
      price: 180.0,
    ),
    Service(
      id: '10',
      name: 'Full Detail',
      description: 'Complete interior and exterior detail.',
      price: 2500.0,
    ),
    Service(
      id: '11',
      name: 'Mobile Car Wash',
      description: 'Car wash service at your location.',
      price: 1050.0,
    ),
    Service(
      id: '12',
      name: '24-Hour Car Wash',
      description: 'Car wash available 24/7.',
      price: 2000.0,
    ),
    Service(
      id: '14',
      name: 'Car Detailing',
      description: 'Complete interior and exterior detailing.',
      price: 1200.0,
    ),
  ];

  final List<Service> CleanRide = [
    Service(
      id: '1',
      name: 'Exterior Car Washing',
      description: 'Thorough cleaning of the vehicle exterior.',
      price: 1520.0,
    ),
    Service(
      id: '2',
      name: 'Interior Vacuuming & Cleaning',
      description: 'Vacuum and clean interior surfaces.',
      price: 5500.0,
    ),
    Service(
      id: '3',
      name: 'Engine Cleaning',
      description: 'Degrease and clean engine bay.',
      price: 4500.0,
    ),
    Service(
      id: '4',
      name: 'Undercarriage Cleaning',
      description: 'Clean vehicle undercarriage.',
      price: 5000.0,
    ),
    Service(
      id: '5',
      name: 'Car Detailing',
      description: 'Complete interior and exterior detailing.',
      price: 1200.0,
    ),
    Service(
      id: '6',
      name: 'Air Purge (Dash & Console)',
      description: 'Clean and freshen air vents and dash.',
      price: 2000.0,
    ),
    Service(
      id: '7',
      name: 'Carpet Shampoo',
      description: 'Deep clean carpets and upholstery.',
      price: 3500.0,
    ),
    Service(
      id: '8',
      name: 'Seat & Upholstery Shampoo',
      description: 'Clean seats and upholstery fabrics.',
      price: 3505.0,
    ),
    Service(
      id: '9',
      name: 'Interior Detail',
      description: 'Detailed cleaning and conditioning of interior.',
      price: 1180.0,
    ),
    Service(
      id: '10',
      name: 'Full Detail',
      description: 'Complete interior and exterior detail.',
      price: 2550.0,
    ),
    Service(
      id: '11',
      name: 'Mobile Car Wash',
      description: 'Car wash service at your location.',
      price: 3050.0,
    ),
    Service(
      id: '12',
      name: '24-Hour Car Wash',
      description: 'Car wash available 24/7.',
      price: 4000.0,
    ),
    Service(
      id: '14',
      name: 'Car Detailing',
      description: 'Complete interior and exterior detailing.',
      price: 3200.0,
    ),
  ];

  return [
    CarWash(
      id: '1',
      name: 'Sparkle Wash (Legacy)',
      imageUrl:
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80',
      services: SparkleWashServices,
      location: '123 Main Street, Downtown',
      openHours: '8:00 AM - 8:00 PM',
      latitude: -1.2921,
      longitude: 36.8219,
    ),
    CarWash(
      id: '2',
      name: 'CleanRide (Legacy)',
      imageUrl:
          'https://images.unsplash.com/photo-1549924231-f129b911e442?auto=format&fit=crop&w=800&q=80',
      services: CleanRide,
      location: '456 Elm Avenue, Uptown',
      openHours: '7:00 AM - 9:00 PM',
      latitude: -1.2833,
      longitude: 36.8167,
    ),
  ];
}

// Main function to get car washes from API (replaces the old carWashes list)
// Use this function throughout the app instead of the old hardcoded carWashes list
Future<List<CarWash>> carWashes() async {
  return await getCarWashes();
}

// Synchronous fallback for immediate access (use sparingly)
List<CarWash> carWashesSync() {
  return getLegacyCarWashes();
}
