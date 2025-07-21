import '../models/cars.dart';

class CartItem {
  final Service service;
  int quantity;

  CartItem({required this.service, this.quantity = 1});
}
