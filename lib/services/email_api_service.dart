import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailApiService {
  // Get email API URL from environment or use default production URL
  static String get _baseUrl =>
      dotenv.env['EMAIL_API_URL'] ?? 'https://unit-activity-backend.vercel.app';

  /// Send verification email
  Future<Map<String, dynamic>> sendVerificationEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/send-verification-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Email berhasil dikirim',
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Gagal mengirim email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Tidak dapat terhubung ke email service: ${e.toString()}',
      };
    }
  }

  /// Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/send-password-reset-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Email berhasil dikirim',
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Gagal mengirim email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Tidak dapat terhubung ke email service: ${e.toString()}',
      };
    }
  }

  /// Check if email service is available
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
