import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_connect.dart';
import 'package:flutter_application_1/screens/main/login%20screens/account.dart';
import 'package:flutter_application_1/screens/main/login%20screens/loginform.dart';

import 'dart:convert';

class SignUpForm extends StatefulWidget {
  const SignUpForm({Key? key}) : super(key: key);

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email';
    return null;
  }

  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) return 'Please enter your $fieldName';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final response = await ApiConnect.register(
          _usernameController.text,
          _emailController.text,
          _firstNameController.text,
          _lastNameController.text,
          _passwordController.text,
          _confirmPasswordController.text,
        );
        Navigator.of(context).pop(); 
        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please log in.')),
          );
          Navigator.pop(context); // Close sign up dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.all(20),
                content: LoginForm(),
              );
            },
          );
        } else {
          String errorMsg = 'Registration failed!';
          try {
            final data = jsonDecode(response.body);
            errorMsg = data['detail'] ?? errorMsg;
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } catch (e) {
        Navigator.of(context).pop(); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                cursorColor: Colors.blue,
                decoration: const InputDecoration(
                  hintText: "Your email",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.email),
                  ),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                cursorColor: Colors.blue,
                decoration: const InputDecoration(
                  hintText: "Username",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.person),
                  ),
                ),
                validator: (value) => _validateNotEmpty(value, 'username'),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                cursorColor: Colors.blue,
                decoration: const InputDecoration(
                  hintText: "First name",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.person_outline),
                  ),
                ),
                validator: (value) => _validateNotEmpty(value, 'first name'),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                cursorColor: Colors.blue,
                decoration: const InputDecoration(
                  hintText: "Last name",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.person_outline),
                  ),
                ),
                validator: (value) => _validateNotEmpty(value, 'last name'),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                cursorColor: Colors.blue,
                decoration: const InputDecoration(
                  hintText: "Password",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.lock),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                cursorColor: Colors.blue,
                decoration: const InputDecoration(
                  hintText: "Confirm password",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.lock_outline),
                  ),
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("SIGN UP"),
              ),
              const SizedBox(height: 5),
              AlreadyHaveAnAccountCheck(
                login: false,
                press: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        content: LoginForm(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
