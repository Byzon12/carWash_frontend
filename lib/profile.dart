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
    print('[DEBUG] ProfilePage: Initializing ProfilePage');
    _initializeControllers();
    _loadUserProfile();
    _loadLoyaltyPoints(); // Load loyalty points when page initializes
    print('[DEBUG] ProfilePage: ProfilePage initialization completed');
  }

  void _initializeControllers() {
    print('[DEBUG] ProfilePage: Initializing text controllers');
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneNumberController = TextEditingController();
    print('[DEBUG] ProfilePage: Text controllers initialized successfully');
  }

  @override
  void dispose() {
    print('[DEBUG] ProfilePage: Disposing text controllers');
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
    print('[DEBUG] ProfilePage: ProfilePage disposed successfully');
  }

  Future<void> _loadUserProfile([bool showLoading = true]) async {
    try {
      print('[DEBUG] ProfilePage: Starting to load user profile');
      if (showLoading) {
        setState(() => _loading = true);
      }

      // Try to get profile from API first
      print('[DEBUG] ProfilePage: Attempting to fetch profile from API');
      final response = await ApiConnect.getUserProfile();

      if (response != null && response.statusCode == 200) {
        print(
          '[DEBUG] ProfilePage: API response successful, status: ${response.statusCode}',
        );
        final profile = jsonDecode(response.body);
        print(
          '[DEBUG] ProfilePage: Profile data received: ${profile.keys.toList()}',
        );

        setState(() {
          _userProfile = profile;
          _updateControllers();
        });

        // Also load loyalty points only during full refresh
        if (showLoading) {
          await _loadLoyaltyPoints();
        }

        print('[DEBUG] ProfilePage: Profile loaded successfully from API');
      } else {
        print(
          '[DEBUG] ProfilePage: API failed - Status: ${response?.statusCode}, falling back to stored data',
        );
        // Fallback to stored user data
        await _loadStoredUserData();
      }
    } catch (e, stackTrace) {
      print('[ERROR] ProfilePage: Exception in _loadUserProfile: $e');
      print('[ERROR] ProfilePage: Stack trace: $stackTrace');

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
      print('[DEBUG] ProfilePage: Profile loading completed');
    }
  }

  Future<void> _loadStoredUserData() async {
    try {
      print(
        '[DEBUG] ProfilePage: Loading stored user data from secure storage',
      );

      // Load from secure storage
      final email = await ApiConnect.storage.read(key: 'email');
      final firstName = await ApiConnect.storage.read(key: 'first_name');
      final lastName = await ApiConnect.storage.read(key: 'last_name');
      final username = await ApiConnect.storage.read(key: 'username');
      final address = await ApiConnect.storage.read(key: 'address');
      final phoneNumber = await ApiConnect.storage.read(key: 'phone_number');

      print(
        '[DEBUG] ProfilePage: Stored data - Username: $username, Email: $email',
      );
      print(
        '[DEBUG] ProfilePage: Stored data - FirstName: $firstName, LastName: $lastName',
      );
      print(
        '[DEBUG] ProfilePage: Stored data - Address: $address, Phone: $phoneNumber',
      );

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

      print('[DEBUG] ProfilePage: Stored user data loaded successfully');
    } catch (e, stackTrace) {
      print('[ERROR] ProfilePage: Exception in _loadStoredUserData: $e');
      print('[ERROR] ProfilePage: Stack trace: $stackTrace');

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
      print('[DEBUG] ProfilePage: Updating text controllers with profile data');

      if (_userProfile != null) {
        _usernameController.text = _userProfile!['username'] ?? '';
        _emailController.text = _userProfile!['email'] ?? '';
        _firstNameController.text = _userProfile!['first_name'] ?? '';
        _lastNameController.text = _userProfile!['last_name'] ?? '';
        _addressController.text = _userProfile!['address'] ?? '';
        _phoneNumberController.text = _userProfile!['phone_number'] ?? '';

        print(
          '[DEBUG] ProfilePage: Controllers updated - Username: ${_usernameController.text}',
        );
        print(
          '[DEBUG] ProfilePage: Controllers updated - Email: ${_emailController.text}',
        );
      } else {
        print(
          '[WARNING] ProfilePage: _userProfile is null, cannot update controllers',
        );
      }
    } catch (e, stackTrace) {
      print('[ERROR] ProfilePage: Exception in _updateControllers: $e');
      print('[ERROR] ProfilePage: Stack trace: $stackTrace');
    }
  }

  void _navigateToLoyaltyDashboard() {
    print('[DEBUG] ProfilePage: Navigating to loyalty dashboard');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoyaltyPointsScreen()),
    );
  }

  Future<void> _loadLoyaltyPoints() async {
    try {
      print('[DEBUG] ProfilePage: Loading loyalty points from API');
      final response = await ApiConnect.getLoyaltyDashboard();

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final loyaltyStats = data['data']['loyalty_stats'];
          setState(() {
            _userProfile ??= {};
            _userProfile!['loyalty_points'] = loyaltyStats['current_points'];
          });
          print(
            '[DEBUG] ProfilePage: Loyalty points updated: ${loyaltyStats['current_points']}',
          );
        }
      } else {
        print(
          '[DEBUG] ProfilePage: Failed to load loyalty points, using default',
        );
      }
    } catch (e) {
      print('[ERROR] ProfilePage: Exception loading loyalty points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      '[DEBUG] ProfilePage: Building UI - Loading: $_loading, Editing: $_isEditing',
    );

    final bookings = context.watch<CartProvider>().bookings;
    print('[DEBUG] ProfilePage: Found ${bookings.length} bookings');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Refresh profile data button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('[DEBUG] ProfilePage: Refresh button pressed');
              _loadUserProfile();
            },
            tooltip: 'Refresh Profile',
          ),
          // Password change button in top corner
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              print('[DEBUG] ProfilePage: Password change button pressed');
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
                print('[DEBUG] ProfilePage: Save button pressed');
                _saveProfile();
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                print('[DEBUG] ProfilePage: Cancel edit button pressed');
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
                    _buildBookingHistorySection(bookings),
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
                                color: Colors.orange.shade300.withOpacity(0.3),
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
                    print('[DEBUG] ProfilePage: Edit button pressed');
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
        const Text(
          'Booking History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildBookingHistory(bookings),
      ],
    );
  }

  Widget _buildBookingHistory(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: Text('No bookings yet.')),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(Icons.local_car_wash, color: Colors.blue.shade600),
            title: Text('${booking.carWash.name} - ${booking.service.name}'),
            subtitle: Text(
              'Date: ${DateFormat.yMMMd().add_jm().format(booking.dateTime)}\n'
              'Payment: ${booking.paymentMethod}\n'
              'Quantity: ${booking.quantity}\n'
              'Status: Confirmed',
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
      print('[DEBUG] ProfilePage: Starting profile save operation');
      print(
        '[DEBUG] ProfilePage: Data to save - Username: ${_usernameController.text}',
      );
      print(
        '[DEBUG] ProfilePage: Data to save - Email: ${_emailController.text}',
      );
      print(
        '[DEBUG] ProfilePage: Data to save - FirstName: ${_firstNameController.text}',
      );
      print(
        '[DEBUG] ProfilePage: Data to save - LastName: ${_lastNameController.text}',
      );
      print(
        '[DEBUG] ProfilePage: Data to save - Address: ${_addressController.text}',
      );
      print(
        '[DEBUG] ProfilePage: Data to save - Phone: ${_phoneNumberController.text}',
      );

      // Validate required fields
      if (_usernameController.text.trim().isEmpty) {
        print('[ERROR] ProfilePage: Username is empty');
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
        print('[ERROR] ProfilePage: Invalid email format');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Call the API to update the profile
      print('[DEBUG] ProfilePage: Calling API to update profile');
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

      print(
        '[DEBUG] ProfilePage: API response status: ${response?.statusCode}',
      );
      if (response != null) {
        print('[DEBUG] ProfilePage: API response body: ${response.body}');
      }

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        print(
          '[DEBUG] ProfilePage: API update successful, status: ${response.statusCode}',
        );

        // Update local storage
        print('[DEBUG] ProfilePage: Updating local storage');
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
        print('[DEBUG] ProfilePage: Reloading profile data from server');
        await _loadUserProfile(false); // Don't show loading spinner

        print('[DEBUG] ProfilePage: Profile saved and reloaded successfully');
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
        print(
          '[ERROR] ProfilePage: API update failed - Status: ${response?.statusCode}',
        );
        if (response != null) {
          print('[ERROR] ProfilePage: API response body: ${response.body}');
        }

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
          } catch (e) {
            print('[WARNING] ProfilePage: Could not parse error response: $e');
          }
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
      print('[ERROR] ProfilePage: Exception in _saveProfile: $e');
      print('[ERROR] ProfilePage: Stack trace: $stackTrace');

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
    print('[DEBUG] ProfilePage: Showing change password dialog');

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
                  print(
                    '[DEBUG] ProfilePage: Change password dialog cancelled',
                  );
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  print(
                    '[DEBUG] ProfilePage: Change password confirmed, processing...',
                  );
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
    print('[DEBUG] ProfilePage: Starting password change operation');

    // Validation checks
    if (current.trim().isEmpty) {
      print('[ERROR] ProfilePage: Current password is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current password cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword != confirm) {
      print('[ERROR] ProfilePage: New passwords do not match');
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
      print('[ERROR] ProfilePage: New password same as current');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be different from current password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('[DEBUG] ProfilePage: Calling API to change password');
      final response = await ApiConnect.changePassword(
        currentPassword: current,
        newPassword: newPassword,
        confirmPassword: confirm,
      );

      Navigator.pop(context); // Close dialog
      print('[DEBUG] ProfilePage: Password change dialog closed');

      if (response != null && response.statusCode == 200) {
        print('[DEBUG] ProfilePage: Password changed successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print(
          '[ERROR] ProfilePage: Password change failed - Status: ${response?.statusCode}',
        );
        print('[ERROR] ProfilePage: Response body: ${response?.body}');

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
            print('[WARNING] ProfilePage: Could not parse error response: $e');
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
      print('[ERROR] ProfilePage: Exception in _changePassword: $e');
      print('[ERROR] ProfilePage: Stack trace: $stackTrace');

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
      print('[DEBUG] ProfilePage: Starting logout process');

      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () {
                    print('[DEBUG] ProfilePage: Logout cancelled by user');
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    print('[DEBUG] ProfilePage: Logout confirmed by user');
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Logout'),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        print('[DEBUG] ProfilePage: Performing logout operation');
        await ApiConnect.logout();
        print('[DEBUG] ProfilePage: Logout completed, navigating to login');

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          print('[DEBUG] ProfilePage: Navigation to login completed');
        } else {
          print(
            '[WARNING] ProfilePage: Widget not mounted, skipping navigation',
          );
        }
      } else {
        print('[DEBUG] ProfilePage: Logout operation cancelled');
      }
    } catch (e, stackTrace) {
      print('[ERROR] ProfilePage: Exception during logout: $e');
      print('[ERROR] ProfilePage: Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error during logout. Please try again.'),
            backgroundColor: Colors.red,
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
      print(
        '[DEBUG] ProfilePage: Starting cancel booking for: ${booking.carWash.name}',
      );

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
                    print(
                      '[DEBUG] ProfilePage: Booking cancellation cancelled by user',
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () {
                    try {
                      print(
                        '[DEBUG] ProfilePage: Confirming booking cancellation',
                      );
                      // Remove booking from provider
                      context.read<CartProvider>().removeBooking(booking);
                      Navigator.pop(context);

                      print(
                        '[DEBUG] ProfilePage: Booking cancelled successfully',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking cancelled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e, stackTrace) {
                      print(
                        '[ERROR] ProfilePage: Error cancelling booking: $e',
                      );
                      print('[ERROR] ProfilePage: Stack trace: $stackTrace');

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
      print('[ERROR] ProfilePage: Exception in _cancelBooking: $e');
      print('[ERROR] ProfilePage: Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error opening cancel dialog. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
