import 'package:flutter/material.dart';
import '../api/api_connect.dart';

class LoginStatusWidget extends StatelessWidget {
  const LoginStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ApiConnect.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final isLoggedIn = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLoggedIn ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLoggedIn ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLoggedIn ? Icons.check_circle : Icons.error,
                color: isLoggedIn ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isLoggedIn ? 'Logged In' : 'Not Logged In',
                style: TextStyle(
                  color:
                      isLoggedIn ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper method to show login status
void showLoginStatus(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Login Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoginStatusWidget(),
              const SizedBox(height: 16),
              FutureBuilder<String?>(
                future: ApiConnect.getAccessToken(),
                builder: (context, snapshot) {
                  final token = snapshot.data;
                  return Text(
                    token != null
                        ? 'Token: ${token.substring(0, 20)}...'
                        : 'No token found',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                await ApiConnect.logout();
                Navigator.pop(context);

                // Navigate to welcome screen after logout
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        ),
  );
}
