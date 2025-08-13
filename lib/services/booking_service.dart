import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/connection_service.dart';
import '../api/api_connect.dart';

// Booking model classes
class BookingRequest {
  final String locationId;
  final String locationServiceId;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String customerPhone;
  final String paymentMethod;
  final String? specialInstructions;
  final double totalAmount;

  BookingRequest({
    required this.locationId,
    required this.locationServiceId,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.customerPhone,
    required this.paymentMethod,
    this.specialInstructions,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'location': locationId,
      'location_service': locationServiceId,
      'booking_date':
          scheduledDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'booking_time': scheduledTime,
      'customer_phone': customerPhone,
      'payment_method': _mapPaymentMethod(paymentMethod),
      'special_instructions': specialInstructions ?? '',
      'total_amount': totalAmount,
    };
  }

  String _mapPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'mobile money':
        return 'mpesa';
      case 'cash on service':
        return 'cash';
      case 'credit/debit card':
        return 'card';
      default:
        return 'cash';
    }
  }
}

class Booking {
  final int id;
  final String locationService;
  final String locationServiceName;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String customerPhone;
  final String paymentMethod;
  final String specialInstructions;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String bookingNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.locationService,
    required this.locationServiceName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.customerPhone,
    required this.paymentMethod,
    required this.specialInstructions,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.bookingNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Parse booking ID more robustly - try multiple possible field names
    int bookingId = 0;

    // Try 'id' field first
    if (json['id'] != null) {
      if (json['id'] is int) {
        bookingId = json['id'];
      } else if (json['id'] is String) {
        bookingId = int.tryParse(json['id']) ?? 0;
      } else {
        bookingId = int.tryParse(json['id'].toString()) ?? 0;
      }
    }

    // If id is 0 or not found, try 'booking_id' field
    if (bookingId == 0 && json['booking_id'] != null) {
      if (json['booking_id'] is int) {
        bookingId = json['booking_id'];
      } else if (json['booking_id'] is String) {
        bookingId = int.tryParse(json['booking_id']) ?? 0;
      } else {
        bookingId = int.tryParse(json['booking_id'].toString()) ?? 0;
      }
    }

