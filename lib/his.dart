import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cars.dart';

class BookingHistoryPage extends StatelessWidget {
  final List<Booking> bookings;

  const BookingHistoryPage({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text('${booking.carWash.name} - ${booking.service.name}'),
            subtitle: Text(
              'Date: ${DateFormat.yMMMd().add_jm().format(booking.dateTime)}\n'
              'Payment: ${booking.paymentMethod}\n'
              'Quantity: ${booking.quantity}\n'
              'Status: Confirmed',
            ),
          ),
        );
      },
    );
  }
}
