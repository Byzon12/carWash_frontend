import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/cars.dart';
import 'item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final List<Booking> _bookings = [];
  final _uuid = Uuid();

  List<CartItem> get items => List.unmodifiable(_items);
  List<Booking> get bookings => List.unmodifiable(_bookings);

  double get total =>
      _items.fold(0, (sum, item) => sum + item.service.price * item.quantity);

  bool get isEmpty => _items.isEmpty;

  void add(Service service) {
    final index = _items.indexWhere((item) => item.service.id == service.id);
    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(service: service));
    }
    notifyListeners();
  }

  void remove(Service service) {
    _items.removeWhere((item) => item.service.id == service.id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void addBookings(List<Booking> newBookings) {
    _bookings.addAll(newBookings);
    notifyListeners();
  }

  void removeBooking(Booking booking) {
    _bookings.removeWhere((b) => b.id == booking.id);
    notifyListeners();
  }

  void checkout({
    required DateTime bookingDateTime,
    required String paymentMethod,
    required CarWash carWash,
  }) {
    if (_items.isEmpty) return;

    final newBookings =
        _items.map((cartItem) {
          return Booking(
            id: _uuid.v4(),
            carWash: carWash,
            service: cartItem.service,
            dateTime: bookingDateTime,
            paymentMethod: paymentMethod,
            quantity: cartItem.quantity,
          );
        }).toList();

    addBookings(newBookings);
    clear();
  }
}
