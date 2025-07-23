import 'package:flutter/material.dart';

class NavigationTestButton extends StatelessWidget {
  const NavigationTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        print('🧪 Testing navigation to home...');

        try {
          // Test direct navigation to home
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
          print('✅ Navigation test successful!');
        } catch (e) {
          print('❌ Navigation test failed: $e');

          // Show error to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigation failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      label: const Text('Test Home Navigation'),
      icon: const Icon(Icons.home),
      backgroundColor: Colors.orange,
    );
  }
}

// Widget to add debug information to any screen
class NavigationDebugInfo extends StatelessWidget {
  const NavigationDebugInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔍 Navigation Debug Info',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Current route: ${ModalRoute.of(context)?.settings.name ?? "Unknown"}',
          ),
          Text('Can pop: ${Navigator.of(context).canPop()}'),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  print('Testing /home route...');
                  Navigator.pushNamed(context, '/home');
                },
                child: const Text('Test /home'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  print('Testing /login route...');
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Test /login'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
