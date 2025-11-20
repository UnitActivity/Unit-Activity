import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'email_api_service.dart';

class EmailVerificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EmailApiService _emailService = EmailApiService();

  /// Generate random 6-character verification code (alphanumeric)
  /// Dipastikan mengandung minimal: 1 huruf besar, 1 huruf kecil, 1 angka
  String _generateVerificationCode() {
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

  /// Verify email with verification code
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      // ========== VALIDASI INPUT ==========
      final trimmedEmail = email.trim().toLowerCase();
      final trimmedCode = code.trim();

      if (trimmedEmail.isEmpty || trimmedCode.isEmpty) {
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
          .eq('email', trimmedEmail)
          .eq('code', trimmedCode)
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
          .eq('email', trimmedEmail)
          .eq('code', trimmedCode);

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

      // Normalisasi email
      final trimmedEmail = email.trim().toLowerCase();

      // ========== CEK APAKAH EMAIL SUDAH TERVERIFIKASI ==========
      final verification = await _supabase
          .from('email_verifikasi')
          .select('is_verified')
          .eq('email', trimmedEmail)
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
          .eq('email', trimmedEmail)
          .maybeSingle();

      if (user == null) {
        // Jika user belum ada, buat kode verifikasi baru untuk proses register
        // (ini untuk kasus send code sebelum register)
      }

      // ========== GENERATE KODE BARU ==========
      final verificationCode = _generateVerificationCode();
      final expiredAt = DateTime.now().add(const Duration(minutes: 5));

      // ========== DELETE SEMUA KODE LAMA (VERIFIED & UNVERIFIED) ==========
      // Hapus semua record dengan email yang sama untuk menghindari duplikasi
      await _supabase
          .from('email_verifikasi')
          .delete()
          .eq('email', trimmedEmail);

      // Insert kode baru
      await _supabase.from('email_verifikasi').insert({
        'email': trimmedEmail,
        'code': verificationCode,
        'is_verified': false,
        'expired_at': expiredAt.toIso8601String(),
        'create_at': DateTime.now().toIso8601String(),
      });

      // ========== KIRIM EMAIL VERIFIKASI ==========
      final emailResult = await _emailService.sendVerificationEmail(
        email: trimmedEmail,
        code: verificationCode,
      );

      if (!emailResult['success']) {
        print(
          'Warning: Failed to send verification email: ${emailResult['error']}',
        );
        // Tidak return error karena kode sudah tersimpan
      }

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
