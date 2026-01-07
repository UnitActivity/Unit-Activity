import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service untuk generate dan validate QR code dinamis
/// QR code berganti setiap 10 detik dengan timestamp validation
class DynamicQRService {
  // Secret key untuk signing QR code (harus sama di server dan client)
  static const String _secretKey = 'UKM_UNIT_ACTIVITY_2026_SECRET';

  // QR code valid window (dalam detik)
  static const int _validityWindow = 10;

  // Grace period untuk network delay (dalam detik)
  static const int _gracePeriod = 5;

  /// Generate dynamic QR code dengan timestamp
  /// Format: TYPE:ID:TIMESTAMP:SIGNATURE
  static String generateDynamicQR({
    required String type, // 'EVENT' atau 'PERTEMUAN'
    required String id, // ID event atau pertemuan
    required String? additionalData, // Data tambahan (opsional)
  }) {
    // Get current timestamp (rounded to 10 second interval)
    final now = DateTime.now();
    final timestamp = _roundToInterval(now, _validityWindow);

    // Create payload
    final payload = '$type:$id:$timestamp';

    // Create signature
    final signature = _createSignature(payload);

    // Return QR code
    return '$payload:$signature';
  }

  /// Validate dynamic QR code
  /// Returns validation result with error message if invalid
  static Map<String, dynamic> validateDynamicQR(String qrCode) {
    try {
      final parts = qrCode.split(':');

      if (parts.length < 4) {
        return {
          'valid': false,
          'message': 'Format QR Code tidak valid.',
          'error_type': 'INVALID_FORMAT',
        };
      }

      final type = parts[0];
      final id = parts[1];
      final timestampStr = parts[2];
      final signature = parts[3];

      // Parse timestamp
      final qrTimestamp = int.tryParse(timestampStr);
      if (qrTimestamp == null) {
        return {
          'valid': false,
          'message': 'QR Code rusak atau tidak valid.',
          'error_type': 'INVALID_TIMESTAMP',
        };
      }

      // Validate signature
      final payload = '$type:$id:$timestampStr';
      final expectedSignature = _createSignature(payload);

      if (signature != expectedSignature) {
        return {
          'valid': false,
          'message': 'QR Code tidak valid atau telah dimodifikasi.',
          'error_type': 'INVALID_SIGNATURE',
        };
      }

      // Check timestamp validity
      final now = DateTime.now();
      final currentTimestamp = now.millisecondsSinceEpoch ~/ 1000;
      final timeDiff = (currentTimestamp - qrTimestamp).abs();

      // Allow grace period for network delay
      if (timeDiff > (_validityWindow + _gracePeriod)) {
        return {
          'valid': false,
          'message':
              'QR Code sudah kadaluarsa. Silakan scan QR Code yang baru.',
          'error_type': 'EXPIRED',
          'expired_seconds_ago': timeDiff - _validityWindow,
        };
      }

      // Valid QR code
      return {
        'valid': true,
        'type': type,
        'id': id,
        'timestamp': qrTimestamp,
        'scanned_at': currentTimestamp,
        'age_seconds': timeDiff,
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Gagal memvalidasi QR Code: ${e.toString()}',
        'error_type': 'VALIDATION_ERROR',
      };
    }
  }

  /// Check if QR code is still valid (quick check)
  static bool isQRCodeValid(String qrCode) {
    final result = validateDynamicQR(qrCode);
    return result['valid'] == true;
  }

  /// Get remaining validity time in seconds
  static int getRemainingValidity(String qrCode) {
    final result = validateDynamicQR(qrCode);
    if (result['valid'] != true) return 0;

    final ageSeconds = result['age_seconds'] as int? ?? 0;
    final remaining = _validityWindow - ageSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Round timestamp to interval (10 seconds)
  static int _roundToInterval(DateTime dateTime, int intervalSeconds) {
    final timestamp = dateTime.millisecondsSinceEpoch ~/ 1000;
    return (timestamp ~/ intervalSeconds) * intervalSeconds;
  }

  /// Create HMAC signature for QR code
  static String _createSignature(String payload) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    // Return first 8 characters of hex digest (sufficient for QR code security)
    return digest.toString().substring(0, 16);
  }

  /// Generate QR code for Event
  static String generateEventQR(String eventId) {
    return generateDynamicQR(type: 'EVENT', id: eventId, additionalData: null);
  }

  /// Generate QR code for Pertemuan
  static String generatePertemuanQR(String pertemuanId) {
    return generateDynamicQR(
      type: 'PERTEMUAN',
      id: pertemuanId,
      additionalData: null,
    );
  }

  /// Parse QR code to extract type and ID (without validation)
  static Map<String, String?> parseQRCode(String qrCode) {
    try {
      final parts = qrCode.split(':');
      if (parts.length >= 2) {
        return {'type': parts[0], 'id': parts[1]};
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return {'type': null, 'id': null};
  }

  /// Get QR validity window in seconds
  static int get validityWindow => _validityWindow;

  /// Get grace period in seconds
  static int get gracePeriod => _gracePeriod;
}
