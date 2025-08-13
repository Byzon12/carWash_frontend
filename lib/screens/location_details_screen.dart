import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cars.dart';
import '../services/favorites_service.dart';
import 'service_details_screen.dart';

class LocationDetailsScreen extends StatefulWidget {
  final CarWash carWash;

  const LocationDetailsScreen({super.key, required this.carWash});

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      setState(() => _isLoadingFavorite = true);
      final isFavorite = await FavoritesService.isLocationFavorite(
        widget.carWash.id.toString(),
      );
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    try {
      setState(() => _isTogglingFavorite = true);

      // Debug the location ID we're sending
      final locationId = widget.carWash.id.toString();final success = await FavoritesService.toggleFavorite(locationId);

      if (mounted) {
        if (success) {
          setState(() {
            _isFavorite = !_isFavorite;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isFavorite ? 'Added to favorites!' : 'Removed from favorites!',
              ),
              backgroundColor: _isFavorite ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Show specific error message based on the problem
          String errorMessage = 'Failed to update favorites. Please try again.';

          // Check if it's a location ID mismatch issue
          if (locationId.isEmpty) {
            errorMessage =
                'Invalid location data. Please refresh and try again.';
          } else {
            errorMessage =
                'This location is not available for favorites. Please contact support.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Favorites Error'),
                          content: Text(
                            'Location ID: $locationId\n'
                            'Location Name: ${widget.carWash.name}\n\n'
                            'This location may not be configured for favorites in the system. '
                            'Please contact support if this issue persists.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ),
          );
        }
        setState(() => _isTogglingFavorite = false);
      }
    } catch (e) {if (mounted) {
        setState(() => _isTogglingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.carWash.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isLoadingFavorite
              ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
              : IconButton(
                icon:
                    _isTogglingFavorite
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Icon(
                          _isFavorite ? Icons.star : Icons.star_border,
                          color: _isFavorite ? Colors.yellow : Colors.white,
                        ),
                onPressed: _isTogglingFavorite ? null : _toggleFavorite,
                tooltip:
                    _isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image with Status
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.carWash.imageUrl),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Status badges
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Column(
                        children: [
                          if (widget.carWash.isOpen)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'OPEN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (widget.carWash.averageRating > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.carWash.averageRating
                                        .toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Title and location
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.carWash.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.carWash.address.isNotEmpty
                                      ? widget.carWash.address
                                      : widget.carWash.location,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.carWash.distance != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_walk,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.carWash.distance!.toStringAsFixed(2)} km away',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Stats
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Services',
                      '${widget.carWash.totalServices}',
                      Icons.local_car_wash,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Bookings',
                      '${widget.carWash.totalBookings}',
                      Icons.calendar_today,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Rating',
                      widget.carWash.averageRating > 0
                          ? widget.carWash.averageRating.toStringAsFixed(1)
                          : 'New',
                      Icons.star,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Business Information Section
            if (widget.carWash.businessInfo != null) ...[
              _buildSectionHeader('Business Information', Icons.business),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    if (widget.carWash.businessInfo!.contactNumber.isNotEmpty)
                      _buildInfoTile(
                        'Phone',
                        widget.carWash.businessInfo!.contactNumber,
                        Icons.phone,
                        onTap:
                            () => _makePhoneCall(
                              widget.carWash.businessInfo!.contactNumber,
                            ),
                      ),
                    if (widget.carWash.businessInfo!.email.isNotEmpty)
                      _buildInfoTile(
                        'Email',
                        widget.carWash.businessInfo!.email,
                        Icons.email,
                        onTap:
                            () =>
                                _sendEmail(widget.carWash.businessInfo!.email),
                      ),
                    if (widget.carWash.businessInfo!.parking.isNotEmpty)
                      _buildInfoTile(
                        'Parking',
                        widget.carWash.businessInfo!.parking,
                        Icons.local_parking,
                      ),
                    if (widget.carWash.businessInfo!.accessibility.isNotEmpty)
                      _buildInfoTile(
                        'Accessibility',
                        widget.carWash.businessInfo!.accessibility,
                        Icons.accessible,
                      ),
                  ],
                ),
              ),
            ],

            // Operating Hours Section
            if (widget.carWash.businessInfo?.operatingHours.isNotEmpty ==
                true) ...[
              _buildSectionHeader('Operating Hours', Icons.access_time),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children:
                          widget.carWash.businessInfo!.operatingHours.entries
                              .map((entry) {
                                final isToday = _isToday(entry.key);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          _capitalizeDayName(entry.key),
                                          style: TextStyle(
                                            fontWeight:
                                                isToday
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color:
                                                isToday
                                                    ? Colors.blue
                                                    : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: TextStyle(
                                            fontWeight:
                                                isToday
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color:
                                                isToday
                                                    ? Colors.blue
                                                    : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isToday)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                widget.carWash.isOpen
                                                    ? Colors.green
                                                    : Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            widget.carWash.isOpen
                                                ? 'Open'
                                                : 'Closed',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              })
                              .toList(),
                    ),
                  ),
                ),
              ),
            ],

            // Payment Methods Section
            if (widget.carWash.businessInfo?.paymentMethods.isNotEmpty ==
                true) ...[
              _buildSectionHeader('Payment Methods', Icons.payment),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.carWash.businessInfo!.paymentMethods.map((
                            method,
                          ) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPaymentIcon(method),
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    method,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ],

            // Features Section
            if (widget.carWash.features.isNotEmpty) ...[
              _buildSectionHeader('Amenities & Features', Icons.star_outline),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.carWash.features.map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getFeatureIcon(feature),
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    feature,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ],

            // Price Range Section
            if (widget.carWash.priceRange != null) ...[
              _buildSectionHeader('Price Range', Icons.monetization_on),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.monetization_on,
                      color: Colors.green,
                    ),
                    title: const Text('Service Prices'),
                    subtitle: Text(
                      '${widget.carWash.priceRange!.currency} ${widget.carWash.priceRange!.min.toStringAsFixed(0)} - ${widget.carWash.priceRange!.max.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Available Services Section
            _buildSectionHeader(
              'Available Services (${widget.carWash.locationServices.length})',
              Icons.local_car_wash,
            ),

            if (widget.carWash.locationServices.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No services available at this location',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children:
                      widget.carWash.locationServices.map((locationService) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              // Convert LocationService to Service for navigation
                              final service = Service(
                                id: locationService.id,
                                name: locationService.name,
                                description: locationService.description,
                                price: locationService.totalPrice,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ServiceDetailsScreen(
                                        service: service,
                                        carWash: widget.carWash,
                                      ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.car_repair,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    locationService.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                if (locationService.isPopular)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'POPULAR',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              locationService.description,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Service details row
                                  Row(
                                    children: [
                                      if (locationService
                                          .duration
                                          .isNotEmpty) ...[
                                        Icon(
                                          Icons.schedule,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          locationService.duration,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                      Icon(
                                        Icons.list_alt,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${locationService.serviceCount} services included',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'KSh ${locationService.totalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Services included section
                                  if (locationService
                                      .servicesIncluded
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Services Included:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...locationService.servicesIncluded.map((
                                            service,
                                          ) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          top: 6,
                                                        ),
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            3,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                service.name,
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              'KSh ${service.price.toStringAsFixed(0)}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors
                                                                        .green
                                                                        .shade600,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (service
                                                            .description
                                                            .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            service.description,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Rating and booking info
                                  if (locationService.averageRating > 0 ||
                                      locationService.bookingCount > 0) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (locationService.averageRating >
                                            0) ...[
                                          Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            locationService.averageRating
                                                .toStringAsFixed(1),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        if (locationService.bookingCount >
                                            0) ...[
                                          Text(
                                            '(${locationService.bookingCount} ${locationService.bookingCount == 1 ? 'booking' : 'bookings'})',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),

      // Enhanced Bottom Action Bar
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
        child: Row(
          children: [
            if (widget.carWash.businessInfo?.contactNumber.isNotEmpty == true)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      () => _makePhoneCall(
                        widget.carWash.businessInfo!.contactNumber,
                      ),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (widget.carWash.businessInfo?.contactNumber.isNotEmpty == true)
              const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openDirections(),
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        subtitle: Text(value),
        trailing:
            onTap != null
                ? const Icon(Icons.arrow_forward_ios, size: 16)
                : null,
        onTap: onTap,
      ),
    );
  }

  bool _isToday(String dayName) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final todayName = dayNames[weekday - 1];
    return dayName.toLowerCase() == todayName;
  }

  String _capitalizeDayName(String dayName) {
    return dayName[0].toUpperCase() + dayName.substring(1);
  }

  IconData _getPaymentIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'm-pesa':
      case 'mpesa':
        return Icons.phone_android;
      case 'credit card':
      case 'visa':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  IconData _getFeatureIcon(String feature) {
    switch (feature.toLowerCase()) {
      case 'free wifi':
        return Icons.wifi;
      case 'comfortable waiting area':
        return Icons.chair;
      case 'restrooms':
        return Icons.wc;
      case 'coffee/tea service':
        return Icons.coffee;
      case 'air conditioning':
        return Icons.ac_unit;
      case 'cctv security':
        return Icons.security;
      case 'covered parking':
        return Icons.local_parking;
      case 'mobile payment':
        return Icons.mobile_friendly;
      default:
        return Icons.check_circle;
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    // Clean the phone number (remove spaces, dashes, etc.)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri.parse('tel:$cleanNumber');

    try {if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);} else {if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to make phone call. Please check if you have a phone app installed.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making phone call: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _sendEmail(String email) async {
    final Uri emailUri = Uri.parse('mailto:$email');

    try {if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);} else {if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to open email app. Please check if you have an email app installed.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _openDirections() async {
    final double lat = widget.carWash.latitude;
    final double lng = widget.carWash.longitude;
    final String carWashName = widget.carWash.name;// Try Google Maps first (most common), then Apple Maps, then fallback to web
    final List<String> mapUrls = [
      // Google Maps app (Android/iOS)
      'google.navigation:q=$lat,$lng',
      // Apple Maps (iOS)
      'maps://maps.apple.com/?daddr=$lat,$lng&dirflg=d',
      // Google Maps web version (universal fallback)
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    ];

    bool launched = false;

    for (String urlString in mapUrls) {
      try {
        final Uri mapUri = Uri.parse(urlString);

        if (await canLaunchUrl(mapUri)) {
          await launchUrl(
            mapUri,
            mode:
                urlString.startsWith('http')
                    ? LaunchMode.externalApplication
                    : LaunchMode.externalNonBrowserApplication,
          );
          launched = true;break;
        }
      } catch (e) {continue;
      }
    }

    if (!launched) {if (mounted) {
        // Show dialog with manual coordinates as fallback
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Directions'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unable to open maps app. Here are the coordinates:',
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Location: $carWashName\nLatitude: $lat\nLongitude: $lng',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You can copy these coordinates to your preferred maps app.',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () async {
                    // Try to open web version as last resort
                    final webUrl =
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                    final Uri webUri = Uri.parse(webUrl);

                    try {
                      await launchUrl(
                        webUri,
                        mode: LaunchMode.externalApplication,
                      );
                      Navigator.of(context).pop();
                    } catch (e) {}
                  },
                  child: const Text('Open in Browser'),
                ),
              ],
            );
          },
        );
      }
    }
  }
}
