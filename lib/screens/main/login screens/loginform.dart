import 'package:flutter/material.dart';
    import 'package:flutter_application_1/api/api_connect.dart';
import 'package:flutter_application_1/home.dart';
    import 'package:flutter_application_1/screens/main/login%20screens/account.dart';
    // Remember to import your actual API and other required files
    import 'dart:convert';
    import 'package:flutter_application_1/screens/main/signupscreens/form.dart';

    class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailOrUsernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

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
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
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
          final data = jsonDecode(response.body);
          await ApiConnect.storage.write(key: 'access', value: data['access']);
          await ApiConnect.storage.write(key: 'refresh', value: data['refresh']);
          await ApiConnect.storage.write(key: 'username', value: data['username']);
          await ApiConnect.storage.write(key: 'email', value: data['email']);
          await ApiConnect.storage.write(key: 'first_name', value: data['first_name']);
          await ApiConnect.storage.write(key: 'last_name', value: data['last_name']);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );

          await Future.delayed(const Duration(milliseconds: 1200));
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          ); // Go to home
        } else {
          String errorMsg = 'Login failed!';
          try {
            final data = jsonDecode(response.body);
            if (data is Map && data.containsKey('detail')) {
              errorMsg = data['detail'];
            } else {
              errorMsg = data.values
                  .map((v) => v is List ? v.join(', ') : v.toString())
                  .join('\n');
            }
          } catch (e) {
            print('Error parsing login response: $e');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred: $errorMsg')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
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
          const SizedBox(height: 16.0),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _submit,
                  child: const Text("LOGIN"),
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

extension on SnackBar {
  get closed => null;
}
