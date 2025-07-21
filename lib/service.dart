import 'package:flutter/material.dart';
import 'package:flutter_application_1/utilites/provider.dart';
import 'package:provider/provider.dart';
import 'models/cars.dart';


class ServicesPage extends StatelessWidget {
  final CarWash carWash;

  const ServicesPage({super.key, required this.carWash});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text(carWash.name)),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: carWash.services.length,
        itemBuilder: (context, index) {
          final service = carWash.services[index];
          return Card(
            child: ListTile(
              title: Text(service.name),
              subtitle: Text(service.description),
              trailing: Text('Ksh${service.price.toStringAsFixed(2)}'),
              onTap: () {
                cart.add(service);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${service.name} added to cart')),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/cart');
        },
        child: const Icon(Icons.shopping_cart),
      ),
    );
  }
}
