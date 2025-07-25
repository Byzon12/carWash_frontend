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
    print('[DEBUG] Booking.fromJson: Parsing booking data: $json');

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

    print(
      '[DEBUG] Booking.fromJson: Parsed booking ID: $bookingId from fields id=${json['id']}, booking_id=${json['booking_id']}',
    );

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
  static const String baseUrl = 'http://192.168.0.104:8000';
  static const String bookingEndpoint = '/booking';

  // Create a new booking
  static Future<Booking?> createBooking(BookingRequest request) async {
    print('[DEBUG] BookingService: Creating booking...');

    try {
      // Check connection first
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/create/');
      print('[DEBUG] BookingService: POST $url');
      print('[DEBUG] BookingService: Request data: ${request.toJson()}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');
      print('[DEBUG] BookingService: Response body: ${response.body}');

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
      print('[ERROR] BookingService: Error creating booking: $e');
      rethrow;
    }
  }

  // Get list of bookings for the authenticated user
  static Future<List<Booking>> getBookings() async {
    print('[DEBUG] BookingService: Fetching bookings...');

    try {
      // Check connection first
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        return _getFallbackBookings();
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        return [];
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/list/');
      print('[DEBUG] BookingService: GET $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle both list and paginated response formats
        if (responseData is List) {
          print(
            '[DEBUG] BookingService: Found ${responseData.length} bookings',
          );
          return responseData.map((json) => Booking.fromJson(json)).toList();
        } else if (responseData is Map && responseData.containsKey('results')) {
          // Handle paginated response
          final List<dynamic> data = responseData['results'];
          print(
            '[DEBUG] BookingService: Found ${data.length} bookings (paginated)',
          );
          return data.map((json) => Booking.fromJson(json)).toList();
        } else {
          print('[WARNING] BookingService: Unexpected response format');
          return [];
        }
      } else {
        print(
          '[ERROR] BookingService: Failed to fetch bookings: ${response.statusCode}',
        );
        return _getFallbackBookings();
      }
    } catch (e) {
      print('[ERROR] BookingService: Error fetching bookings: $e');
      return _getFallbackBookings();
    }
  }

  // Get specific booking details
  static Future<Booking?> getBookingDetails(int bookingId) async {
    print(
      '[DEBUG] BookingService: Fetching booking details for ID: $bookingId',
    );

    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        return null;
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        return null;
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/$bookingId/');
      print('[DEBUG] BookingService: GET $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');

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
        print(
          '[ERROR] BookingService: Failed to fetch booking details: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('[ERROR] BookingService: Error fetching booking details: $e');
      return null;
    }
  }

  // Cancel a booking
  static Future<bool> cancelBooking(int bookingId) async {
    print('[DEBUG] BookingService: Cancelling booking ID: $bookingId');

    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/$bookingId/cancel/');
      print('[DEBUG] BookingService: POST $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[DEBUG] BookingService: Booking cancelled successfully');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      print('[ERROR] BookingService: Error cancelling booking: $e');
      rethrow;
    }
  }

  // Delete a booking permanently
  static Future<bool> deleteBooking(int bookingId) async {
    print('[DEBUG] BookingService: Deleting booking ID: $bookingId');

    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/delete/$bookingId/');
      print('[DEBUG] BookingService: DELETE $url');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[DEBUG] BookingService: Booking deleted successfully');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete booking');
      }
    } catch (e) {
      print('[ERROR] BookingService: Error deleting booking: $e');
      rethrow;
    }
  }

  // Initiate payment for a booking
  static Future<PaymentResponse> initiatePayment(
    PaymentInitiationRequest request,
  ) async {
    print('[DEBUG] BookingService: Initiating payment...');

    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/payment/initiate/');
      print('[DEBUG] BookingService: POST $url');
      print('[DEBUG] BookingService: Payment request: ${request.toJson()}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');
      print('[DEBUG] BookingService: Response body: ${response.body}');

      final data = jsonDecode(response.body);
      return PaymentResponse.fromJson(data);
    } catch (e) {
      print('[ERROR] BookingService: Error initiating payment: $e');
      rethrow;
    }
  }

  // Check payment status
  static Future<PaymentResponse> checkPaymentStatus(
    String checkoutRequestId,
  ) async {
    print(
      '[DEBUG] BookingService: Checking payment status for: $checkoutRequestId',
    );

    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse(
        '$baseUrl$bookingEndpoint/payment/status/?checkout_request_id=$checkoutRequestId',
      );
      print('[DEBUG] BookingService: GET $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);
      return PaymentResponse.fromJson(data);
    } catch (e) {
      print('[ERROR] BookingService: Error checking payment status: $e');
      rethrow;
    }
  }

  // Update booking details
  static Future<Booking?> updateBooking(
    int bookingId,
    BookingRequest request,
  ) async {
    print('[DEBUG] BookingService: Updating booking ID: $bookingId');

    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/$bookingId/update/');
      print('[DEBUG] BookingService: PUT $url');
      print('[DEBUG] BookingService: Update data: ${request.toJson()}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');
      print('[DEBUG] BookingService: Response body: ${response.body}');

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
      print('[ERROR] BookingService: Error updating booking: $e');
      rethrow;
    }
  }

  // Retry payment for a booking
  static Future<PaymentResponse> retryPayment(
    int bookingId,
    String phoneNumber,
  ) async {
    print(
      '[DEBUG] BookingService: Retrying payment for booking ID: $bookingId',
    );

    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse(
        '$baseUrl$bookingEndpoint/$bookingId/payment/retry/',
      );
      print('[DEBUG] BookingService: POST $url');

      final requestData = {
        'phone_number': phoneNumber,
        'payment_method': 'mpesa',
      };

      print('[DEBUG] BookingService: Retry payment request: $requestData');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');
      print('[DEBUG] BookingService: Response body: ${response.body}');

      final data = jsonDecode(response.body);
      return PaymentResponse.fromJson(data);
    } catch (e) {
      print('[ERROR] BookingService: Error retrying payment: $e');
      rethrow;
    }
  }

  // Get booking payment status
  static Future<Map<String, dynamic>> getBookingPaymentStatus(
    int bookingId,
  ) async {
    print(
      '[DEBUG] BookingService: Getting payment status for booking ID: $bookingId',
    );

    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse(
        '$baseUrl$bookingEndpoint/$bookingId/payment/status/',
      );
      print('[DEBUG] BookingService: GET $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to get payment status');
      }
    } catch (e) {
      print('[ERROR] BookingService: Error getting payment status: $e');
      rethrow;
    }
  }

  // Reschedule booking
  static Future<Booking?> rescheduleBooking(
    int bookingId,
    DateTime newDate,
    String newTime,
  ) async {
    print('[DEBUG] BookingService: Rescheduling booking ID: $bookingId');

    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        throw Exception(
          'Backend server is not reachable. Please check your connection.',
        );
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('$baseUrl$bookingEndpoint/$bookingId/reschedule/');
      print('[DEBUG] BookingService: POST $url');

      final requestData = {
        'booking_date': newDate.toIso8601String().split('T')[0],
        'booking_time': newTime,
      };

      print('[DEBUG] BookingService: Reschedule request: $requestData');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');
      print('[DEBUG] BookingService: Response body: ${response.body}');

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
      print('[ERROR] BookingService: Error rescheduling booking: $e');
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
    print('[DEBUG] BookingService: Fetching booking history with filters...');

    try {
      final isConnected = await ConnectionService.isBackendAvailable();
      if (!isConnected) {
        print('[ERROR] BookingService: No backend connection available');
        return _getFallbackBookings();
      }

      final token = await ApiConnect.getAccessToken();
      if (token == null) {
        print('[ERROR] BookingService: No authentication token found');
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

      print('[DEBUG] BookingService: GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[DEBUG] BookingService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List) {
          return responseData.map((json) => Booking.fromJson(json)).toList();
        } else if (responseData is Map && responseData.containsKey('results')) {
          final List<dynamic> data = responseData['results'];
          return data.map((json) => Booking.fromJson(json)).toList();
        } else {
          print('[WARNING] BookingService: Unexpected response format');
          return [];
        }
      } else {
        print(
          '[ERROR] BookingService: Failed to fetch booking history: ${response.statusCode}',
        );
        return _getFallbackBookings();
      }
    } catch (e) {
      print('[ERROR] BookingService: Error fetching booking history: $e');
      return _getFallbackBookings();
    }
  }

  // Fallback data for offline scenarios
  static List<Booking> _getFallbackBookings() {
    print('[DEBUG] BookingService: Using fallback booking data');

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
