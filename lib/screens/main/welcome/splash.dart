import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screens/main/welcome/welcome.dart';
import 'package:flutter_application_1/api/api_connect.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Check authentication status after animation
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      print('[DEBUG] Splash: Checking authentication status...');
      final isLoggedIn = await ApiConnect.isLoggedIn();
      print('[DEBUG] Splash: Is user logged in? $isLoggedIn');

      if (isLoggedIn) {
        print('[DEBUG] Splash: User is logged in, navigating to home...');
        // User is already logged in, go directly to home using named route
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false, // Remove all previous routes
        );
        print('[DEBUG] Splash: Navigation to home completed');
      } else {
        print('[DEBUG] Splash: User not logged in, showing welcome screen...');
        // User not logged in, show welcome screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
        print('[DEBUG] Splash: Navigation to welcome completed');
      }
    } catch (e, stackTrace) {
      print('[ERROR] Splash: Exception checking auth: $e');
      print('[ERROR] Splash: Stack trace: $stackTrace');

      // If there's an error checking auth, default to welcome screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      print('[DEBUG] Splash: Fallback navigation to welcome completed');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Center(
            child: Text(
              "WELCOME TO OUR CAR WASH",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
