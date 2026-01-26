import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

      // ========== REGISTRASI KE SUPABASE AUTH (TANPA EMAIL CONFIRMATION) ==========
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'nim': nim},
        emailRedirectTo: null, // Nonaktifkan email redirect
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
        // await _supabase.auth.admin.deleteUser(authResponse.user!.id);
        print('Error inserting user: $e');
        return {
          'success': false,
          'error': 'Gagal menyimpan data user: ${e.toString()}',
          'code': 'INSERT_ERROR',
        };
      }

      // ========== UPDATE STATUS VERIFIKASI EMAIL ==========
      // Update status is_verified menjadi true karena user sudah verifikasi sebelum register
      try {
        await _supabase
            .from('email_verifikasi')
            .update({
              'is_verified': true,
              'verified_at': DateTime.now().toIso8601String(),
            })
            .eq('email', email.trim().toLowerCase())
            .eq('is_verified', true); // Hanya update yang sudah verified
      } catch (e) {
        print('Error updating verification status: $e');
      }

      // ========== RESPONSE SUCCESS ==========
      return {
        'success': true,
        'message': 'Registrasi berhasil! Silakan login untuk melanjutkan.',
        'data': {
          'id_user': authResponse.user!.id,
          'username': username,
          'email': email,
          'nim': nim,
          'picture': picture,
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

  /// Check if email already exists
  Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      final result = await _supabase
          .from('users')
          .select('email')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      return {'success': true, 'exists': result != null};
    } catch (e) {
      return {
        'success': false,
        'error': 'Terjadi kesalahan saat mengecek email',
        'exists': false,
      };
    }
  }

  /// Check if NIM already exists
  Future<Map<String, dynamic>> checkNimExists(String nim) async {
    try {
      final result = await _supabase
          .from('users')
          .select('nim')
          .eq('nim', nim.trim())
          .maybeSingle();

      return {'success': true, 'exists': result != null};
    } catch (e) {
      return {
        'success': false,
        'error': 'Terjadi kesalahan saat mengecek NIM',
        'exists': false,
      };
    }
  }
}
