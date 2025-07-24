import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/main/welcome/splash.dart';
import 'package:flutter_application_1/utilites/provider.dart';
import 'package:provider/provider.dart';

import 'cart.dart';
import 'home.dart';
import 'models/cars.dart';
import 'screens/main/login screens/loginform.dart';
import 'screens/backend_test_screen.dart';
import 'screens/simple_login_test.dart';
import 'screens/location_test_screen.dart';
import 'screens/quick_backend_test.dart';
import 'screens/backend_connectivity_test.dart';

void main() {
  runApp(const CarWashApp());
}

class CarWashApp extends StatelessWidget {
  const CarWashApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
      secondary: Colors.green,
      tertiary: Colors.blue,
    );

    final ThemeData theme = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          minimumSize: const Size(300, 56),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: colorScheme.surfaceContainerHighest,
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      splashColor: colorScheme.secondary.withOpacity(0.3),
      highlightColor: colorScheme.secondary.withOpacity(0.1),
    );

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: MaterialApp(
        title: 'Car Wash Booking',
        theme: theme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const Splash(),
          '/home': (context) {
            print('[DEBUG] Route: Navigating to HomePage');
            return const HomePage();
          },
          '/login': (context) => LoginForm(),
          '/backend-test': (context) => const BackendTestScreen(),
          '/login-test': (context) => const SimpleLoginTest(),
          '/location-test': (context) => const LocationTestScreen(),
          '/quick-test': (context) => const QuickBackendTest(),
          '/connectivity-test': (context) => const BackendConnectivityTest(),
          '/cart':
              (context) => CartPage(
                carWash: CarWash(
                  id: '',
                  name: '',
                  imageUrl: '',
                  services: [],
                  location: '',
                  openHours: '',
                  latitude: 0.0,
                  longitude: 0.0,
                ),
              ), // Replace with actual CarWash object if needed
        },
      ),
    );
  }
}
