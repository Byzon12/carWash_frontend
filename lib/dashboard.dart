import 'package:flutter/material.dart';
import 'models/cars.dart';
import 'page.dart';
import 'api/api_connect.dart';
import 'screens/location_details_screen.dart';
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
  bool _locationLoading = true;
  String? _locationError;
  Future<List<CarWash>>? _carWashesFuture;

  @override
  void initState() {
    super.initState();
    _carWashesFuture = carWashes(); // Load car washes from API
    _requestLocation();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi / 180
    final a =
        0.5 -
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
          // Don't treat as error - just continue without location
          setState(() {
            _userLocation = null;
            _locationLoading = false;
            _locationError = null;
          });
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          // Don't treat as error - just continue without location
          setState(() {
            _userLocation = null;
            _locationLoading = false;
            _locationError = null;
          });
          return;
        }
      }

      final userLoc = await location.getLocation();
      setState(() {
        _userLocation = userLoc;
        _locationLoading = false;
        _locationError = null;
      });
    } catch (e) {
      // If location fails, just continue without it instead of showing error
      setState(() {
        _userLocation = null;
        _locationLoading = false;
        _locationError = null;
      });
    }
  }

  List<CarWash> _getNearestCarWashes(List<CarWash> carWashList) {
    if (_userLocation == null) return carWashList;

    final userLat = _userLocation!.latitude!;
    final userLon = _userLocation!.longitude!;

    List<CarWash> sorted = List.from(carWashList);
    sorted.sort((a, b) {
      final distA = calculateDistance(
        userLat,
        userLon,
        a.latitude,
        a.longitude,
      );
      final distB = calculateDistance(
        userLat,
        userLon,
        b.latitude,
        b.longitude,
      );
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

      bool afterOpen =
          (now.hour > open.hour) ||
          (now.hour == open.hour && now.minute >= open.minute);
      bool beforeClose =
          (now.hour < close.hour) ||
          (now.hour == close.hour && now.minute <= close.minute);

      return afterOpen && beforeClose;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CarWash>>(
      future: _carWashesFuture,
      builder: (context, carWashSnapshot) {
        if (carWashSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading car wash locations...'),
              ],
            ),
          );
        }

        if (carWashSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading car washes: ${carWashSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _carWashesFuture = carWashes(); // Retry API call
                    });
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                // Debug button to test API directly
                ElevatedButton(
                  onPressed: () => _testApiDirectly(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Debug API'),
                ),
                const SizedBox(height: 8),
                // Button to test connectivity screen
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/connectivity-test');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Text('Full API Test'),
                ),
              ],
            ),
          );
        }

        final carWashList = carWashSnapshot.data ?? [];
        if (carWashList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_car_wash, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No car washes available at the moment'),
              ],
            ),
          );
        }

        final nearestCarWashes = _getNearestCarWashes(carWashList);

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
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Kenya_location_map.svg/800px-Kenya_location_map.svg.png',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: Colors.blue[200],
                        child: const Center(child: Icon(Icons.map)),
                      ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_pin, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    _locationLoading
                        ? 'Loading location...'
                        : _userLocation != null
                        ? 'Nearest car washes to you (${nearestCarWashes.length} found)'
                        : 'Car wash locations (${nearestCarWashes.length} found)',
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
                  final openStatus =
                      isOpenNow(carWash.openHours) ? 'Open now' : 'Closed';

                  // Calculate distance only if we have user location
                  String distanceText = '';
                  if (_userLocation != null && !_locationLoading) {
                    final distanceKm = calculateDistance(
                      _userLocation!.latitude!,
                      _userLocation!.longitude!,
                      carWash.latitude,
                      carWash.longitude,
                    );
                    distanceText = '${distanceKm.toStringAsFixed(2)} km away';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Image.network(
                        carWash.imageUrl,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              width: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.local_car_wash),
                            ),
                      ),
                      title: Text(carWash.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(carWash.location),
                          const SizedBox(height: 4),
                          Text(
                            'Open Hours: ${carWash.openHours}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            openStatus,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  openStatus == 'Open now'
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (distanceText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              distanceText,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${carWash.services.length} services available',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    LocationDetailsScreen(carWash: carWash),
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
      },
    );
  }

  // Debug method to test API connectivity directly
  Future<void> _testApiDirectly() async {
    print('[DEBUG] Dashboard: Testing API connectivity directly...');

    try {
      // Import the API connect to test directly
      final response = await ApiConnect.getLocations();

      if (response != null) {
        print('[DEBUG] Dashboard: API Response Status: ${response.statusCode}');
        print('[DEBUG] Dashboard: API Response Body: ${response.body}');

        if (mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('API Test Result'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status Code: ${response.statusCode}'),
                        const SizedBox(height: 8),
                        const Text('Response Body:'),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            response.body,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
          );
        }
      } else {
        print('[DEBUG] Dashboard: API Response is null');
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('API Test Result'),
                  content: const Text(
                    'API returned null response. Check backend connection.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      print('[DEBUG] Dashboard: API Test Exception: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('API Test Error'),
                content: Text('Exception: $e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    }
  }
}
