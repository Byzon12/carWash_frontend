class FavoriteLocation {
  final String id;
  final String locationId;
  final String locationName;
  final String locationAddress;
  final double? latitude;
  final double? longitude;
  final DateTime dateAdded;
  final Map<String, dynamic>? locationDetails;

  FavoriteLocation({
    required this.id,
    required this.locationId,
    required this.locationName,
    required this.locationAddress,
    this.latitude,
    this.longitude,
    required this.dateAdded,
    this.locationDetails,
  });

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) {
    return FavoriteLocation(
      id: json['id']?.toString() ?? '',
      locationId:
          json['location_id']?.toString() ?? json['location']?.toString() ?? '',
      locationName:
          json['location_name']?.toString() ??
          json['name']?.toString() ??
          'Unknown Location',
      locationAddress:
          json['location_address']?.toString() ??
          json['address']?.toString() ??
          'Address not available',
      latitude:
          json['latitude'] != null
              ? double.tryParse(json['latitude'].toString())
              : null,
      longitude:
          json['longitude'] != null
              ? double.tryParse(json['longitude'].toString())
              : null,
      dateAdded:
          json['date_added'] != null
              ? DateTime.tryParse(json['date_added'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      locationDetails: json['location_details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_id': locationId,
      'location_name': locationName,
      'location_address': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'date_added': dateAdded.toIso8601String(),
      'location_details': locationDetails,
    };
  }

  @override
  String toString() {
    return 'FavoriteLocation(id: $id, locationId: $locationId, name: $locationName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteLocation && other.locationId == locationId;
  }

  @override
  int get hashCode => locationId.hashCode;
}

class FavoriteLocationResponse {
  final bool success;
  final String message;
  final List<FavoriteLocation> favorites;
  final int totalCount;

  FavoriteLocationResponse({
    required this.success,
    required this.message,
    required this.favorites,
    required this.totalCount,
  });

  factory FavoriteLocationResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> favoritesData = [];

    // Handle different response formats
    if (json['data'] is List) {
      favoritesData = json['data'];
    } else if (json['favorites'] is List) {
      favoritesData = json['favorites'];
    } else if (json['results'] is List) {
      favoritesData = json['results'];
    }

    List<FavoriteLocation> favoritesList =
        favoritesData
            .map(
              (item) => FavoriteLocation.fromJson(item as Map<String, dynamic>),
            )
            .toList();

    return FavoriteLocationResponse(
      success: json['success'] ?? true,
      message:
          json['message']?.toString() ??
          (favoritesList.isNotEmpty
              ? 'Favorites loaded successfully'
              : 'No favorites found'),
      favorites: favoritesList,
      totalCount: favoritesList.length,
    );
  }

  static FavoriteLocationResponse fromHttpResponse(Map<String, dynamic> json) {
    return FavoriteLocationResponse.fromJson(json);
  }

  static FavoriteLocationResponse empty() {
    return FavoriteLocationResponse(
      success: true,
      message: 'No favorites found',
      favorites: [],
      totalCount: 0,
    );
  }

  static FavoriteLocationResponse error(String errorMessage) {
    return FavoriteLocationResponse(
      success: false,
      message: errorMessage,
      favorites: [],
      totalCount: 0,
    );
  }
}

class AddFavoriteRequest {
  final String locationId;

  AddFavoriteRequest({required this.locationId});

  Map<String, dynamic> toJson() {
    return {'location_id': locationId};
  }
}

class RemoveFavoriteRequest {
  final String locationId;

  RemoveFavoriteRequest({required this.locationId});

  Map<String, dynamic> toJson() {
    return {'location_id': locationId};
  }
}
