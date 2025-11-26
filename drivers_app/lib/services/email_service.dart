import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../services/location_service.dart';

class EmailService {
  static Future<void> sendTimeoutAlert({
    required String driverName,
    required String driverId,
    required Position location,
  }) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': AppConstants.emailServiceId,
          'template_id': AppConstants.emailTemplateId,
          'user_id': AppConstants.emailPublicKey,
          'template_params': {
            'name': driverName,
            'driverId': driverId,
            'locationUrl': _getGoogleMapsUrl(location.latitude, location.longitude),
            'email': AppConstants.adminEmail,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Timeout alert email sent successfully');
      } else {
        print('Failed to send timeout alert email: ${response.body}');
        throw EmailServiceException('Failed to send email: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending timeout alert email: $e');
      throw EmailServiceException('Error sending email: $e');
    }
  }

  static String _getGoogleMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }
}

class EmailServiceException implements Exception {
  final String message;
  EmailServiceException(this.message);

  @override
  String toString() => 'EmailServiceException: $message';
}
