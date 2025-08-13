import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  bool _mapLoading = true;
  Future<List<CarWash>>? _carWashesFuture;
  GoogleMapController? _mapController;

  // Kenya center coordinates
  static const LatLng _kenyaCenter = LatLng(-0.0236, 37.9062);

  @override
  void initState() {
    super.initState();
    // Print network setup instructions for wireless debugging
    ApiConnect.printNetworkInstructions();
    // Test connectivity immediately
    _testConnectivityOnStart();
    _carWashesFuture = carWashes(); // Load car washes from API
    // Request location with a small delay to let the UI load first
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _requestLocation();
      }
    });
  }

  // Test connectivity when the app starts
  Future<void> _testConnectivityOnStart() async {final isConnected = await ApiConnect.testConnectivity();
    if (isConnected) {} else {}
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
        // Show user-friendly dialog for enabling location service
        final shouldEnable = await _showLocationDialog(
          'Enable Location Service',
          'To show your location on the map and find nearby car washes, please enable location service on your device.',
          'Enable Location',
        );

        if (shouldEnable) {
          serviceEnabled = await location.requestService();
        }

        if (!serviceEnabled) {
          setState(() {
            _userLocation = null;
            _locationLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Location service disabled. You can still browse car washes.',
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        // Show user-friendly dialog for location permission
        final shouldRequest = await _showLocationDialog(
          'Location Permission Required',
          'Would you like to enable location access? This will help us:\n\n• Show your position on the map\n• Find nearest car washes\n• Calculate distances\n\nYour location is only used within the app and never shared.',
          'Grant Permission',
        );

        if (shouldRequest) {
          permissionGranted = await location.requestPermission();
        }

        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _userLocation = null;
            _locationLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Location access denied. You can still browse car washes.',
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      final userLoc = await location.getLocation();
      setState(() {
        _userLocation = userLoc;
        _locationLoading = false;
      });

      // Center map on user location after getting it
      if (_mapController != null &&
          userLoc.latitude != null &&
          userLoc.longitude != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(userLoc.latitude!, userLoc.longitude!),
              zoom: 12.0,
            ),
          ),
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Location enabled! Your position: ${userLoc.latitude?.toStringAsFixed(3)}, ${userLoc.longitude?.toStringAsFixed(3)}',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _userLocation = null;
        _locationLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error getting location: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<bool> _showLocationDialog(
    String title,
    String content,
    String actionText,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.location_searching, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(content),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can change this later in your device settings.',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(actionText),
                ),
              ],
            );
          },
        ) ??
        false;
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

  Set<Marker> _createCarWashMarkers(List<CarWash> carWashes) {
    Set<Marker> markers =
        carWashes.map((carWash) {
          return Marker(
            markerId: MarkerId(carWash.id),
            position: LatLng(carWash.latitude, carWash.longitude),
            infoWindow: InfoWindow(
              title: carWash.name,
              snippet: '${carWash.services.length} services available',
              onTap: () {
                // Navigate to car wash details when marker is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => LocationDetailsScreen(carWash: carWash),
                  ),
                );
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          );
        }).toSet();

    // Add user location marker if available
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_userLocation!.latitude!, _userLocation!.longitude!),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    return markers;
  }

  void _centerMapOnUser() async {
    if (_mapController != null && _userLocation != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_userLocation!.latitude!, _userLocation!.longitude!),
            zoom: 12.0,
          ),
        ),
      );
    }
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
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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
        final nearestCarWashes = _getNearestCarWashes(carWashList);

        // Always show the map, regardless of car wash data
        return Scaffold(
          body: Column(
            children: [
              // Google Maps section - always visible
              Container(
                height: 200, // Increased height for better map view
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Google Maps Widget
                      GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;setState(() {
                            _mapLoading = false;
                          });
                          // If we already have user location, center on it
                          if (_userLocation != null) {
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                _centerMapOnUser();
                              },
                            );
                          }
                        },
                        initialCameraPosition: CameraPosition(
                          target:
                              _userLocation != null
                                  ? LatLng(
                                    _userLocation!.latitude!,
                                    _userLocation!.longitude!,
                                  )
                                  : _kenyaCenter,
                          zoom: _userLocation != null ? 12.0 : 6.0,
                        ),
                        markers: _createCarWashMarkers(nearestCarWashes),
                        mapType: MapType.normal,
                        zoomGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        myLocationEnabled: _userLocation != null,
                        myLocationButtonEnabled:
                            false, // We'll use our custom button
                        compassEnabled: true,
                        mapToolbarEnabled: false,
                      ),

                      // Overlay to show map status
                      if (_mapLoading)
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.blue.shade50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map,
                                size: 48,
                                color: Colors.blue.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading Map...',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kenya Car Wash Locations',
                                style: TextStyle(
                                  color: Colors.blue.shade400,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Location status section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      _userLocation != null
                          ? Icons.location_on
                          : _locationLoading
                          ? Icons.location_searching
                          : Icons.location_off,
                      color:
                          _userLocation != null
                              ? Colors.green
                              : _locationLoading
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationLoading
                            ? 'Getting your location...'
                            : _userLocation != null
                            ? 'Showing ${nearestCarWashes.length} car washes near you'
                            : carWashList.isEmpty
                            ? 'Loading car wash locations...'
                            : 'Showing ${nearestCarWashes.length} car washes in Kenya (enable location to see distances)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              _userLocation != null
                                  ? Colors.green[700]
                                  : _locationLoading
                                  ? Colors.orange[700]
                                  : Colors.blue[700],
                        ),
                      ),
                    ),
                    if (!_locationLoading && _userLocation == null)
                      TextButton(
                        onPressed: _requestLocation,
                        child: const Text(
                          'Enable',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

              // Car wash list section
              Expanded(
                child:
                    carWashList.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.local_car_wash,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No car washes available at the moment',
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _carWashesFuture =
                                        carWashes(); // Retry API call
                                  });
                                },
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: nearestCarWashes.length,
                          itemBuilder: (context, index) {
                            final carWash = nearestCarWashes[index];
                            final openStatus =
                                isOpenNow(carWash.openHours)
                                    ? 'Open now'
                                    : 'Closed';

                            // Calculate distance only if we have user location
                            String distanceText = '';
                            if (_userLocation != null && !_locationLoading) {
                              final distanceKm = calculateDistance(
                                _userLocation!.latitude!,
                                _userLocation!.longitude!,
                                carWash.latitude,
                                carWash.longitude,
                              );
                              distanceText =
                                  '${distanceKm.toStringAsFixed(2)} km away';
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
                                          (context) => LocationDetailsScreen(
                                            carWash: carWash,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
          floatingActionButton:
              _userLocation != null
                  ? FloatingActionButton(
                    onPressed: _centerMapOnUser,
                    backgroundColor: Colors.blue,
                    tooltip: 'Center map on your location',
                    child: const Icon(Icons.my_location, color: Colors.white),
                  )
                  : !_locationLoading
                  ? FloatingActionButton.extended(
                    onPressed: _requestLocation,
                    backgroundColor: Colors.green,
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    label: const Text(
                      'Enable Location',
                      style: TextStyle(color: Colors.white),
                    ),
                    tooltip: 'Enable location to see your position on the map',
                  )
                  : FloatingActionButton(
                    onPressed: null,
                    backgroundColor: Colors.grey,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
        );
      },
    );
  }

  // Debug method to test API connectivity directly
  Future<void> _testApiDirectly() async {try {
      // Import the API connect to test directly
      final response = await ApiConnect.getLocations();

      if (response != null) {if (mounted) {
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
      } else {if (mounted) {
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
    } catch (e) {if (mounted) {
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
