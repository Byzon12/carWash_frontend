import 'package:flutter/material.dart';

class BookingPage extends StatelessWidget {
  final String? serviceName;

  const BookingPage({super.key, this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Page')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (serviceName != null)
              Text('Booking for: $serviceName', style: const TextStyle(fontSize: 18)),
            const TextField(decoration: InputDecoration(labelText: 'Name')),
            const TextField(decoration: InputDecoration(labelText: 'Phone')),
            const TextField(decoration: InputDecoration(labelText: 'Car Model')),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text("Success"),
                    content: Text("Booking confirmed!"),
                  ),
                );
              },
              child: const Text("Make Payment"),
            )
          ],
        ),
      ),
    );
  }
}
