import 'package:flutter/material.dart';
import 'package:flutter_application_1/pop.dart';
import 'package:flutter_application_1/utilites/provider.dart';
import 'package:provider/provider.dart';
import '../models/cars.dart'; // Import CarWash model

class CartPage extends StatelessWidget {
  final CarWash carWash; // Pass the CarWash to CartPage

  const CartPage({Key? key, required this.carWash}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return ListTile(
                        title: Text(item.service.name),
                        subtitle: Text('Ksh ${item.service.price.toStringAsFixed(2)} x ${item.quantity}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => cart.remove(item.service),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: Theme.of(context).textTheme.titleLarge),
                      Text('Ksh ${cart.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton(
                    onPressed: cart.isEmpty
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom,
                                ),
                                child: BookingPopup(
                                  cartItems: cart.items,
                                  carWash: carWash,
                                  onComplete: () {
                                    cart.clear();
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            );
                          },
                    child: const Text('Proceed to Pay'),
                  ),
                ),
              ],
            ),
    );
  }
}
