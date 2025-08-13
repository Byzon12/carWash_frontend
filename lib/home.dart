import 'package:flutter/material.dart';
import 'package:flutter_application_1/dashboard.dart';
import 'package:flutter_application_1/his.dart';
import 'package:flutter_application_1/profile.dart';
import 'package:flutter_application_1/screens/favorites_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/utilites/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();}

  @override
  Widget build(BuildContext context) {final pages = [
      DashboardPage(
        onBook: (booking) {
          // Handle booking if needed - you can use the CartProvider here
          context.read<CartProvider>().addBookings([booking]);
        },
      ),
      BookingHistoryPage(),
      FavoritesPage(
        onNavigateToDashboard: () {
          setState(() {
            _selectedIndex = 0; // Navigate to dashboard
          });
        },
      ),
      const ProfilePage(
        bookings: [],
      ), // ProfilePage reads bookings internally from provider
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
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
