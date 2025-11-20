import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordResetService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Request password reset
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      // ========== VALIDASI INPUT ==========
      if (email.isEmpty) {
        return {
          'success': false,
          'error': 'Email wajib diisi',
          'code': 'VALIDATION_ERROR',
        };
      }

      // ========== CEK APAKAH EMAIL TERDAFTAR ==========
      final user = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (user == null) {
        return {
          'success': false,
          'error': 'Email tidak terdaftar',
          'code': 'EMAIL_NOT_FOUND',
        };
      }

      // ========== GENERATE RESET CODE ==========
      final resetCode =
          (100000 +
                  (900000 *
                          (DateTime.now().millisecondsSinceEpoch % 1000) /
                          1000)
                      .floor())
              .toString();
      final expiredAt = DateTime.now().add(const Duration(hours: 1));

      // ========== DELETE KODE LAMA ==========
      await _supabase.from('password_reset').delete().eq('email', email);

      // ========== INSERT KODE BARU ==========
      await _supabase.from('password_reset').insert({
        'email': email,
        'code': resetCode,
        'is_verified': false,
        'expired_at': expiredAt.toIso8601String(),
        'create_at': DateTime.now().toIso8601String(),
      });

      // ========== RESPONSE SUCCESS ==========
      return {
        'success': true,
        'message': 'Kode reset password telah dikirim ke email Anda',
        'data': {
          'reset_code': resetCode, // Untuk testing
        },
        'code': 'SUCCESS',
      };
    } catch (e) {
      return {
        'success': false,
        'error':
            'Terjadi kesalahan saat request reset password: ${e.toString()}',
        'code': 'SERVER_ERROR',
      };
    }
  }

  /// Verify reset code
  Future<Map<String, dynamic>> verifyResetCode(
    String email,
    String code,
  ) async {
    try {
      // ========== VALIDASI INPUT ==========
      if (email.isEmpty || code.isEmpty) {
        return {
          'success': false,
          'error': 'Email dan kode reset wajib diisi',
          'code': 'VALIDATION_ERROR',
        };
      }

      // ========== CEK RESET CODE ==========
      final resetData = await _supabase
          .from('password_reset')
          .select()
          .eq('email', email)
          .eq('code', code)
          .eq('is_verified', false)
          .maybeSingle();

      if (resetData == null) {
        return {
          'success': false,
          'error': 'Kode reset tidak valid',
          'code': 'INVALID_CODE',
        };
      }

      // ========== CEK EXPIRED ==========
      final now = DateTime.now();
      final expiredAt = DateTime.parse(resetData['expired_at']);

      if (now.isAfter(expiredAt)) {
        return {
          'success': false,
          'error': 'Kode reset sudah kadaluarsa. Silakan minta kode baru.',
          'code': 'CODE_EXPIRED',
        };
      }

      // ========== UPDATE STATUS VERIFIKASI ==========
      await _supabase
          .from('password_reset')
          .update({
            'is_verified': true,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('email', email)
          .eq('code', code);

      // ========== RESPONSE SUCCESS ==========
      return {
        'success': true,
        'message': 'Kode reset berhasil diverifikasi',
        'code': 'SUCCESS',
      };
    } catch (e) {
      return {
        'success': false,
        'error':
            'Terjadi kesalahan saat verifikasi kode reset: ${e.toString()}',
        'code': 'SERVER_ERROR',
      };
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      // ========== VALIDASI INPUT ==========
      if (email.isEmpty || code.isEmpty || newPassword.isEmpty) {
        return {
          'success': false,
          'error': 'Email, kode reset, dan password baru wajib diisi',
          'code': 'VALIDATION_ERROR',
        };
      }

      if (newPassword.length < 6) {
        return {
          'success': false,
          'error': 'Password minimal 6 karakter',
          'code': 'PASSWORD_TOO_SHORT',
        };
      }

      // ========== CEK RESET CODE SUDAH DIVERIFIKASI ==========
      final resetData = await _supabase
          .from('password_reset')
          .select()
          .eq('email', email)
          .eq('code', code)
          .eq('is_verified', true)
          .maybeSingle();

      if (resetData == null) {
        return {
          'success': false,
          'error': 'Kode reset belum diverifikasi atau tidak valid',
          'code': 'CODE_NOT_VERIFIED',
        };
      }

      // ========== GET USER DATA ==========
      final userData = await _supabase
          .from('users')
          .select('id_user')
          .eq('email', email)
          .single();

      // ========== UPDATE PASSWORD DI SUPABASE AUTH ==========
      await _supabase.auth.admin.updateUserById(
        userData['id_user'],
        attributes: AdminUserAttributes(password: newPassword),
      );

      // ========== DELETE RESET CODE ==========
      await _supabase.from('password_reset').delete().eq('email', email);

      // ========== RESPONSE SUCCESS ==========
      return {
        'success': true,
        'message':
            'Password berhasil direset. Silakan login dengan password baru.',
        'code': 'SUCCESS',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Terjadi kesalahan saat reset password: ${e.toString()}',
        'code': 'SERVER_ERROR',
      };
    }
  }
}
