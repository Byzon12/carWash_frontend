import 'package:flutter/material.dart';
import '../models/cars.dart';
import 'booking_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final Service service;
  final CarWash carWash;

  const ServiceDetailsScreen({
    super.key,
    required this.service,
    required this.carWash,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(service.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.car_repair,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'at ${carWash.name}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'KSh ${service.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Service Details
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Section
                  const Text(
                    'Service Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      service.description.isNotEmpty
                          ? service.description
                          : 'Professional car wash service tailored to your vehicle\'s needs.',
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // What's Included Section
                  const Text(
                    'What\'s Included',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildIncludedServices(),

                  const SizedBox(height: 24),

                  // Duration and Additional Info
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.schedule,
                          'Duration',
                          _getEstimatedDuration(),
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.verified,
                          'Quality',
                          'Professional',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Location Info
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                      ),
                      title: Text(carWash.name),
                      subtitle: Text(carWash.location),
                      trailing: const Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Book Now Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          BookingScreen(service: service, carWash: carWash),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Book This Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncludedServices() {
    final List<String> defaultIncludes = _getDefaultIncludes();

    return Column(
      children:
          defaultIncludes.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  List<String> _getDefaultIncludes() {
    final serviceName = service.name.toLowerCase();

    if (serviceName.contains('exterior') || serviceName.contains('basic')) {
      return [
        'Exterior wash and rinse',
        'Tire and rim cleaning',
        'Window cleaning (exterior)',
        'Drying with clean towels',
      ];
    } else if (serviceName.contains('interior')) {
      return [
        'Vacuum cleaning',
        'Dashboard cleaning',
        'Seat cleaning',
        'Floor mat cleaning',
        'Window cleaning (interior)',
      ];
    } else if (serviceName.contains('full') ||
        serviceName.contains('detail') ||
        serviceName.contains('premium')) {
      return [
        'Complete exterior wash',
        'Full interior cleaning',
        'Tire and rim detailing',
        'Dashboard and console cleaning',
        'Seat deep cleaning',
        'Window cleaning (inside & out)',
        'Air freshener',
        'Final inspection',
      ];
    } else {
      return [
        'Professional car cleaning',
        'Quality service guarantee',
        'Experienced technicians',
        'Eco-friendly products',
      ];
    }
  }

  String _getEstimatedDuration() {
    final serviceName = service.name.toLowerCase();

    if (serviceName.contains('basic') || serviceName.contains('exterior')) {
      return '30-45 min';
    } else if (serviceName.contains('interior')) {
      return '45-60 min';
    } else if (serviceName.contains('full') ||
        serviceName.contains('detail') ||
        serviceName.contains('premium')) {
      return '90-120 min';
    } else {
      return '60 min';
    }
  }
}
