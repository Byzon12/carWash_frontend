import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/main/login%20screens/loginform.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  void _showLoginPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(20),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              // Pass the parent context (the scaffold's context)
              child: LoginForm(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginButton = ElevatedButton(
      onPressed: () => _showLoginPopup(context),
      child: const Text("Login"),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(300, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        backgroundColor: Colors.blue,
      ),
    );

    return Scaffold(
      body: Center(
        child: loginButton,
      ),
    );
  }
}
