import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cars.dart';
import '../utilites/item.dart';
import '../utilites/provider.dart';

class BookingPopup extends StatefulWidget {
  final List<CartItem> cartItems;
  final CarWash carWash;
  final VoidCallback onComplete;

  const BookingPopup({
    required this.cartItems,
    required this.carWash,
    required this.onComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<BookingPopup> createState() => _BookingPopupState();
}

class _BookingPopupState extends State<BookingPopup> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDateTime;
  String? _paymentMethod;
  final List<String> _paymentMethods = ['Visa', 'PayPal', 'Mpesa'];

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _mpesaNumberController = TextEditingController();

  bool _isProcessingPayment = false;

  String? _validateMpesaNumber(String? value) {
    final trimmed = value?.trim() ?? '';
    final regExp = RegExp(r'^254\d{9}$'); // Must start with 254 and 9 digits follow

    if (trimmed.isEmpty) {
      return 'Please enter your Mpesa phone number';
    } else if (!regExp.hasMatch(trimmed)) {
      return 'Phone number must start with 254 and be 12 digits long';
    }
    return null;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _processMpesaPayment() async {
    setState(() {
      _isProcessingPayment = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessingPayment = false;
    });

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mpesa Payment'),
        content: Text(
          'Payment request sent to ${_mpesaNumberController.text.trim()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateTime == null || _paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date/time and payment method')),
      );
      return;
    }

    if ((_paymentMethod == 'Visa' || _paymentMethod == 'PayPal') &&
        _cardNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your $_paymentMethod card number')),
      );
      return;
    }

    if (_paymentMethod == 'Mpesa') {
      await _processMpesaPayment();
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.checkout(
      bookingDateTime: _selectedDateTime!,
      paymentMethod: _paymentMethod!,
      carWash: widget.carWash,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking successful!')),
    );

    widget.onComplete();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _mpesaNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateTimeText = _selectedDateTime == null
        ? 'Select Date & Time'
        : DateFormat('yyyy-MM-dd – HH:mm').format(_selectedDateTime!);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(dateTimeText),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Select Payment Method:', style: TextStyle(fontSize: 16)),
              ),
              ..._paymentMethods.map(
                (method) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Image.asset(
                            _getPaymentMethodImage(method),
                            width: 40,
                            height: 40,
                          ),
                          const SizedBox(width: 10),
                          Text(method),
                        ],
                      ),
                      value: method,
                      groupValue: _paymentMethod,
                      onChanged: (value) => setState(() {
                        _paymentMethod = value;
                        _cardNumberController.clear();
                        _mpesaNumberController.clear();
                      }),
                    ),
                    if ((_paymentMethod == 'Visa' || _paymentMethod == 'PayPal') &&
                        method == _paymentMethod)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _cardNumberController,
                          decoration: InputDecoration(
                            labelText: '${method} Card Number',
                            hintText: 'Enter your card number',
                            prefixIcon: const Icon(Icons.credit_card),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    if (_paymentMethod == 'Mpesa' && method == 'Mpesa')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          controller: _mpesaNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Mpesa Phone Number',
                            hintText: 'Enter your phone number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: _validateMpesaNumber,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isProcessingPayment ? null : _submitBooking,
                child: _isProcessingPayment
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodImage(String method) {
    switch (method) {
      case 'Visa':
        return 'assets/images/visa.png';
      case 'PayPal':
        return 'assets/images/pay.png';
      case 'Mpesa':
        return 'assets/images/mpesa.png';
      default:
        return '';
    }
  }
}
