import 'package:supabase_flutter/supabase_flutter.dart';

class LoginService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Login user with role detection
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

      // ========== LOGIN KE SUPABASE AUTH ==========
      print('Attempting login for: $email');

      AuthResponse? authResponse;
      try {
        authResponse = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        print('Auth response received: ${authResponse.user?.id}');
      } on AuthException catch (authError) {
        print('Auth error: ${authError.message}');
        print('Auth error code: ${authError.statusCode}');

        // Check if error is "Email not confirmed"
        if (authError.message.contains('Email not confirmed')) {
          print('Email not confirmed, but allowing login anyway...');

          // Try to get user session anyway - for development purposes
          // In production, you should enable email confirmation in Supabase
          // For now, we'll return a helpful error
          return {
            'success': false,
            'error':
                'Email belum dikonfirmasi di Supabase Auth. Silakan konfirmasi email Anda atau hubungi administrator untuk mengaktifkan akun.',
            'code': 'EMAIL_NOT_CONFIRMED',
          };
        }

        // Return specific error message for other errors
        String errorMessage = 'Email atau password salah';
        if (authError.message.contains('Invalid login credentials')) {
          errorMessage = 'Email atau password salah. Silakan periksa kembali.';
        } else {
          errorMessage = authError.message;
        }

        return {'success': false, 'error': errorMessage, 'code': 'AUTH_ERROR'};
      }

      if (authResponse == null || authResponse.user == null) {
        print('Auth response user is null');
        return {'success': false, 'error': 'Login gagal', 'code': 'AUTH_ERROR'};
      }

      print('User authenticated: ${authResponse.user!.email}');

      // ========== DETECT USER ROLE ==========
      String role = 'user';
      Map<String, dynamic>? userData;

      // Check admin table first (for admin & ukm)
      print('Checking admin table for: $email');
      final adminData = await _supabase
          .from('admin')
          .select('id_admin, email_admin, role, username_admin, status')
          .eq('email_admin', email)
          .maybeSingle();

      print('Admin data: $adminData');

      if (adminData != null) {
        // User is admin or ukm
        role = adminData['role'] ?? 'admin';
        userData = {
          'id': adminData['id_admin'],
          'email': adminData['email_admin'],
          'name': adminData['username_admin'], // Changed from nama_admin
          'role': role,
          'status': adminData['status'],
        };

        // Cache the role
        _cachedUserData = userData;
        print('User identified as: $role');
      } else {
        // Check users table (for regular users/mahasiswa)
        print('Checking users table for user ID: ${authResponse.user!.id}');
        final userDataResponse = await _supabase
            .from('users')
            .select('id_user, email, username, nim, picture')
            .eq('id_user', authResponse.user!.id)
            .maybeSingle();

        print('User data: $userDataResponse');

        if (userDataResponse != null) {
          role = 'user';
          userData = {
            'id': userDataResponse['id_user'],
            'email': userDataResponse['email'],
            'name': userDataResponse['username'],
            'nim': userDataResponse['nim'],
            'picture': userDataResponse['picture'],
            'role': role,
          };

          // Cache the role
          _cachedUserData = userData;
          print('User identified as: user');
        } else {
          print('ERROR: User data not found in both admin and users tables');
          return {
            'success': false,
            'error': 'Data pengguna tidak ditemukan di database',
            'code': 'USER_NOT_FOUND',
          };
        }
      }

      print('Login successful - Role: $role, User: ${userData['name']}');

      // ========== RESPONSE SUCCESS ==========
      return {
        'success': true,
        'message': 'Login berhasil',
        'data': {
          'user': userData,
          'role': role,
          'session': {
            'access_token': authResponse.session?.accessToken,
            'refresh_token': authResponse.session?.refreshToken,
          },
        },
        'code': 'SUCCESS',
      };
    } on AuthException catch (e) {
      print('AuthException caught: ${e.message}');
      return {'success': false, 'error': e.message, 'code': 'AUTH_ERROR'};
    } catch (e) {
      print('General error: $e');
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

  /// Get current user role
  String? getUserRole() {
    if (_cachedUserData == null) return null;
    return _cachedUserData!['role'] as String?;
  }

  /// Check if current user is Admin
  bool isAdmin() {
    if (_cachedUserData == null) return false;
    return _cachedUserData!['role'] == 'admin';
  }

  /// Check if current user is regular User
  bool isUser() {
    if (_cachedUserData == null) return false;
    return _cachedUserData!['role'] == 'user';
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
