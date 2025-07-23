import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_connect.dart';
import 'package:flutter_application_1/screens/main/login%20screens/account.dart';

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

  void _submit() async {
    print('[DEBUG] LoginForm: _submit() called');

    if (_formKey.currentState!.validate()) {
      print('[DEBUG] LoginForm: Form validation passed');
      setState(() {
        _isLoading = true;
        _loginSuccess = false; // Reset success state
      });

      try {
        final input = _emailOrUsernameController.text.trim();
        final password = _passwordController.text;
        final isEmail = input.contains('@');

        print('[DEBUG] LoginForm: Attempting login with input: $input');
        print('[DEBUG] LoginForm: Is email? $isEmail');

        final response = await ApiConnect.login(
          username: isEmail ? null : input,
          email: isEmail ? input : null,
          password: password,
        );

        print('🔍 Login response status: ${response.statusCode}');
        print('🔍 Login response body: ${response.body}');
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Login successful! Setting success state and navigating...');
          setState(() => _loginSuccess = true);

          // User data is already stored by ApiConnect.login() method
          print(
            '📱 User data stored by API method, proceeding with navigation...',
          );

          // Wait a short time before navigation
          await Future.delayed(const Duration(milliseconds: 500));

          // Then navigate to home screen
          if (mounted) {
            print('🏠 Navigating to home screen...');
            print('🔍 Current route: ${ModalRoute.of(context)?.settings.name}');
            print('🔍 Navigator state: ${Navigator.of(context)}');

            try {
              // First, let's try a simple push to see if route exists
              print('🧪 Testing if /home route exists...');

              // Navigate to home using pushNamedAndRemoveUntil to clear the stack
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false, // Remove all previous routes
              );
              print('🎯 Navigation to home completed successfully!');

              // Show success message to user
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Login successful! Welcome back!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e, stackTrace) {
              print('❌ Navigation error: $e');
              print('❌ Stack trace: $stackTrace');

              // Fallback: try pushReplacement instead
              try {
                print('🔄 Trying fallback navigation...');
                Navigator.of(context).pushReplacementNamed('/home');
                print('🔄 Fallback navigation completed!');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login successful! (fallback navigation)'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (fallbackError, fallbackTrace) {
                print('❌ Fallback navigation failed: $fallbackError');
                print('❌ Fallback stack trace: $fallbackTrace');

                // Show error to user
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Navigation error: $fallbackError'),
                      backgroundColor: Colors.red,
                      action: SnackBarAction(
                        label: 'Retry',
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                      ),
                    ),
                  );
                }
              }
            }
          } else {
            print('⚠️ Widget not mounted, skipping navigation');
          }
        } else {
          print(
            '[ERROR] LoginForm: Login failed with status: ${response.statusCode}',
          );
          print('[ERROR] LoginForm: Response body: ${response.body}');

          String errorMsg = 'Login failed!';

          // More detailed error handling for different status codes
          if (response.statusCode == 400) {
            errorMsg = 'Bad Request: Please check your credentials';
          } else if (response.statusCode == 401) {
            errorMsg = 'Invalid credentials';
          } else if (response.statusCode == 404) {
            errorMsg = 'Login endpoint not found';
          } else if (response.statusCode == 500) {
            errorMsg = 'Server error. Please try again later';
          }

          try {
            final data = jsonDecode(response.body);
            print('[DEBUG] LoginForm: Parsed error response: $data');

            if (data is Map && data.containsKey('detail')) {
              errorMsg = data['detail'];
            } else if (data is Map && data.containsKey('error')) {
              errorMsg = data['error'];
            } else if (data is Map && data.containsKey('message')) {
              errorMsg = data['message'];
            } else if (data is Map) {
              // Handle validation errors
              final errors = <String>[];
              data.forEach((key, value) {
                if (value is List) {
                  errors.add('$key: ${value.join(', ')}');
                } else {
                  errors.add('$key: $value');
                }
              });
              if (errors.isNotEmpty) {
                errorMsg = errors.join('\n');
              }
            }
          } catch (e) {
            print('[ERROR] LoginForm: Error parsing login response: $e');
            errorMsg += ' (Status: ${response.statusCode})';
          }

          print('[DEBUG] LoginForm: Final error message: $errorMsg');

          // Ensure widget is mounted before showing SnackBar
          if (mounted) {
            print('[DEBUG] LoginForm: Showing error SnackBar');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login failed: $errorMsg'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    print('[DEBUG] LoginForm: Retry button pressed');
                    _submit();
                  },
                ),
              ),
            );
          } else {
            print(
              '[WARNING] LoginForm: Widget not mounted, cannot show SnackBar',
            );
          }
        }
      } catch (e, stackTrace) {
        print('[ERROR] LoginForm: Login exception: $e');
        print('[ERROR] LoginForm: Stack trace: $stackTrace');

        // Only show SnackBar if the widget is still mounted
        if (mounted) {
          print('[DEBUG] LoginForm: Showing connection error SnackBar');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection error: Failed to connect to server'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  print(
                    '[DEBUG] LoginForm: Retry button pressed from exception handler',
                  );
                  _submit(); // Retry login
                },
              ),
            ),
          );
        } else {
          print(
            '[WARNING] LoginForm: Widget not mounted, cannot show connection error SnackBar',
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      print('[DEBUG] LoginForm: Form validation failed');
      // Show validation error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
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
                                    const SnackBar(
                                      content: Text(
                                        'Please enter your email address',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(emailController.text)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid email address',
                                      ),
                                      backgroundColor: Colors.red,
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
                                        const SnackBar(
                                          content: Text(
                                            'Password reset link sent! Check your email.',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  } else {
                                    String errorMessage =
                                        'Failed to send reset link';

                                    if (response.statusCode == 404) {
                                      errorMessage = 'Email address not found';
                                    } else if (response.statusCode == 429) {
                                      errorMessage =
                                          'Too many requests. Please try again later';
                                    } else if (response.statusCode >= 500) {
                                      errorMessage =
                                          'Server error. Please try again later';
                                    }

                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  Navigator.pop(context); // Close dialog
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Network error: $e'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 5),
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
          _isLoading
              ? const CircularProgressIndicator()
              : _loginSuccess
              ? Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'LOGIN SUCCESSFUL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              : ElevatedButton(onPressed: _submit, child: const Text("LOGIN")),
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
