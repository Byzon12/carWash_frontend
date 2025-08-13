import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_connect.dart';
import 'package:flutter_application_1/screens/main/login%20screens/account.dart';
import 'package:flutter_application_1/home.dart';
import 'package:flutter_application_1/services/location_helper.dart';

import 'dart:convert';
import 'package:flutter_application_1/screens/main/signupscreens/form.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailOrUsernameController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _loginSuccess = false;
  String? _errorMessage;
  bool _showError = false;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmailOrUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email or username';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Helper method to test route navigation
  void _testNavigation() async {
    // Show testing message
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
              Text('Testing navigation to home...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Navigation test failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _testNavigation(),
            ),
          ),
        );
      }
    }
  }

  // Enhanced method to parse server error messages
  String _parseServerError(int statusCode, String responseBody) {
    String errorMsg = 'Login failed!';

    // Default messages for status codes
    switch (statusCode) {
      case 400:
        errorMsg = 'Invalid request. Please check your input.';
        break;
      case 401:
        errorMsg = 'Invalid username/email or password.';
        break;
      case 403:
        errorMsg = 'Access forbidden. Your account may be disabled.';
        break;
      case 404:
        errorMsg = 'Login service not found. Please contact support.';
        break;
      case 429:
        errorMsg = 'Too many login attempts. Please try again later.';
        break;
      case 500:
        errorMsg = 'Server error. Please try again later.';
        break;
      case 502:
        errorMsg = 'Service temporarily unavailable. Please try again.';
        break;
      case 503:
        errorMsg = 'Service under maintenance. Please try again later.';
        break;
      default:
        errorMsg = 'Login failed with error code $statusCode.';
    }

    // Try to parse JSON response for more specific error messages
    try {
      final data = jsonDecode(responseBody);
      if (data is Map) {
        // Common error message fields from Django REST framework
        if (data.containsKey('detail')) {
          errorMsg = _formatErrorMessage(data['detail']);
        } else if (data.containsKey('error')) {
          errorMsg = _formatErrorMessage(data['error']);
        } else if (data.containsKey('message')) {
          errorMsg = _formatErrorMessage(data['message']);
        } else if (data.containsKey('non_field_errors')) {
          if (data['non_field_errors'] is List &&
              data['non_field_errors'].isNotEmpty) {
            errorMsg = _formatErrorMessage(data['non_field_errors'][0]);
          }
        } else {
          // Handle field-specific validation errors
          final errors = <String>[];

          // Common field names and their user-friendly versions
          final fieldMapping = {
            'username': 'Username',
            'email': 'Email',
            'password': 'Password',
            'credentials': 'Login credentials',
          };

          data.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              final fieldName = fieldMapping[key] ?? key;
              final errorMessage = value.join(', ');
              errors.add('$fieldName: ${_formatErrorMessage(errorMessage)}');
            } else if (value is String && value.isNotEmpty) {
              final fieldName = fieldMapping[key] ?? key;
              errors.add('$fieldName: ${_formatErrorMessage(value)}');
            }
          });

          if (errors.isNotEmpty) {
            errorMsg = errors.join('\n');
          }
        }
      }
    } catch (e) {
      // Keep the default error message based on status code
      errorMsg += ' Please try again.';
    }

    return errorMsg;
  }

  // Helper method to format error messages for better readability
  String _formatErrorMessage(dynamic message) {
    if (message is String) {
      // Common server error message translations
      final errorTranslations = {
        'Invalid credentials':
            'The username/email or password you entered is incorrect.',
        'Unable to log in with provided credentials':
            'The username/email or password you entered is incorrect.',
        'No active account found with the given credentials':
            'No account found with these login details.',
        'This field may not be blank': 'This field is required.',
        'This field is required': 'This field cannot be empty.',
        'Enter a valid email address': 'Please enter a valid email address.',
        'This password is too short': 'Password must be longer.',
        'This password is too common': 'Please choose a more secure password.',
        'User is not active':
            'Your account has been deactivated. Please contact support.',
        'Account locked':
            'Your account has been temporarily locked due to multiple failed login attempts.',
      };

      // Check for exact matches first
      for (final entry in errorTranslations.entries) {
        if (message.toLowerCase().contains(entry.key.toLowerCase())) {
          return entry.value;
        }
      }

      // Return the original message with first letter capitalized
      return message.isNotEmpty
          ? message[0].toUpperCase() + message.substring(1)
          : message;
    }

    return message.toString();
  }

  // Enhanced method to parse password reset error messages
  String _parsePasswordResetError(int statusCode, String responseBody) {
    String errorMsg = 'Failed to send reset link';

    // Default messages for status codes
    switch (statusCode) {
      case 400:
        errorMsg = 'Invalid email address format.';
        break;
      case 404:
        errorMsg = 'No account found with this email address.';
        break;
      case 429:
        errorMsg = 'Too many reset requests. Please wait before trying again.';
        break;
      case 500:
        errorMsg = 'Server error. Please try again later.';
        break;
      case 502:
        errorMsg = 'Email service temporarily unavailable.';
        break;
      case 503:
        errorMsg = 'Password reset service under maintenance.';
        break;
      default:
        errorMsg = 'Failed to send reset link. Error code: $statusCode';
    }

    // Try to parse JSON response for more specific error messages
    try {
      final data = jsonDecode(responseBody);
      if (data is Map) {
        if (data.containsKey('detail')) {
          errorMsg = _formatPasswordResetErrorMessage(data['detail']);
        } else if (data.containsKey('error')) {
          errorMsg = _formatPasswordResetErrorMessage(data['error']);
        } else if (data.containsKey('message')) {
          errorMsg = _formatPasswordResetErrorMessage(data['message']);
        } else if (data.containsKey('email')) {
          if (data['email'] is List && data['email'].isNotEmpty) {
            errorMsg =
                'Email: ${_formatPasswordResetErrorMessage(data['email'][0])}';
          }
        }
      }
    } catch (e) {}

    return errorMsg;
  }

  // Helper method to format password reset error messages
  String _formatPasswordResetErrorMessage(dynamic message) {
    if (message is String) {
      final errorTranslations = {
        'User with this email does not exist':
            'No account found with this email address.',
        'Invalid email': 'Please enter a valid email address.',
        'Rate limit exceeded':
            'Too many reset requests. Please wait before trying again.',
        'Email not found': 'No account found with this email address.',
        'Enter a valid email address': 'Please enter a valid email address.',
        'This field may not be blank': 'Email address is required.',
        'This field is required': 'Email address is required.',
      };

      // Check for exact matches first
      for (final entry in errorTranslations.entries) {
        if (message.toLowerCase().contains(entry.key.toLowerCase())) {
          return entry.value;
        }
      }

      return message.isNotEmpty
          ? message[0].toUpperCase() + message.substring(1)
          : message;
    }

    return message.toString();
  }

  void _submit() async {
    print('[DEBUG] LoginForm: _submit() called');
    print('[DEBUG] LoginForm: Navigator canPop: ${Navigator.canPop(context)}');

    // Clear previous error state
    setState(() {
      _errorMessage = null;
      _showError = false;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _loginSuccess = false; // Reset success state
      });

      try {
        final input = _emailOrUsernameController.text.trim();
        final password = _passwordController.text;
        final isEmail = input.contains('@');
        final response = await ApiConnect.login(
          username: isEmail ? null : input,
          email: isEmail ? input : null,
          password: password,
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            _loginSuccess = true;
            _showError = false;
            _errorMessage = null;
            _isLoading = false; // Stop loading to show success message
          });
          // User data is already stored by ApiConnect.login() method
          // First navigate to home screen immediately
          if (mounted) {
            print('🔍 Current route: ${ModalRoute.of(context)?.settings.name}');
            try {
              // Simple navigation to home
              // Show success message before navigation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Login successful! Redirecting to dashboard...'),
                    ],
                  ),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );

              // Wait a brief moment for snackbar to show
              await Future.delayed(const Duration(milliseconds: 500));

              // Navigate to home first
              Navigator.of(context).pushReplacementNamed('/home');
              // Request location permission AFTER navigation (non-blocking)
              Future.delayed(const Duration(milliseconds: 1500), () async {
                if (mounted) {
                  try {
                    await LocationHelper.requestLocationPermission(context);
                  } catch (e) {}
                }
              });
            } catch (e, stackTrace) {
              // Fallback: try pushNamedAndRemoveUntil
              try {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (route) => false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Login successful! (fallback navigation)'),
                        ],
                      ),
                      backgroundColor: Colors.orange.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (fallbackError, fallbackTrace) {
                // Final fallback: try direct route construction
                try {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Login successful! (direct navigation)'),
                          ],
                        ),
                        backgroundColor: Colors.amber.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (directError) {
                  // Show error to user
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Navigation Error',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Login successful but navigation failed: $directError',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 6),
                        action: SnackBarAction(
                          label: 'GO HOME',
                          textColor: Colors.white,
                          backgroundColor: Colors.red.shade500,
                          onPressed: () {
                            try {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/home',
                                (route) => false,
                              );
                            } catch (e) {}
                          },
                        ),
                      ),
                    );
                  }
                }
              }
            }
          } else {}
        } else {
          // Use enhanced error parsing method
          String errorMsg = _parseServerError(
            response.statusCode,
            response.body,
          );
          // Set error state for inline display
          setState(() {
            _errorMessage = errorMsg;
            _showError = true;
          });

          // Enhanced SnackBar with better styling
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Login Failed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(errorMsg, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 6),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                action: SnackBarAction(
                  label: 'RETRY',
                  textColor: Colors.white,
                  backgroundColor: Colors.red.shade500,
                  onPressed: () {
                    _submit();
                  },
                ),
              ),
            );
          } else {}
        }
      } catch (e, stackTrace) {
        // Set connection error state
        setState(() {
          _errorMessage =
              'Unable to connect to server. Please check your internet connection and try again.';
          _showError = true;
        });

        // Enhanced connection error SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Connection Error',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Failed to connect to server',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                backgroundColor: Colors.orange.shade500,
                onPressed: () {
                  _submit(); // Retry login
                },
              ),
            ),
          );
        } else {}
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Set validation error state
      setState(() {
        _errorMessage = 'Please fill in all required fields correctly';
        _showError = true;
      });

      // Enhanced validation error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Validation Error',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Please check your input fields',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.amber.shade700,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Reset Password'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your email address and we\'ll send you a link to reset your password.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (emailController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Email Required',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Please enter your email address',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.red.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(emailController.text)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.email_outlined,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Invalid Email',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Please enter a valid email address',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.orange.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isLoading = true);

                                try {
                                  final response =
                                      await ApiConnect.passwordReset(
                                        emailController.text,
                                      );

                                  Navigator.pop(context); // Close dialog

                                  if (response.statusCode == 200) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Reset Link Sent!',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Check your email for password reset instructions',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              Colors.green.shade700,
                                          duration: const Duration(seconds: 6),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    // Use enhanced error parsing for password reset
                                    String errorMessage =
                                        _parsePasswordResetError(
                                          response.statusCode,
                                          response.body,
                                        );

                                    // Determine appropriate icon based on error type
                                    IconData errorIcon = Icons.error_outline;
                                    if (errorMessage.toLowerCase().contains(
                                          'email',
                                        ) &&
                                        errorMessage.toLowerCase().contains(
                                          'not found',
                                        )) {
                                      errorIcon = Icons.person_search;
                                    } else if (errorMessage
                                            .toLowerCase()
                                            .contains('too many') ||
                                        errorMessage.toLowerCase().contains(
                                          'wait',
                                        )) {
                                      errorIcon = Icons.hourglass_empty;
                                    } else if (errorMessage
                                            .toLowerCase()
                                            .contains('server') ||
                                        errorMessage.toLowerCase().contains(
                                          'maintenance',
                                        )) {
                                      errorIcon = Icons.dns_outlined;
                                    } else if (errorMessage
                                            .toLowerCase()
                                            .contains('invalid') &&
                                        errorMessage.toLowerCase().contains(
                                          'email',
                                        )) {
                                      errorIcon = Icons.email_outlined;
                                    }

                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(
                                                errorIcon,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      'Reset Failed',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      errorMessage,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.red.shade700,
                                          duration: const Duration(seconds: 6),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          action: SnackBarAction(
                                            label: 'RETRY',
                                            textColor: Colors.white,
                                            backgroundColor:
                                                Colors.red.shade500,
                                            onPressed: () {
                                              _showForgotPasswordDialog();
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  Navigator.pop(context); // Close dialog
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.wifi_off,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Network Error',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Failed to connect: $e',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.orange.shade700,
                                        duration: const Duration(seconds: 6),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        action: SnackBarAction(
                                          label: 'RETRY',
                                          textColor: Colors.white,
                                          backgroundColor:
                                              Colors.orange.shade500,
                                          onPressed: () {
                                            _showForgotPasswordDialog();
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Send Reset Link'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _emailOrUsernameController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            cursorColor: Colors.blue,
            decoration: const InputDecoration(
              hintText: "Your email or username",
              prefixIcon: Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.person),
              ),
            ),
            validator: _validateEmailOrUsername,
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _passwordController,
            textInputAction: TextInputAction.done,
            obscureText: true,
            cursorColor: Colors.blue,
            decoration: const InputDecoration(
              hintText: "Your password",
              prefixIcon: Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.lock),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 8.0),
          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.blue.shade600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          // Inline Error Display
          if (_showError && _errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showError = false;
                        _errorMessage = null;
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: Colors.red.shade700,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          _isLoading
              ? const CircularProgressIndicator()
              : _loginSuccess
              ? Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'LOGIN SUCCESSFUL!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
              : ElevatedButton(onPressed: _submit, child: const Text("LOGIN")),
          const SizedBox(height: 8.0),
          // Test navigation button for debugging
          if (true) // Set to false to hide
            TextButton(
              onPressed: _testNavigation,
              child: const Text(
                "TEST NAVIGATION",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16.0),
          AlreadyHaveAnAccountCheck(
            login: true,
            press: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                    content: const SignUpForm(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
