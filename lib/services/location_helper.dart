import 'package:flutter/material.dart';
import 'package:location/location.dart';

class LocationHelper {
  static final Location _location = Location();

  /// Shows a user-friendly dialog asking for location permissions
  /// Returns true if permissions are granted, false otherwise
  static Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        // Show dialog asking user to enable location service
        final shouldEnable = await _showLocationServiceDialog(context);
        if (!shouldEnable) return false;

        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          await _showLocationDeniedDialog(context);
          return false;
        }
      }

      // Check permission status
      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        // Show dialog explaining why we need location
        final shouldRequest = await _showLocationPermissionDialog(context);
        if (!shouldRequest) return false;

        permissionStatus = await _location.requestPermission();
        if (permissionStatus != PermissionStatus.granted) {
          await _showLocationDeniedDialog(context);
          return false;
        }
      }

      // Permission granted - get initial location
      final locationData = await _location.getLocation();
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Location enabled! Your position: ${locationData.latitude?.toStringAsFixed(3)}, ${locationData.longitude?.toStringAsFixed(3)}',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Location error: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Shows dialog explaining location service requirement
  static Future<bool> _showLocationServiceDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Enable Location Service'),
                ],
              ),
              content: const Text(
                'To show nearby car wash locations on the map, please enable your device\'s location service.\n\n'
                'This will help us:\n'
                '• Show your position on the map\n'
                '• Find the nearest car wash locations\n'
                '• Calculate distances to car washes',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enable Location'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Shows dialog explaining why location permission is needed
  static Future<bool> _showLocationPermissionDialog(
    BuildContext context,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.location_searching, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Location Permission'),
                ],
              ),
              content: const Text(
                'CarWash App needs location access to provide you with the best experience:\n\n'
                '✓ Show your current location on the map\n'
                '✓ Find car washes closest to you\n'
                '✓ Provide accurate directions\n'
                '✓ Calculate distances and travel times\n\n'
                'Your location data is only used within the app and never shared.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Grant Permission'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Shows dialog when location permission is denied
  static Future<void> _showLocationDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_disabled, color: Colors.red),
              SizedBox(width: 8),
              Text('Location Disabled'),
            ],
          ),
          content: const Text(
            'Location access was not granted. You can still use the app, but:\n\n'
            '• The map will show Kenya\'s general view\n'
            '• You won\'t see your current position\n'
            '• Distance calculations won\'t be available\n\n'
            'You can enable location later in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Get current location if permission is already granted
  static Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await _location.hasPermission();
      if (hasPermission == PermissionStatus.granted) {
        return await _location.getLocation();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    try {
      final serviceEnabled = await _location.serviceEnabled();
      final permissionStatus = await _location.hasPermission();
      return serviceEnabled && permissionStatus == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }
}
