import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'email_api_service.dart';

class PasswordResetService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EmailApiService _emailService = EmailApiService();

  /// Generate random 6-character reset code (alphanumeric)
  /// Dipastikan mengandung minimal: 1 huruf besar, 1 huruf kecil, 1 angka
  String _generateResetCode() {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    final random = Random.secure();

    // Pastikan ada minimal 1 dari setiap kategori
    final List<String> code = [
      uppercase[random.nextInt(uppercase.length)], // 1 huruf besar
      lowercase[random.nextInt(lowercase.length)], // 1 huruf kecil
      numbers[random.nextInt(numbers.length)], // 1 angka
    ];

    // Isi 3 karakter sisanya dengan random dari semua kategori
    const allChars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    for (int i = 0; i < 3; i++) {
      code.add(allChars[random.nextInt(allChars.length)]);
    }

    // Acak urutan karakter
    code.shuffle(random);

    return code.join();
  }

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

      // Normalisasi email
      final trimmedEmail = email.trim().toLowerCase();

      // ========== CEK APAKAH EMAIL TERDAFTAR ==========
      final user = await _supabase
          .from('users')
          .select('email')
          .eq('email', trimmedEmail)
          .maybeSingle();

      if (user == null) {
        return {
          'success': false,
          'error': 'Email tidak terdaftar',
          'code': 'EMAIL_NOT_FOUND',
        };
      }

      // ========== GENERATE RESET CODE ==========
      final resetCode = _generateResetCode();
      final expiredAt = DateTime.now().add(const Duration(hours: 1));

      // ========== DELETE KODE LAMA ==========
      await _supabase.from('password_reset').delete().eq('email', trimmedEmail);

      // ========== INSERT KODE BARU ==========
      await _supabase.from('password_reset').insert({
        'email': trimmedEmail,
        'reset_code': resetCode,
        'is_verified': false,
        'expired_at': expiredAt.toIso8601String(),
        'create_at': DateTime.now().toIso8601String(),
      });

      // ========== KIRIM EMAIL RESET PASSWORD ==========
      final emailResult = await _emailService.sendPasswordResetEmail(
        email: trimmedEmail,
        code: resetCode,
      );

      if (!emailResult['success']) {
        print(
          'Warning: Failed to send password reset email: ${emailResult['error']}',
        );
        // Tidak return error karena kode sudah tersimpan
      }

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
      final trimmedEmail = email.trim().toLowerCase();
      final trimmedCode = code.trim();

      if (trimmedEmail.isEmpty || trimmedCode.isEmpty) {
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
          .eq('email', trimmedEmail)
          .eq('reset_code', trimmedCode)
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
          .eq('email', trimmedEmail)
          .eq('reset_code', trimmedCode);

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
      final trimmedEmail = email.trim().toLowerCase();
      final trimmedCode = code.trim();

      if (trimmedEmail.isEmpty || trimmedCode.isEmpty || newPassword.isEmpty) {
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
          .eq('email', trimmedEmail)
          .eq('reset_code', trimmedCode)
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
          .eq('email', trimmedEmail)
          .single();

      // ========== UPDATE PASSWORD DI SUPABASE AUTH ==========
      await _supabase.auth.admin.updateUserById(
        userData['id_user'],
        attributes: AdminUserAttributes(password: newPassword),
      );

      // ========== DELETE RESET CODE ==========
      await _supabase.from('password_reset').delete().eq('email', trimmedEmail);

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
