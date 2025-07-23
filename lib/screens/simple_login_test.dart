import 'package:flutter/material.dart';

class SimpleLoginTest extends StatelessWidget {
  const SimpleLoginTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Simple Login Navigation Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                print('🔄 Starting simulated login...');

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) =>
                          const Center(child: CircularProgressIndicator()),
                );

                // Simulate login delay
                await Future.delayed(const Duration(seconds: 1));

                // Close loading dialog
                Navigator.of(context).pop();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Login successful! Redirecting...'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );

                // Wait a bit
                await Future.delayed(const Duration(seconds: 1));

                // Navigate to home
                if (context.mounted) {
                  print('🏠 Navigating to home...');
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/home', (route) => false);
                  print('✅ Navigation completed!');
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Simulate Successful Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (route) => false);
              },
              icon: const Icon(Icons.home),
              label: const Text('Direct Home Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Check the debug console for navigation logs',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
