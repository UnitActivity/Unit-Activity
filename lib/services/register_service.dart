import 'package:supabase_flutter/supabase_flutter.dart';
import 'email_api_service.dart';

class RegisterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EmailApiService _emailService = EmailApiService();

  /// Register new user
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
    String? nim,
    String? picture,
  }) async {
    try {
      // ========== VALIDASI INPUT ==========
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'error': 'Username, email, dan password wajib diisi',
          'code': 'VALIDATION_ERROR',
        };
      }

      // Validasi format email
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(email)) {
        return {
          'success': false,
          'error': 'Format email tidak valid',
          'code': 'INVALID_EMAIL',
        };
      }

      // Validasi panjang password
      if (password.length < 6) {
        return {
          'success': false,
          'error': 'Password minimal 6 karakter',
          'code': 'PASSWORD_TOO_SHORT',
        };
      }

      // Validasi username
      final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,}$');
      if (!usernameRegex.hasMatch(username)) {
        return {
          'success': false,
          'error':
              'Username minimal 3 karakter dan hanya boleh mengandung huruf, angka, dan underscore',
          'code': 'INVALID_USERNAME',
        };
      }

      // ========== CEK EMAIL DUPLIKAT ==========
      final existingUser = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        return {
          'success': false,
          'error': 'Email sudah terdaftar',
          'code': 'EMAIL_EXISTS',
        };
      }

      // ========== REGISTRASI KE SUPABASE AUTH ==========
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'nim': nim},
      );

      if (authResponse.user == null) {
        return {
          'success': false,
          'error': 'Registrasi gagal',
          'code': 'AUTH_ERROR',
        };
      }

      // ========== INSERT DATA USER KE TABEL USERS ==========
      try {
        await _supabase.from('users').insert({
          'id_user': authResponse.user!.id,
          'username': username,
          'email': email,
          'password': authResponse.user!.id, // Simpan user ID sebagai referensi
          'nim': nim,
          'picture': picture,
          'create_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Rollback: hapus user dari auth jika insert gagal
        await _supabase.auth.admin.deleteUser(authResponse.user!.id);

        return {
          'success': false,
          'error': 'Gagal menyimpan data user: ${e.toString()}',
          'code': 'INSERT_ERROR',
        };
      }

      // ========== GENERATE VERIFICATION CODE ==========
      final verificationCode =
          (100000 +
                  (900000 *
                          (DateTime.now().millisecondsSinceEpoch % 1000) /
                          1000)
                      .floor())
              .toString();
      final expiredAt = DateTime.now().add(const Duration(hours: 24));

      // Insert ke tabel email_verifikasi
      try {
        await _supabase.from('email_verifikasi').insert({
          'email': email,
          'code': verificationCode,
          'is_verified': false,
          'expired_at': expiredAt.toIso8601String(),
          'create_at': DateTime.now().toIso8601String(),
        });

        // ========== KIRIM EMAIL VERIFIKASI ==========
        final emailResult = await _emailService.sendVerificationEmail(
          email: email,
          code: verificationCode,
        );

        if (!emailResult['success']) {
          print(
            'Warning: Failed to send verification email: ${emailResult['error']}',
          );
          // Tidak return error karena user sudah terdaftar dan kode sudah tersimpan
        }
      } catch (e) {
        print('Error creating verification code: $e');
        // Tidak return error karena user sudah terdaftar
      }

      // ========== RESPONSE SUCCESS ==========
      return {
        'success': true,
        'message':
            'Registrasi berhasil! Silakan cek email untuk verifikasi akun.',
        'data': {
          'id_user': authResponse.user!.id,
          'username': username,
          'email': email,
          'nim': nim,
          'picture': picture,
          'verification_code': verificationCode, // Untuk testing
        },
        'code': 'SUCCESS',
      };
    } on AuthException catch (e) {
      return {'success': false, 'error': e.message, 'code': 'AUTH_ERROR'};
    } catch (e) {
      return {
        'success': false,
        'error': 'Terjadi kesalahan saat registrasi: ${e.toString()}',
        'code': 'SERVER_ERROR',
      };
    }
  }
}
