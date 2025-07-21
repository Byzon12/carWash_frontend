import 'package:flutter/material.dart';
import 'package:flutter_application_1/utilites/provider.dart';
import 'package:provider/provider.dart';

import 'models/cars.dart';


class ServiceDetailPage extends StatelessWidget {
  final Service service;
  final CarWash carWash;

  const ServiceDetailPage({
    super.key,
    required this.service,
    required this.carWash,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text(service.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                carWash.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(service.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Price: Ksh${service.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, color: Colors.green)),
            const SizedBox(height: 20),
            Text(service.description, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  cart.add(service);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${service.name} added to cart')),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
