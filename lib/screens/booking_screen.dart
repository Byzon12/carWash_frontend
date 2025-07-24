import 'package:flutter/material.dart';
import '../models/cars.dart';
import '../services/booking_service.dart' as booking_api;

class BookingScreen extends StatefulWidget {
  final Service service;
  final CarWash carWash;

  const BookingScreen({
    super.key,
    required this.service,
    required this.carWash,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String selectedPaymentMethod = 'Mobile Money';
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  bool isLoading = false;

  final List<String> paymentMethods = [
    'Mobile Money',
    'Cash on Service',
    'Credit/Debit Card',
  ];

  final List<TimeOfDay> availableTimeSlots = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 17, minute: 0),
  ];

  @override
  void dispose() {
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Summary Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.car_repair, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.service.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          'KSh ${widget.service.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.carWash.name,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Date Selection
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Tap to change date'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _selectDate(context),
              ),
            ),

            const SizedBox(height: 24),

            // Time Selection
            const Text(
              'Select Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: availableTimeSlots.length,
                itemBuilder: (context, index) {
                  final timeSlot = availableTimeSlots[index];
                  final isSelected = timeSlot == selectedTime;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTime = timeSlot;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected ? Colors.blue : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          timeSlot.format(context),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Payment Method
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              children:
                  paymentMethods.map((method) {
                    return Card(
                      child: RadioListTile<String>(
                        title: Text(method),
                        value: method,
                        groupValue: selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentMethod = value!;
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 24),

            // Phone Number
            const Text(
              'Phone Number',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter your phone number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 24),

            // Additional Notes
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special instructions or requests...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 32),

            // Total and Book Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'KSh ${widget.service.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          isLoading
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Processing...'),
                                ],
                              )
                              : const Text(
                                'Confirm Booking',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create booking request
      final bookingRequest = booking_api.BookingRequest(
        locationId: widget.carWash.id,
        locationServiceId: widget.service.id,
        scheduledDate: selectedDate,
        scheduledTime: selectedTime.format(context),
        customerPhone: phoneController.text.trim(),
        paymentMethod: selectedPaymentMethod,
        specialInstructions: notesController.text.trim(),
        totalAmount: widget.service.price,
      );

      print(
        '[DEBUG] BookingScreen: Creating booking with request: ${bookingRequest.toJson()}',
      );

      // Create the booking
      final booking = await booking_api.BookingService.createBooking(
        bookingRequest,
      );

      if (booking != null && mounted) {
        print(
          '[DEBUG] BookingScreen: Booking created successfully with ID: ${booking.id}',
        );

        // Validate that we have a valid booking ID
        if (booking.id <= 0) {
          print('[ERROR] BookingScreen: Invalid booking ID: ${booking.id}');
          throw Exception(
            'Booking was created but received invalid booking ID',
          );
        }

        // Show booking confirmation dialog with payment option
        _showBookingConfirmationDialog(booking);
      } else {
        throw Exception('Failed to create booking - no response from server');
      }
    } catch (e) {
      print('[ERROR] BookingScreen: Booking failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleMobilePayment(booking_api.Booking booking) async {
    try {
      print(
        '[DEBUG] BookingScreen: Initiating mobile payment for booking ${booking.id}',
      );
      print(
        '[DEBUG] BookingScreen: Booking object: id=${booking.id}, bookingNumber=${booking.bookingNumber}',
      );

      final paymentRequest = booking_api.PaymentInitiationRequest(
        bookingId: booking.id,
        phoneNumber: phoneController.text.trim(),
        paymentMethod: 'mpesa',
      );

      print(
        '[DEBUG] BookingScreen: Payment request created with bookingId: ${paymentRequest.bookingId}',
      );

      final paymentResponse = await booking_api.BookingService.initiatePayment(
        paymentRequest,
      );

      if (mounted) {
        if (paymentResponse.success) {
          // Show payment initiated dialog
          _showPaymentInitiatedDialog(booking, paymentResponse);
        } else {
          // Payment initiation failed, but booking was created
          _showBookingSuccessWithPaymentErrorDialog(
            booking,
            paymentResponse.message,
          );
        }
      }
    } catch (e) {
      print('[ERROR] BookingScreen: Payment initiation failed: $e');
      if (mounted) {
        // Payment failed, but booking was created
        _showBookingSuccessWithPaymentErrorDialog(booking, e.toString());
      }
    }
  }

  void _showPaymentInitiatedDialog(
    booking_api.Booking booking,
    booking_api.PaymentResponse paymentResponse,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.payment, color: Colors.orange, size: 30),
                SizedBox(width: 12),
                Text('Payment Initiated'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your booking has been created and payment has been initiated.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your phone for the M-Pesa payment prompt.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Number: ${booking.bookingNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Amount: KSh ${booking.totalAmount.toStringAsFixed(0)}',
                      ),
                      Text('Phone: ${booking.customerPhone}'),
                      if (paymentResponse.transactionId != null)
                        Text(
                          'Transaction ID: ${paymentResponse.transactionId}',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Note: You can view your booking status in the Bookings tab.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
    );
  }

  void _showBookingSuccessWithPaymentErrorDialog(
    booking_api.Booking booking,
    String errorMessage,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 30),
                SizedBox(width: 12),
                Text('Booking Created'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your booking has been created successfully, but there was an issue with payment initiation.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Number: ${booking.bookingNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Service: ${booking.locationServiceName}'),
                      Text(
                        'Amount: KSh ${booking.totalAmount.toStringAsFixed(0)}',
                      ),
                      Text('Status: ${booking.status.toUpperCase()}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Error:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You can retry payment later from the Bookings tab.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
    );
  }

  void _showBookingConfirmationDialog(booking_api.Booking booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 12),
                Text('Booking Created!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your booking has been created successfully. Please review the details below:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Number: ${booking.bookingNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Service', booking.locationServiceName),
                      _buildDetailRow(
                        'Date',
                        '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}',
                      ),
                      _buildDetailRow('Time', booking.scheduledTime),
                      _buildDetailRow('Location', widget.carWash.name),
                      _buildDetailRow(
                        'Amount',
                        'KSh ${booking.totalAmount.toStringAsFixed(0)}',
                      ),
                      _buildDetailRow('Payment Method', selectedPaymentMethod),
                      _buildDetailRow('Status', booking.status.toUpperCase()),
                      if (booking.specialInstructions.isNotEmpty)
                        _buildDetailRow(
                          'Special Instructions',
                          booking.specialInstructions,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedPaymentMethod == 'Mobile Money')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Click "Pay Now" to initiate M-Pesa payment for this booking.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              if (selectedPaymentMethod != 'Mobile Money')
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Complete'),
                ),
              if (selectedPaymentMethod == 'Mobile Money') ...[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Skip Payment'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close confirmation dialog
                    await _handleMobilePayment(booking);
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              // Additional action menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More Actions',
                onSelected: (action) async {
                  Navigator.of(context).pop(); // Close confirmation dialog
                  switch (action) {
                    case 'cancel':
                      await _cancelBooking(booking);
                      break;
                    case 'reschedule':
                      await _rescheduleBooking(booking);
                      break;
                    case 'retry_payment':
                      await _retryPayment(booking);
                      break;
                    case 'check_status':
                      await _checkPaymentStatus(booking);
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'reschedule',
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 20),
                            SizedBox(width: 8),
                            Text('Reschedule'),
                          ],
                        ),
                      ),
                      if (booking.paymentStatus == 'pending' ||
                          booking.paymentStatus == 'failed')
                        const PopupMenuItem(
                          value: 'retry_payment',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 20),
                              SizedBox(width: 8),
                              Text('Retry Payment'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'check_status',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Check Status'),
                          ],
                        ),
                      ),
                      if (booking.status != 'cancelled' &&
                          booking.status != 'completed')
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Cancel Booking',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ],
              ),
            ],
          ),
    );
  }

  // Cancel booking method
  Future<void> _cancelBooking(booking_api.Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Booking'),
            content: Text(
              'Are you sure you want to cancel booking ${booking.bookingNumber}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await booking_api.BookingService.cancelBooking(booking.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel booking: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Retry payment method
  Future<void> _retryPayment(booking_api.Booking booking) async {
    try {
      final paymentResponse = await booking_api.BookingService.retryPayment(
        booking.id,
        phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : booking.customerPhone,
      );

      if (mounted) {
        if (paymentResponse.success) {
          _showPaymentInitiatedDialog(booking, paymentResponse);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment retry failed: ${paymentResponse.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to retry payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Reschedule booking method
  Future<void> _rescheduleBooking(booking_api.Booking booking) async {
    DateTime? newDate;
    TimeOfDay? newTime;

    // Date picker
    newDate = await showDatePicker(
      context: context,
      initialDate: booking.scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (newDate == null) return;

    // Time picker
    newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(booking.scheduledDate),
    );

    if (newTime == null) return;

    try {
      final updatedBooking = await booking_api.BookingService.rescheduleBooking(
        booking.id,
        newDate,
        newTime.format(context),
      );

      if (mounted && updatedBooking != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rescheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reschedule booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check payment status method
  Future<void> _checkPaymentStatus(booking_api.Booking booking) async {
    try {
      final paymentStatus = await booking_api
          .BookingService.getBookingPaymentStatus(booking.id);

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Payment Status'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking: ${booking.bookingNumber}'),
                    Text(
                      'Payment Status: ${paymentStatus['payment_status'] ?? 'Unknown'}',
                    ),
                    Text(
                      'Payment Method: ${paymentStatus['payment_method'] ?? 'Unknown'}',
                    ),
                    if (paymentStatus['transaction_id'] != null)
                      Text(
                        'Transaction ID: ${paymentStatus['transaction_id']}',
                      ),
                    if (paymentStatus['last_updated'] != null)
                      Text('Last Updated: ${paymentStatus['last_updated']}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check payment status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
