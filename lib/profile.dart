import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../utilites/provider.dart';
import '../models/cars.dart';
import '../api/api_connect.dart';
import '../screens/loyalty_points_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required List<Booking> bookings});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userProfile;
  bool _loading = true;
  bool _isEditing = false;

  // Booking history state
  List<Booking> _bookingHistory = [];
  bool _bookingHistoryLoading = false;
  String? _bookingHistoryError;

  // Controllers for editable fields
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneNumberController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserProfile();
    _loadLoyaltyPoints(); // Load loyalty points when page initializes
    _loadBookingHistory(); // Load booking history from API
  }

  void _initializeControllers() {
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile([bool showLoading = true]) async {
    try {
      if (showLoading) {
        setState(() => _loading = true);
      }

      // Try to get profile from API first
      final response = await ApiConnect.getUserProfile();

      if (response != null && response.statusCode == 200) {
        final profile = jsonDecode(response.body);

        setState(() {
          _userProfile = profile;
          _updateControllers();
        });

        // Also load loyalty points only during full refresh
        if (showLoading) {
          await _loadLoyaltyPoints();
        }
      } else {
        // Fallback to stored user data
        await _loadStoredUserData();
      }
    } catch (e, stackTrace) {
      // Show user-friendly error message only during full refresh
      if (mounted && showLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load profile from server. Using cached data.',
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(label: 'Retry', onPressed: _loadUserProfile),
          ),
        );
      }

      // Fallback to stored user data
      await _loadStoredUserData();
    } finally {
      if (showLoading) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadStoredUserData() async {
    try {
      // Load from secure storage
      final email = await ApiConnect.storage.read(key: 'email');
      final firstName = await ApiConnect.storage.read(key: 'first_name');
      final lastName = await ApiConnect.storage.read(key: 'last_name');
      final username = await ApiConnect.storage.read(key: 'username');
      final address = await ApiConnect.storage.read(key: 'address');
      final phoneNumber = await ApiConnect.storage.read(key: 'phone_number');
      setState(() {
        _userProfile = {
          'email': email ?? 'user@example.com',
          'first_name': firstName ?? 'User',
          'last_name': lastName ?? '',
          'username': username ?? 'user',
          'address': address ?? '',
          'phone_number': phoneNumber ?? '',
          'loyalty_points': 0, // Default value
        };
        _updateControllers();
      });
    } catch (e, stackTrace) {
      // Set default values if storage fails
      setState(() {
        _userProfile = {
          'email': 'user@example.com',
          'first_name': 'User',
          'last_name': '',
          'username': 'user',
          'address': '',
          'phone_number': '',
          'loyalty_points': 0,
        };
        _updateControllers();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not load stored profile data. Using defaults.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _updateControllers() {
    try {
      if (_userProfile != null) {
        _usernameController.text = _userProfile!['username'] ?? '';
        _emailController.text = _userProfile!['email'] ?? '';
        _firstNameController.text = _userProfile!['first_name'] ?? '';
        _lastNameController.text = _userProfile!['last_name'] ?? '';
        _addressController.text = _userProfile!['address'] ?? '';
        _phoneNumberController.text = _userProfile!['phone_number'] ?? '';
      } else {}
    } catch (e, stackTrace) {}
  }

  void _navigateToLoyaltyDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoyaltyPointsScreen()),
    );
  }

  Future<void> _loadLoyaltyPoints() async {
    try {
      final response = await ApiConnect.getLoyaltyDashboard();

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final loyaltyStats = data['data']['loyalty_stats'];
          setState(() {
            _userProfile ??= {};
            _userProfile!['loyalty_points'] = loyaltyStats['current_points'];
          });
        }
      } else {}
    } catch (e) {}
  }

  // Load booking history from API
  Future<void> _loadBookingHistory() async {
    try {
      setState(() {
        _bookingHistoryLoading = true;
        _bookingHistoryError = null;
      });

      final response = await ApiConnect.getUserBookingHistory();

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // If response is directly a list of bookings
          _parseBookingHistory(data);
        } else if (data['success'] == true && data['data'] != null) {
          // If response has success wrapper
          _parseBookingHistory(data['data']);
        } else if (data['bookings'] != null) {
          // If response has bookings key
          _parseBookingHistory(data['bookings']);
        } else {
          // Try to parse the whole response as bookings
          _parseBookingHistory([data]);
        }
      } else {
        setState(() {
          _bookingHistoryError =
              'Failed to load booking history: ${response?.statusCode ?? 'No response'}';
          _bookingHistoryLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _bookingHistoryError = 'Error loading booking history: $e';
        _bookingHistoryLoading = false;
      });
    }
  }

  // Parse booking history data and convert to Booking objects
  void _parseBookingHistory(dynamic bookingsData) {
    try {
      final List<Booking> parsedBookings = [];

      if (bookingsData is List) {
        for (final bookingData in bookingsData) {
          try {
            // Create a Booking object from the API data
            // Note: You may need to adjust these fields based on your actual API response
            final booking = Booking(
              id: bookingData['id']?.toString() ?? '',
              carWash: CarWash(
                id: bookingData['carwash_id']?.toString() ?? '',
                name: bookingData['carwash_name'] ?? 'Unknown Car Wash',
                imageUrl: bookingData['carwash_image'] ?? '',
                services: [],
                location: bookingData['carwash_location'] ?? '',
                openHours: '',
                latitude: 0.0,
                longitude: 0.0,
                address: bookingData['carwash_address'] ?? '',
                contactNumber: '',
                email: '',
                locationServices: [],
                totalServices: 0,
                popularServices: [],
                averageRating: 0.0,
                totalBookings: 0,
                completionRate: 0.0,
                isOpen: false,
                features: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              service: Service(
                id: bookingData['service_id']?.toString() ?? '',
                name: bookingData['service_name'] ?? 'Unknown Service',
                description: bookingData['service_description'] ?? '',
                price:
                    double.tryParse(
                      bookingData['service_price']?.toString() ?? '0',
                    ) ??
                    0.0,
              ),
              dateTime:
                  DateTime.tryParse(bookingData['booking_date'] ?? '') ??
                  DateTime.now(),
              paymentMethod: bookingData['payment_method'] ?? 'Unknown',
              quantity:
                  int.tryParse(bookingData['quantity']?.toString() ?? '1') ?? 1,
            );
            parsedBookings.add(booking);
          } catch (e) {}
        }
      }

      setState(() {
        _bookingHistory = parsedBookings;
        _bookingHistoryLoading = false;
        _bookingHistoryError = null;
      });
    } catch (e) {
      setState(() {
        _bookingHistoryError = 'Error parsing booking history: $e';
        _bookingHistoryLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use API-loaded booking history instead of provider bookings
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Refresh profile data button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadUserProfile();
            },
            tooltip: 'Refresh Profile',
          ),
          // Password change button in top corner
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              _showChangePasswordDialog();
            },
            tooltip: 'Change Password',
          ),
          // Logout button moved to top corner
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                _saveProfile();
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildUserInfo(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    _buildBookingHistorySection(_bookingHistory),
                  ],
                ),
              ),
    );
  }

  Widget _buildUserInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture and Basic Info
            Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/avatar_placeholder.png'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing) ...[
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ] else ...[
                        Text(
                          _userProfile?['username'] ?? 'Username',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade200,
                                Colors.orange.shade300,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade300.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _navigateToLoyaltyDashboard(),
                            borderRadius: BorderRadius.circular(15),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🏆',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_userProfile?['loyalty_points'] ?? 0} Loyalty Points',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Profile Details
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            if (_isEditing) ...[
              // Edit Mode - Form Fields
              _buildEditField('First Name', _firstNameController, Icons.person),
              const SizedBox(height: 12),
              _buildEditField('Last Name', _lastNameController, Icons.person),
              const SizedBox(height: 12),
              _buildEditField('Email', _emailController, Icons.email),
              const SizedBox(height: 12),
              _buildEditField('Address', _addressController, Icons.location_on),
              const SizedBox(height: 12),
              _buildEditField(
                'Phone Number',
                _phoneNumberController,
                Icons.phone,
              ),
            ] else ...[
              // View Mode - Display Fields
              _buildInfoRow(
                'First Name',
                _userProfile?['first_name'] ?? '-',
                Icons.person,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Last Name',
                _userProfile?['last_name'] ?? '-',
                Icons.person,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Email',
                _userProfile?['email'] ?? '-',
                Icons.email,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Address',
                _userProfile?['address'] ?? '-',
                Icons.location_on,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Phone Number',
                _userProfile?['phone_number'] ?? '-',
                Icons.phone,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue.shade600),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Center(
      child: SizedBox(
        width: 200, // Width for edit button
        child:
            !_isEditing
                ? ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isEditing = true);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )
                : const SizedBox.shrink(), // Hide when editing (save/cancel are in AppBar)
      ),
    );
  }

  Widget _buildBookingHistorySection(List<Booking> bookings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Booking History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBookingHistory,
              tooltip: 'Refresh booking history',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildBookingHistory(bookings),
      ],
    );
  }

  Widget _buildBookingHistory(List<Booking> bookings) {
    // Show loading state
    if (_bookingHistoryLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Loading booking history...'),
              ],
            ),
          ),
        ),
      );
    }

    // Show error state
    if (_bookingHistoryError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Error loading booking history',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _bookingHistoryError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadBookingHistory,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show empty state
    if (bookings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, color: Colors.grey, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'No bookings yet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your booking history will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show booking list
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.local_car_wash, color: Colors.blue.shade600),
            ),
            title: Text(
              '${booking.carWash.name} - ${booking.service.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMMMd().add_jm().format(booking.dateTime),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.payment, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      booking.paymentMethod,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.numbers, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Quantity: ${booking.quantity}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '\$${booking.service.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showBookingOptions(context, booking),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    try {
      // Validate required fields
      if (_usernameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username cannot be empty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_emailController.text.trim().isEmpty ||
          !_emailController.text.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Call the API to update the profile
      final response = await ApiConnect.updateProfile(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        address:
            _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
        phoneNumber:
            _phoneNumberController.text.trim().isNotEmpty
                ? _phoneNumberController.text.trim()
                : null,
      );
      if (response != null) {}

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Update local storage
        await ApiConnect.storage.write(
          key: 'username',
          value: _usernameController.text.trim(),
        );
        await ApiConnect.storage.write(
          key: 'email',
          value: _emailController.text.trim(),
        );
        await ApiConnect.storage.write(
          key: 'first_name',
          value: _firstNameController.text.trim(),
        );
        await ApiConnect.storage.write(
          key: 'last_name',
          value: _lastNameController.text.trim(),
        );
        await ApiConnect.storage.write(
          key: 'address',
          value: _addressController.text.trim(),
        );
        await ApiConnect.storage.write(
          key: 'phone_number',
          value: _phoneNumberController.text.trim(),
        );

        // Exit editing mode first
        setState(() {
          _isEditing = false;
        });

        // Reload profile data from server to get the latest changes
        await _loadUserProfile(false); // Don't show loading spinner
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // API call failed, show error
        if (response != null) {}

        String errorMessage = 'Failed to update profile on server';
        if (response != null) {
          try {
            final errorData = jsonDecode(response.body);
            if (errorData['detail'] != null) {
              errorMessage = errorData['detail'];
            } else if (errorData['error'] != null) {
              errorMessage = errorData['error'];
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          } catch (e) {}
        } else {
          errorMessage = 'Network error: Could not connect to server';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              action: SnackBarAction(label: 'Retry', onPressed: _saveProfile),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: Failed to update profile'),
            backgroundColor: Colors.red,
            action: SnackBarAction(label: 'Retry', onPressed: _saveProfile),
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                    confirmPasswordController.text,
                  );
                },
                child: const Text('Change Password'),
              ),
            ],
          ),
    );
  }

  Future<void> _changePassword(
    String current,
    String newPassword,
    String confirm,
  ) async {
    // Validation checks
    if (current.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current password cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      print(
        '[ERROR] ProfilePage: Password too short (${newPassword.length} characters)',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword == current) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be different from current password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await ApiConnect.changePassword(
        currentPassword: current,
        newPassword: newPassword,
        confirmPassword: confirm,
      );

      Navigator.pop(context); // Close dialog
      if (response != null && response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = 'Failed to change password';
        if (response != null) {
          try {
            final errorData = jsonDecode(response.body);
            if (errorData['detail'] != null) {
              errorMessage = errorData['detail'];
            } else if (errorData['error'] != null) {
              errorMessage = errorData['error'];
            } else if (response.statusCode == 400) {
              errorMessage = 'Current password is incorrect';
            } else if (response.statusCode == 401) {
              errorMessage = 'Authentication failed. Please login again.';
            }
          } catch (e) {
            errorMessage =
                'Failed to change password (Status: ${response.statusCode})';
          }
        } else {
          errorMessage = 'Network error: Could not connect to server';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _showChangePasswordDialog(),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: Failed to change password'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _showChangePasswordDialog(),
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to logout?'),
                  SizedBox(height: 8),
                  Text(
                    'This will:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('• Clear your login session'),
                  Text('• Log you out from the server'),
                  Text('• Remove stored credentials'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Logout'),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Logging out...'),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Call the enhanced logout method
        final logoutSuccess = await ApiConnect.logout();
        if (mounted) {
          // Clear the loading snackbar
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          if (logoutSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Logged out successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Navigate to login screen
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          } else {
            // Show error message but still navigate (local storage was cleared)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Logout completed with some issues. You have been logged out locally.',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );

            // Still navigate to login screen since local logout succeeded
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
            print(
              '[DEBUG] ProfilePage: Navigation to login completed (with warnings)',
            );
          }
        } else {}
      } else {}
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error during logout: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _logout(),
            ),
          ),
        );
      }
    }
  }

  void _showBookingOptions(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showBookingDetails(booking);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancel Booking'),
                onTap: () {
                  Navigator.pop(context);
                  _cancelBooking(booking);
                },
              ),
            ],
          ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(booking.carWash.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service: ${booking.service.name}'),
                Text(
                  'Date: ${DateFormat.yMMMd().add_jm().format(booking.dateTime)}',
                ),
                Text('Payment: ${booking.paymentMethod}'),
                Text('Quantity: ${booking.quantity}'),
                Text('Status: Confirmed'),
                Text('Location: ${booking.carWash.location}'),
                Text('Operating Hours: ${booking.carWash.openHours}'),
              ],
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

  void _cancelBooking(Booking booking) {
    try {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cancel Booking'),
              content: Text(
                'Are you sure you want to cancel the booking for ${booking.carWash.name}?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () {
                    try {
                      // Remove booking from provider
                      context.read<CartProvider>().removeBooking(booking);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking cancelled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e, stackTrace) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to cancel booking. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
      );
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error opening cancel dialog. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
