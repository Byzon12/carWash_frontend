import 'package:flutter/material.dart';
import 'package:flutter_application_1/cart.dart';
import 'package:flutter_application_1/dashboard.dart';
import 'package:flutter_application_1/his.dart';
import 'package:flutter_application_1/profile.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/utilites/provider.dart';

import 'models/cars.dart'; // Your CartProvider

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    print('[DEBUG] HomePage: HomePage initialized successfully');
  }

  @override
  Widget build(BuildContext context) {
    print('[DEBUG] HomePage: Building HomePage UI');

    final pages = [
      DashboardPage(
        onBook: (booking) {
          // Handle booking if needed - you can use the CartProvider here
          context.read<CartProvider>().addBookings([booking]);
        },
      ),
      BookingHistoryPage(),
      const ProfilePage(
        bookings: [],
      ), // ProfilePage reads bookings internally from provider

      CartPage(
        carWash: CarWash(
          id: '',
          name: '',
          imageUrl: '',
          services: [],
          location: '',
          openHours: '',
          latitude: 0.0,
          longitude: 0.0,
          address: '',
          contactNumber: '',
          email: '',
          locationServices: [],
          totalServices: 0,
          popularServices: [],
          averageRating: 0.0,
          totalBookings: 0,
          completionRate: 0.0,
          isOpen: false,
          features: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Car Wash App')),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Cart',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
