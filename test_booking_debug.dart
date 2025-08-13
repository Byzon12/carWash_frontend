import 'lib/services/booking_service.dart';
import 'lib/api/api_connect.dart';

void main() async {
  print('=== BOOKING DEBUG TEST ===');

  // Test URL construction
  print('BookingService base URL: ${BookingService.baseUrl}');
  print('ApiConnect booking base URL: ${ApiConnect.bookingBaseUrl}');

  // Test some example URLs
  print(
    'Create booking URL: ${BookingService.baseUrl}${BookingService.bookingEndpoint}/create/',
  );
  print(
    'List booking URL: ${BookingService.baseUrl}${BookingService.bookingEndpoint}/list/',
  );

  print('=== END DEBUG TEST ===');
}
