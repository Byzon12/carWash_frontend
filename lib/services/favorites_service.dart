import 'dart:convert';
import '../api/api_connect.dart';
import '../models/favorite_models.dart';

class FavoritesService {
  static const String _tag = 'FavoritesService';

  // Get all favorite locations
  static Future<FavoriteLocationResponse> getFavorites() async {
    try {
      print('[$_tag] Fetching user favorites...');

      final response = await ApiConnect.getFavoriteLocations();

      if (response == null) {
        print('[$_tag] No response from API');
        return FavoriteLocationResponse.error('Failed to connect to server');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[$_tag] Successfully fetched favorites');
        return FavoriteLocationResponse.fromJson(data);
      } else {
        print('[$_tag] Error fetching favorites: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return FavoriteLocationResponse.error(
          errorData['message'] ?? 'Failed to fetch favorites',
        );
      }
    } catch (e) {
      print('[$_tag] Exception fetching favorites: $e');
      return FavoriteLocationResponse.error('An error occurred: $e');
    }
  }

  // Add location to favorites
  static Future<bool> addToFavorites(String locationId) async {
    try {
      print('[$_tag] Adding location $locationId to favorites...');

      // First attempt: Use the ID as-is
      final response = await ApiConnect.addFavoriteLocation(
        locationId: locationId,
      );

      if (response == null) {
        print('[$_tag] No response from add favorite API');
        return false;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[$_tag] Successfully added location to favorites');
        return true;
      } else {
        print('[$_tag] Failed to add to favorites: ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          print('[$_tag] Error details: $errorData');

          // Check if it's a "Location not found" error
          final errorString = errorData.toString().toLowerCase();
          if (errorString.contains('doesnotexist') ||
              errorString.contains('location matching query does not exist') ||
              errorString.contains('not found')) {
            print(
              '[$_tag] Location ID mismatch detected - trying alternative approaches',
            );

            // TODO: Implement alternative ID mapping if backend provides it
            // For now, we'll inform the user about the issue
            return false;
          }
        } catch (e) {
          print('[$_tag] Could not parse error response');
        }
        return false;
      }
    } catch (e) {
      print('[$_tag] Exception adding to favorites: $e');
      return false;
    }
  }

  // Remove location from favorites
  static Future<bool> removeFromFavorites(String locationId) async {
    try {
      print('[$_tag] Removing location $locationId from favorites...');

      final response = await ApiConnect.removeFavoriteLocation(
        locationId: locationId,
      );

      if (response == null) {
        print('[$_tag] No response from remove favorite API');
        return false;
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[$_tag] Successfully removed location from favorites');
        return true;
      } else {
        print(
          '[$_tag] Failed to remove from favorites: ${response.statusCode}',
        );
        try {
          final errorData = jsonDecode(response.body);
          print('[$_tag] Error details: $errorData');
        } catch (e) {
          print('[$_tag] Could not parse error response');
        }
        return false;
      }
    } catch (e) {
      print('[$_tag] Exception removing from favorites: $e');
      return false;
    }
  }

  // Check if location is favorite
  static Future<bool> isLocationFavorite(String locationId) async {
    try {
      return await ApiConnect.isLocationFavorite(locationId: locationId);
    } catch (e) {
      print('[$_tag] Exception checking favorite status: $e');
      return false;
    }
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(String locationId) async {
    try {
      print('[$_tag] Toggling favorite status for location $locationId');
      return await ApiConnect.toggleFavoriteLocation(locationId: locationId);
    } catch (e) {
      print('[$_tag] Exception toggling favorite: $e');
      return false;
    }
  }

  // Get favorite locations as CarWash objects (if you want to integrate with existing CarWash model)
  static Future<List<String>> getFavoriteLocationIds() async {
    try {
      final favoritesResponse = await getFavorites();
      if (favoritesResponse.success) {
        return favoritesResponse.favorites
            .map((favorite) => favorite.locationId)
            .toList();
      }
      return [];
    } catch (e) {
      print('[$_tag] Exception getting favorite IDs: $e');
      return [];
    }
  }

  // Batch operations
  static Future<Map<String, bool>> addMultipleToFavorites(
    List<String> locationIds,
  ) async {
    Map<String, bool> results = {};

    for (String locationId in locationIds) {
      try {
        results[locationId] = await addToFavorites(locationId);
        // Add small delay to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('[$_tag] Error adding location $locationId: $e');
        results[locationId] = false;
      }
    }

    return results;
  }

  static Future<Map<String, bool>> removeMultipleFromFavorites(
    List<String> locationIds,
  ) async {
    Map<String, bool> results = {};

    for (String locationId in locationIds) {
      try {
        results[locationId] = await removeFromFavorites(locationId);
        // Add small delay to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('[$_tag] Error removing location $locationId: $e');
        results[locationId] = false;
      }
    }

    return results;
  }
}
