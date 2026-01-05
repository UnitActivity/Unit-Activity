import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAuthService {
  // Singleton pattern
  static final CustomAuthService _instance = CustomAuthService._internal();
  factory CustomAuthService() => _instance;
  CustomAuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Session storage
  String? _currentUserId;
  String? _currentUserRole;
  Map<String, dynamic>? _currentUserData;

  // SharedPreferences keys
  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  /// Initialize service and restore session
  Future<void> initialize() async {
    await _restoreSession();
  }

  /// Login dengan email dan password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('========== CUSTOM AUTH LOGIN ==========');
      print('Attempting login for: $email');

      // 1. Try login as admin/ukm
      print('Checking admin table...');
      final adminResult =
          await _supabase.rpc(
                'login_admin',
                params: {'p_email': email, 'p_password': password},
              )
              as List<dynamic>?;

      print('Admin result: $adminResult');

      if (adminResult != null && adminResult.isNotEmpty) {
        final admin = adminResult[0] as Map<String, dynamic>;
        print('✅ Login successful as ${admin['role']}');

        _currentUserId = admin['id_admin'];
        _currentUserRole = admin['role'];
        _currentUserData = {
          'id': admin['id_admin'],
          'name': admin['username_admin'],
          'email': admin['email_admin'],
          'role': admin['role'],
          'status': admin['status'],
        };

        await _saveSession();

        return {
          'success': true,
          'role': admin['role'],
          'user': _currentUserData,
        };
      }

      // 2. Try login as user
      print('Checking users table...');
      final userResult =
          await _supabase.rpc(
                'login_user',
                params: {'p_email': email, 'p_password': password},
              )
              as List<dynamic>?;

      print('User result: $userResult');

      if (userResult != null && userResult.isNotEmpty) {
        final user = userResult[0] as Map<String, dynamic>;
        print('✅ Login successful as user');

        _currentUserId = user['id_user'];
        _currentUserRole = 'user';
        _currentUserData = {
          'id': user['id_user'],
          'name': user['username'],
          'email': user['email'],
          'nim': user['nim'],
          'picture': user['picture'],
          'role': 'user',
        };

        await _saveSession();

        return {'success': true, 'role': 'user', 'user': _currentUserData};
      }

      // Login failed
      print('❌ Login failed - invalid credentials');
      return {'success': false, 'error': 'Email atau password salah'};
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'error': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  /// Register admin/ukm
  Future<Map<String, dynamic>> registerAdmin({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final result = await _supabase.rpc(
        'register_admin',
        params: {
          'p_username': username,
          'p_email': email,
          'p_password': password,
          'p_role': role,
        },
      );

      return {'success': true, 'id': result, 'message': 'Registrasi berhasil'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Register user
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
    required String nim,
  }) async {
    try {
      final result = await _supabase.rpc(
        'register_user',
        params: {
          'p_username': username,
          'p_email': email,
          'p_password': password,
          'p_nim': nim,
        },
      );

      return {'success': true, 'id': result, 'message': 'Registrasi berhasil'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Logout
  Future<void> logout() async {
    _currentUserId = null;
    _currentUserRole = null;
    _currentUserData = null;
    await _clearSession();
    print('User logged out');
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUserId != null) {
        await prefs.setString(_keyUserId, _currentUserId!);
        print('✅ Saved user ID: $_currentUserId');
      }
      if (_currentUserRole != null) {
        await prefs.setString(_keyUserRole, _currentUserRole!);
        print('✅ Saved user role: $_currentUserRole');
      }
      if (_currentUserData != null) {
        await prefs.setString(_keyUserEmail, _currentUserData!['email'] ?? '');
        await prefs.setString(_keyUserName, _currentUserData!['name'] ?? '');
        print('✅ Saved user data');
      }
      print('✅ Session saved successfully');
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  /// Restore session from SharedPreferences
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString(_keyUserId);
      _currentUserRole = prefs.getString(_keyUserRole);

      if (_currentUserId != null && _currentUserRole != null) {
        final email = prefs.getString(_keyUserEmail) ?? '';
        final name = prefs.getString(_keyUserName) ?? '';

        _currentUserData = {
          'id': _currentUserId,
          'email': email,
          'name': name,
          'role': _currentUserRole,
        };

        print('✅ Session restored: $_currentUserId ($_currentUserRole)');
        print('✅ User: $name ($email)');
      } else {
        print('ℹ️ No saved session found');
      }
    } catch (e) {
      print('❌ Error restoring session: $e');
    }
  }

  /// Clear session from SharedPreferences
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserRole);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserName);
      print('✅ Session cleared');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  /// Getters
  Map<String, dynamic>? get currentUser => _currentUserData;
  String? get currentUserId => _currentUserId;
  String? get currentUserRole => _currentUserRole;

  bool get isLoggedIn => _currentUserId != null;
  bool get isAdmin => _currentUserRole == 'admin';
  bool get isUKM => _currentUserRole == 'ukm';
  bool get isUser => _currentUserRole == 'user';
}
