import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/cars.dart';
import 'package:flutter_application_1/page.dart';
import 'package:flutter_application_1/service.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin;

class DashboardPage extends StatefulWidget {
  final Function(Booking) onBook;

  const DashboardPage({super.key, required this.onBook});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Location location = Location();
  LocationData? _userLocation;
  bool _loading = true;
  String? _error;

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // Distance in km
  }

  Future<void> _requestLocation() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _error = 'Location services are disabled.';
            _loading = false;
          });
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _error = 'Location permission denied.';
            _loading = false;
          });
          return;
        }
      }

      final userLoc = await location.getLocation();
      setState(() {
        _userLocation = userLoc;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _loading = false;
      });
    }
  }

  List<CarWash> _getNearestCarWashes() {
    if (_userLocation == null) return carWashes;

    final userLat = _userLocation!.latitude!;
    final userLon = _userLocation!.longitude!;

    List<CarWash> sorted = List.from(carWashes);
    sorted.sort((a, b) {
      final distA = calculateDistance(userLat, userLon, a.latitude, a.longitude);
      final distB = calculateDistance(userLat, userLon, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    return sorted;
  }

  bool isOpenNow(String openHours) {
    try {
      final parts = openHours.split(' - ');
      if (parts.length != 2) return false;

      TimeOfDay parseTime(String t) {
        final format = RegExp(r'(\d+):(\d+) (AM|PM)');
        final match = format.firstMatch(t);
        if (match == null) throw Exception('Invalid time format');
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        final ampm = match.group(3);
        if (ampm == 'PM' && hour != 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }

      final now = TimeOfDay.now();
      final open = parseTime(parts[0]);
      final close = parseTime(parts[1]);

      bool afterOpen = (now.hour > open.hour) || (now.hour == open.hour && now.minute >= open.minute);
      bool beforeClose = (now.hour < close.hour) || (now.hour == close.hour && now.minute <= close.minute);

      return afterOpen && beforeClose;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _requestLocation,
              child: const Text('Retry Location Permission'),
            ),
          ],
        ),
      );
    }

    final nearestCarWashes = _getNearestCarWashes();

    return Column(
      children: [
        Container(
          height: 150,
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Kenya_location_map.svg/800px-Kenya_location_map.svg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.blue[200], child: const Center(child: Icon(Icons.map))),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.location_pin, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Nearest car washes to you',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: nearestCarWashes.length,
            itemBuilder: (context, index) {
              final carWash = nearestCarWashes[index];
              final openStatus = isOpenNow(carWash.openHours) ? 'Open now' : 'Closed';
              final distanceKm = calculateDistance(
                _userLocation!.latitude!,
                _userLocation!.longitude!,
                carWash.latitude,
                carWash.longitude,
              );

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Image.network(carWash.imageUrl, width: 80, fit: BoxFit.cover),
                  title: Text(carWash.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(carWash.location),
                      const SizedBox(height: 4),
                      Text('Open Hours: ${carWash.openHours}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      Text(openStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: openStatus == 'Open now' ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 4),
                      Text('Distance: ${distanceKm.toStringAsFixed(2)} km', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServicesPage(carWash: carWash),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
