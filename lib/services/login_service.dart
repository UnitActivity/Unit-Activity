import 'package:supabase_flutter/supabase_flutter.dart';

class LoginService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Login user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // ========== VALIDASI INPUT ==========
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'error': 'Email dan password wajib diisi',
          'code': 'VALIDATION_ERROR',
        };
      }

      // ========== CEK EMAIL VERIFIKASI ==========
      final verification = await _supabase
          .from('email_verifikasi')
          .select('is_verified')
          .eq('email', email)
          .maybeSingle();

      if (verification == null || verification['is_verified'] == false) {
        return {
          'success': false,
          'error':
              'Email belum diverifikasi. Silakan verifikasi email terlebih dahulu.',
          'code': 'EMAIL_NOT_VERIFIED',
        };
      }

      // ========== LOGIN KE SUPABASE AUTH ==========
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'error': 'Login gagal', 'code': 'AUTH_ERROR'};
      }

      // ========== GET USER DATA ==========
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id_user', authResponse.user!.id)
          .single();

      // ========== RESPONSE SUCCESS ==========
      return {
        'success': true,
        'message': 'Login berhasil',
        'data': {
          'user': userData,
          'session': {
            'access_token': authResponse.session?.accessToken,
            'refresh_token': authResponse.session?.refreshToken,
          },
        },
        'code': 'SUCCESS',
      };
    } on AuthException catch (e) {
      return {'success': false, 'error': e.message, 'code': 'AUTH_ERROR'};
    } catch (e) {
      return {
        'success': false,
        'error': 'Terjadi kesalahan saat login: ${e.toString()}',
        'code': 'SERVER_ERROR',
      };
    }
  }

  /// Logout user
  Future<Map<String, dynamic>> logoutUser() async {
    try {
      await _supabase.auth.signOut();

      return {'success': true, 'message': 'Logout berhasil', 'code': 'SUCCESS'};
    } catch (e) {
      return {
        'success': false,
        'error': 'Terjadi kesalahan saat logout: ${e.toString()}',
        'code': 'SERVER_ERROR',
      };
    }
  }

  /// Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return {
          'success': false,
          'error': 'User tidak ditemukan',
          'code': 'USER_NOT_FOUND',
        };
      }

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id_user', user.id)
          .single();

      return {'success': true, 'data': userData, 'code': 'SUCCESS'};
    } catch (e) {
      return {
        'success': false,
        'error': 'Terjadi kesalahan saat mengambil data user: ${e.toString()}',
        'code': 'SERVER_ERROR',
      };
    }
  }

  // ========== HELPER METHODS FOR SYNCHRONOUS ACCESS ==========
  /// Cached user data for synchronous access
  Map<String, dynamic>? _cachedUserData;

  /// Get cached user data
  Map<String, dynamic>? get currentUserData => _cachedUserData;

  /// Check if user is logged in
  bool isUserLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  /// Check if current user is UKM
  bool isUserUKM() {
    if (_cachedUserData == null) return false;
    return _cachedUserData!['role'] == 'ukm';
  }

  /// Initialize cached user data (call this after login or on app start)
  Future<void> initializeUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id_user', user.id)
            .single();
        _cachedUserData = userData;
      }
    } catch (e) {
      _cachedUserData = null;
    }
  }
}
