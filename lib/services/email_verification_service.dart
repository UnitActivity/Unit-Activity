import 'package:supabase_flutter/supabase_flutter.dart';

class EmailVerificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Verify email with verification code
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      // ========== VALIDASI INPUT ==========
      if (email.isEmpty || code.isEmpty) {
        return {
          'success': false,
          'error': 'Email dan kode verifikasi wajib diisi',
          'code': 'VALIDATION_ERROR',
        };
      }

      // ========== CEK VERIFICATION CODE ==========
      final verification = await _supabase
          .from('email_verifikasi')
          .select()
          .eq('email', email)
          .eq('code', code)
          .eq('is_verified', false)
          .maybeSingle();

      if (verification == null) {
        return {
          'success': false,
          'error': 'Kode verifikasi tidak valid',
          'code': 'INVALID_CODE',
        };
      }

      // ========== CEK EXPIRED ==========
      final now = DateTime.now();
      final expiredAt = DateTime.parse(verification['expired_at']);

      if (now.isAfter(expiredAt)) {
        return {
          'success': false,
          'error': 'Kode verifikasi sudah kadaluarsa. Silakan minta kode baru.',
          'code': 'CODE_EXPIRED',
        };
      }

      // ========== UPDATE STATUS VERIFIKASI ==========
      await _supabase
          .from('email_verifikasi')
          .update({
            'is_verified': true,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('email', email)
          .eq('code', code);

      // ========== RESPONSE SUCCESS ==========
      return {
        'success': true,
        'message': 'Email berhasil diverifikasi. Silakan login.',
        'code': 'SUCCESS',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Terjadi kesalahan saat verifikasi email: ${e.toString()}',
        'code': 'SERVER_ERROR',
      };
    }
  }

  /// Resend verification code
  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      // ========== VALIDASI INPUT ==========
      if (email.isEmpty) {
        return {
          'success': false,
          'error': 'Email wajib diisi',
          'code': 'VALIDATION_ERROR',
        };
      }

      // ========== CEK APAKAH EMAIL SUDAH TERVERIFIKASI ==========
      final verification = await _supabase
          .from('email_verifikasi')
          .select('is_verified')
          .eq('email', email)
          .maybeSingle();

      if (verification != null && verification['is_verified'] == true) {
        return {
          'success': false,
          'error': 'Email sudah terverifikasi',
          'code': 'ALREADY_VERIFIED',
        };
      }

      // ========== CEK APAKAH USER ADA ==========
      final user = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (user == null) {
        // Jika user belum ada, buat kode verifikasi baru untuk proses register
        // (ini untuk kasus send code sebelum register)
      }

      // ========== GENERATE KODE BARU ==========
      final verificationCode =
          (100000 +
                  (900000 *
                          (DateTime.now().millisecondsSinceEpoch % 1000) /
                          1000)
                      .floor())
              .toString();
      final expiredAt = DateTime.now().add(const Duration(minutes: 5));

      // ========== DELETE KODE LAMA DAN INSERT KODE BARU ==========
      // Delete kode lama
      await _supabase
          .from('email_verifikasi')
          .delete()
          .eq('email', email)
          .eq('is_verified', false);

      // Insert kode baru
      await _supabase.from('email_verifikasi').insert({
        'email': email,
        'code': verificationCode,
        'is_verified': false,
        'expired_at': expiredAt.toIso8601String(),
        'create_at': DateTime.now().toIso8601String(),
      });

      // ========== RESPONSE SUCCESS ==========
      return {
        'success': true,
        'message': 'Kode verifikasi baru telah dikirim ke email Anda',
        'data': {
          'verification_code': verificationCode, // Untuk testing
        },
        'code': 'SUCCESS',
      };
    } catch (e) {
      return {
        'success': false,
        'error':
            'Terjadi kesalahan saat mengirim ulang kode verifikasi: ${e.toString()}',
        'code': 'SERVER_ERROR',
      };
    }
  }
}
