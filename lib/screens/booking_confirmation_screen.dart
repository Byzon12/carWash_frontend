import 'package:flutter/material.dart';
import '../services/booking_service.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Booking booking;
  final String selectedPaymentMethod;
  final String customerPhone;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.selectedPaymentMethod,
    required this.customerPhone,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Payment status tracking
  String? _currentPaymentStatus;
  bool _isCheckingPaymentStatus = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Initialize payment status and check if needed
    _currentPaymentStatus = widget.booking.paymentStatus;
    if (_shouldShowPaymentRetry()) {
      _checkPaymentStatus();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _shouldShowPaymentRetry() {
    final isMobilePayment =
        widget.selectedPaymentMethod.toLowerCase().contains('mobile') ||
        widget.selectedPaymentMethod.toLowerCase().contains('mpesa') ||
        widget.selectedPaymentMethod.toLowerCase().contains('m-pesa') ||
        widget.selectedPaymentMethod.toLowerCase() == 'm-pesa' ||
        widget.booking.paymentMethod == 'mpesa' ||
        widget.booking.paymentMethod == 'mobile_money' ||
        widget.booking.paymentMethod.toLowerCase().contains('mpesa');

    final needsRetry =
        _currentPaymentStatus == 'pending' ||
        _currentPaymentStatus == 'failed' ||
        widget.booking.paymentStatus == 'pending' ||
        widget.booking.paymentStatus == 'failed';

    print(
      '[DEBUG] _shouldShowPaymentRetry: isMobilePayment=$isMobilePayment, needsRetry=$needsRetry',
    );
    print(
      '[DEBUG] _currentPaymentStatus=$_currentPaymentStatus, booking.paymentStatus=${widget.booking.paymentStatus}',
    );
    print(
      '[DEBUG] selectedPaymentMethod="${widget.selectedPaymentMethod}", booking.paymentMethod="${widget.booking.paymentMethod}"',
    );

    return needsRetry && isMobilePayment;
  }

  Future<void> _checkPaymentStatus() async {
    if (_isCheckingPaymentStatus) return;

    setState(() {
      _isCheckingPaymentStatus = true;
    });

    try {
      final paymentStatusData = await BookingService.getBookingPaymentStatus(
        widget.booking.id,
      );

      if (mounted) {
        setState(() {
          _currentPaymentStatus =
              paymentStatusData['payment_status'] ??
              widget.booking.paymentStatus;
          _isCheckingPaymentStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingPaymentStatus = false;
        });
      }
      print('[ERROR] Failed to check payment status: $e');
    }
  }

  Future<void> _retryPayment() async {
    try {
      print(
        '[DEBUG] Starting payment retry for booking ID: ${widget.booking.id}',
      );

      // Show phone number input dialog if needed
      String phoneNumber = widget.customerPhone;

      if (phoneNumber.isEmpty) {
        final controller = TextEditingController();
        final newPhoneNumber = await showDialog<String>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.phone, color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Text('Retry Payment'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Please enter your phone number to retry M-Pesa payment:',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '0700123456',
                        prefixText: '+254 ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.pop(context, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Retry Payment'),
                  ),
                ],
              ),
        );

        if (newPhoneNumber == null || newPhoneNumber.isEmpty) return;
        phoneNumber = newPhoneNumber;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Retrying M-Pesa payment...',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait while we process your payment',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
      );

      final paymentResponse = await BookingService.retryPayment(
        widget.booking.id,
        phoneNumber,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (paymentResponse.success) {
          setState(() {
            _currentPaymentStatus = 'pending'; // Update local status
          });
          _showPaymentInitiatedDialog(paymentResponse);
        } else {
          _showPaymentErrorDialog(paymentResponse.message);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showPaymentErrorDialog(e.toString());
      }
    }
  }

  void _showPaymentInitiatedDialog(PaymentResponse response) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Payment Initiated'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(response.message),
                const SizedBox(height: 16),
                const Text(
                  'Please check your phone for the payment request and follow the prompts to complete the payment.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _checkPaymentStatus(); // Refresh payment status
                },
                child: const Text('Check Status'),
              ),
            ],
          ),
    );
  }

  void _showPaymentErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.error, color: Colors.red, size: 48),
            title: const Text('Payment Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(errorMessage),
                const SizedBox(height: 16),
                const Text(
                  'You can try again or contact support for assistance.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _retryPayment(); // Try again
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print payment method to help with troubleshooting
    print('[DEBUG] Selected Payment Method: "${widget.selectedPaymentMethod}"');
    print('[DEBUG] Booking Payment Method: "${widget.booking.paymentMethod}"');
    print('[DEBUG] Current Payment Status: "$_currentPaymentStatus"');
    print('[DEBUG] Should Show Retry: ${_shouldShowPaymentRetry()}');

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text(
          'Booking Confirmed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed:
              () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Success Animation
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Success Message
                    const Text(
                      'Booking Created Successfully!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your car wash booking has been confirmed. Please review the details below.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Booking Details Card
                    Card(
                      elevation: 8,
                      shadowColor: Colors.green.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.green.shade50],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_number,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Booking Details',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Booking Number (Highlighted)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Booking Number',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.booking.bookingNumber,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Other Details
                            _buildDetailRow(
                              Icons.car_repair,
                              'Service',
                              widget.booking.locationServiceName,
                            ),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Date',
                              '${widget.booking.scheduledDate.day}/${widget.booking.scheduledDate.month}/${widget.booking.scheduledDate.year}',
                            ),
                            _buildDetailRow(
                              Icons.access_time,
                              'Time',
                              widget.booking.scheduledTime,
                            ),
                            _buildDetailRow(
                              Icons.attach_money,
                              'Amount',
                              'KSh ${widget.booking.totalAmount.toStringAsFixed(0)}',
                            ),
                            _buildDetailRow(
                              Icons.payment,
                              'Payment Method',
                              widget.selectedPaymentMethod,
                            ),
                            _buildDetailRow(
                              Icons.info_outline,
                              'Status',
                              widget.booking.status.toUpperCase(),
                            ),
                            if (widget.booking.specialInstructions.isNotEmpty)
                              _buildDetailRow(
                                Icons.note,
                                'Special Instructions',
                                widget.booking.specialInstructions,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Retry Notice (for pending/failed payments)
                    if (_shouldShowPaymentRetry())
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              _currentPaymentStatus == 'failed'
                                  ? Colors.red.shade50
                                  : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _currentPaymentStatus == 'failed'
                                    ? Colors.red.shade300
                                    : Colors.orange.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _currentPaymentStatus == 'failed'
                                      ? Icons.error
                                      : Icons.schedule,
                                  color:
                                      _currentPaymentStatus == 'failed'
                                          ? Colors.red.shade600
                                          : Colors.orange.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _currentPaymentStatus == 'failed'
                                        ? 'Payment Failed'
                                        : 'Payment Pending',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _currentPaymentStatus == 'failed'
                                              ? Colors.red.shade700
                                              : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentPaymentStatus == 'failed'
                                  ? 'Your M-Pesa payment was not completed. Please try again.'
                                  : 'Your M-Pesa payment is still being processed. You can retry if needed.',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    _currentPaymentStatus == 'failed'
                                        ? Colors.red.shade600
                                        : Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Payment Notice (if Mobile Money)
                    if (widget.selectedPaymentMethod.toLowerCase().contains(
                          'mobile',
                        ) ||
                        widget.selectedPaymentMethod.toLowerCase().contains(
                          'mpesa',
                        ) ||
                        widget.selectedPaymentMethod.toLowerCase().contains(
                          'm-pesa',
                        ))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.orange.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Click "Make Payment" below to initiate M-Pesa payment for this booking.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Quick Retry Button (for pending/failed payments)
                    if (_shouldShowPaymentRetry())
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton.icon(
                          onPressed: _retryPayment,
                          icon: const Icon(Icons.refresh, size: 20),
                          label: Text(
                            _currentPaymentStatus == 'failed'
                                ? 'Retry Failed Payment'
                                : 'Retry Pending Payment',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _currentPaymentStatus == 'failed'
                                    ? Colors.red.shade600
                                    : Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),

                    // Action Buttons
                    Column(
                      children: [
                        // Primary Actions
                        Row(
                          children: [
                            // Edit Details Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _editBookingDetails(),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Details'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Make Payment Button (if Mobile Money)
                            if (widget.selectedPaymentMethod
                                    .toLowerCase()
                                    .contains('mobile') ||
                                widget.selectedPaymentMethod
                                    .toLowerCase()
                                    .contains('mpesa') ||
                                widget.selectedPaymentMethod
                                    .toLowerCase()
                                    .contains('m-pesa'))
                              Expanded(
                                child: Column(
                                  children: [
                                    // Show current payment status
                                    if (_currentPaymentStatus != 'paid')
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _currentPaymentStatus == 'pending'
                                                  ? Colors.orange.shade50
                                                  : _currentPaymentStatus ==
                                                      'failed'
                                                  ? Colors.red.shade50
                                                  : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                _currentPaymentStatus ==
                                                        'pending'
                                                    ? Colors.orange.shade200
                                                    : _currentPaymentStatus ==
                                                        'failed'
                                                    ? Colors.red.shade200
                                                    : Colors.blue.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _currentPaymentStatus == 'pending'
                                                  ? Icons.schedule
                                                  : _currentPaymentStatus ==
                                                      'failed'
                                                  ? Icons.error
                                                  : Icons.info,
                                              size: 16,
                                              color:
                                                  _currentPaymentStatus ==
                                                          'pending'
                                                      ? Colors.orange.shade600
                                                      : _currentPaymentStatus ==
                                                          'failed'
                                                      ? Colors.red.shade600
                                                      : Colors.blue.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _currentPaymentStatus == 'pending'
                                                  ? 'Payment Pending'
                                                  : _currentPaymentStatus ==
                                                      'failed'
                                                  ? 'Payment Failed'
                                                  : 'Payment Required',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    _currentPaymentStatus ==
                                                            'pending'
                                                        ? Colors.orange.shade600
                                                        : _currentPaymentStatus ==
                                                            'failed'
                                                        ? Colors.red.shade600
                                                        : Colors.blue.shade600,
                                              ),
                                            ),
                                            if (_isCheckingPaymentStatus) ...[
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(
                                                        _currentPaymentStatus ==
                                                                'pending'
                                                            ? Colors
                                                                .orange
                                                                .shade600
                                                            : _currentPaymentStatus ==
                                                                'failed'
                                                            ? Colors
                                                                .red
                                                                .shade600
                                                            : Colors
                                                                .blue
                                                                .shade600,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                    // Payment button
                                    ElevatedButton.icon(
                                      onPressed: _makePayment,
                                      icon: const Icon(Icons.payment),
                                      label: const Text('Make Payment'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Check status button (if payment is pending or failed)
                                    if (_shouldShowPaymentRetry())
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: TextButton.icon(
                                          onPressed:
                                              _isCheckingPaymentStatus
                                                  ? null
                                                  : _checkPaymentStatus,
                                          icon: const Icon(
                                            Icons.refresh,
                                            size: 16,
                                          ),
                                          label: const Text('Check Status'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            // Complete Button (if not Mobile Money)
                            if (!(widget.selectedPaymentMethod
                                    .toLowerCase()
                                    .contains('mobile') ||
                                widget.selectedPaymentMethod
                                    .toLowerCase()
                                    .contains('mpesa') ||
                                widget.selectedPaymentMethod
                                    .toLowerCase()
                                    .contains('m-pesa')))
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _completeBooking(),
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Complete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Secondary Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _viewBookingHistory(),
                                icon: const Icon(Icons.history),
                                label: const Text('View History'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _goToHome(),
                                icon: const Icon(Icons.home),
                                label: const Text('Go to Home'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editBookingDetails() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Booking'),
            content: const Text(
              'This feature allows you to modify your booking details. Would you like to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to edit booking screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit booking feature coming soon!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text('Edit'),
              ),
            ],
          ),
    );
  }

  Future<void> _makePayment() async {
    try {
      final paymentRequest = PaymentInitiationRequest(
        bookingId: widget.booking.id,
        phoneNumber: widget.customerPhone,
        paymentMethod: 'mpesa',
      );

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initiating payment...'),
                ],
              ),
            ),
      );

      final paymentResponse = await BookingService.initiatePayment(
        paymentRequest,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (paymentResponse.success) {
          _showPaymentInitiatedDialog(paymentResponse);
        } else {
          _showPaymentErrorDialog(paymentResponse.message);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showPaymentErrorDialog(e.toString());
      }
    }
  }

  void _completeBooking() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 12),
                Text('Booking Complete'),
              ],
            ),
            content: Text(
              'Your booking ${widget.booking.bookingNumber} has been created successfully. You can view and manage your bookings in the Bookings tab.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _goToHome();
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
    );
  }

  void _viewBookingHistory() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    // TODO: Navigate to bookings tab
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigating to booking history...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _goToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