    return Booking(
      id: bookingId,
      locationService:
          json['location']?.toString() ??
          json['location_service']?.toString() ??
          '',
      locationServiceName:
          json['location_name']?.toString() ??
          json['location_service_name']?.toString() ??
          json['service_details']?['name']?.toString() ??
          '',
      scheduledDate:
          DateTime.tryParse(
            json['booking_date']?.toString() ??
                json['scheduled_date']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      scheduledTime:
          json['booking_time']?.toString() ??
          json['scheduled_time']?.toString() ??
          '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      specialInstructions: json['special_instructions']?.toString() ?? '',
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      bookingNumber: json['booking_number']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class PaymentInitiationRequest {
  final int bookingId;
  final String phoneNumber;
  final String paymentMethod;

  PaymentInitiationRequest({
    required this.bookingId,
    required this.phoneNumber,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'payment_method': paymentMethod,
      'phone_number': phoneNumber,
    };
  }
}

class PaymentResponse {
  final bool success;
  final String message;
  final String? transactionId;
  final String? checkoutRequestId;

  PaymentResponse({
    required this.success,
    required this.message,
    this.transactionId,
    this.checkoutRequestId,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString(),
      checkoutRequestId: json['checkout_request_id']?.toString(),
    );
  }
}

class BookingService {
  // Use ApiConnect's dynamic base URL instead of hardcoded URL
  static String get baseUrl => ApiConnect.bookingBaseUrl;
  static const String bookingEndpoint = 'booking';

  // Create a new booking
  static Future<Booking?> createBooking(BookingRequest request) async {
    try {
      // Check connection first
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/create/');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Extract the actual booking data from the response
        if (responseData['data'] != null) {
          return Booking.fromJson(responseData['data']);
        } else {
          // Fallback: try to parse the entire response as booking data
          return Booking.fromJson(responseData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get list of bookings for the authenticated user
  static Future<List<Booking>> getBookings() async {
    try {
      // Check connection first
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        return _getFallbackBookings();
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        return [];
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/list/');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle both list and paginated response formats
        if (responseData is List) {
          return responseData.map((json) => Booking.fromJson(json)).toList();
        } else if (responseData is Map && responseData.containsKey('results')) {
          // Handle paginated response
          final List<dynamic> data = responseData['results'];
          return data.map((json) => Booking.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        return _getFallbackBookings();
      }
    } catch (e) {
      return _getFallbackBookings();
    }
  }

  // Get specific booking details
  static Future<Booking?> getBookingDetails(int bookingId) async {
    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        return null;
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        return null;
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/$bookingId/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle response structure - check if data is nested
        if (responseData['data'] != null) {
          return Booking.fromJson(responseData['data']);
        } else {
          // Fallback: try to parse the entire response as booking data
          return Booking.fromJson(responseData);
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Cancel a booking
  static Future<bool> cancelBooking(int bookingId) async {
    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/$bookingId/cancel/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete a booking permanently
  static Future<bool> deleteBooking(int bookingId) async {
    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/delete/$bookingId/');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete booking');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Initiate payment for a booking
  static Future<PaymentResponse> initiatePayment(
    PaymentInitiationRequest request,
  ) async {
    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/payment/initiate/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );
      final data = jsonDecode(response.body);
      return PaymentResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Check payment status
  static Future<PaymentResponse> checkPaymentStatus(
    String checkoutRequestId,
  ) async {
    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse(
        '$baseUrl$bookingEndpoint/payment/status/?checkout_request_id=$checkoutRequestId',
      );
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      return PaymentResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Update booking details
  static Future<Booking?> updateBooking(
    int bookingId,
    BookingRequest request,
  ) async {
    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/$bookingId/update/');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle response structure - check if data is nested
        if (responseData['data'] != null) {
          return Booking.fromJson(responseData['data']);
        } else {
          // Fallback: try to parse the entire response as booking data
          return Booking.fromJson(responseData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update booking');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Retry payment for a booking
  static Future<PaymentResponse> retryPayment(
    int bookingId,
    String phoneNumber,
  ) async {
    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse(
        '$baseUrl$bookingEndpoint/$bookingId/payment/retry/',
      );
      final requestData = {
        'phone_number': phoneNumber,
        'payment_method': 'mpesa',
      };
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );
      final data = jsonDecode(response.body);
      return PaymentResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Get booking payment status
  static Future<Map<String, dynamic>> getBookingPaymentStatus(
    int bookingId,
  ) async {
    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse(
        '$baseUrl$bookingEndpoint/$bookingId/payment/status/',
      );
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to get payment status');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Reschedule booking
  static Future<Booking?> rescheduleBooking(
    int bookingId,
    DateTime newDate,
    String newTime,
  ) async {
    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/$bookingId/reschedule/');
      final requestData = {
        'booking_date': newDate.toIso8601String().split('T')[0],
        'booking_time': newTime,
      };
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle response structure - check if data is nested
        if (responseData['data'] != null) {
          return Booking.fromJson(responseData['data']);
        } else {
          // Fallback: try to parse the entire response as booking data
          return Booking.fromJson(responseData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to reschedule booking');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get booking history with filters
  static Future<List<Booking>> getBookingHistory({
    String? status,
    String? paymentStatus,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        return _getFallbackBookings();
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        return [];
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(
        '$baseUrl$bookingEndpoint/history/',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List) {
          return responseData.map((json) => Booking.fromJson(json)).toList();
        } else if (responseData is Map && responseData.containsKey('results')) {
          final List<dynamic> data = responseData['results'];
          return data.map((json) => Booking.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        return _getFallbackBookings();
      }
    } catch (e) {
      return _getFallbackBookings();
    }
  }

  // Fallback data for offline scenarios
  static List<Booking> _getFallbackBookings() {
    return [
      Booking(
        id: 1,
        locationService: '1',
        locationServiceName: 'Premium Package (Offline)',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        scheduledTime: '10:00 AM',
        customerPhone: '+254712345678',
        paymentMethod: 'mobile_money',
        specialInstructions: 'Please call when you arrive',
        totalAmount: 1000.0,
        status: 'confirmed',
        paymentStatus: 'pending',
        bookingNumber: 'BK202507240001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Booking(
        id: 2,
        locationService: '2',
        locationServiceName: 'Basic Wash (Offline)',
        scheduledDate: DateTime.now().add(const Duration(days: 3)),
        scheduledTime: '2:00 PM',
        customerPhone: '+254712345678',
        paymentMethod: 'cash',
        specialInstructions: '',
        totalAmount: 500.0,
        status: 'pending',
        paymentStatus: 'pending',
        bookingNumber: 'BK202507240002',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
