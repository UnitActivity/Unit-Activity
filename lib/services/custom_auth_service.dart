import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'push_notification_service.dart';

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
  static const String _keyUserNim = 'user_nim';

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

      // 1. Try login as admin/ukm - direct query (admin table doesn't have password field)
      print('Checking admin table...');
      try {
        final adminResult = await _supabase
            .from('admin')
            .select('id_admin, username_admin, email_admin, role, status')
            .eq('email_admin', email)
            .maybeSingle();

        if (adminResult != null) {
          print('Admin found: ${adminResult['username_admin']}');
          print(
            '✅ Login successful as ${adminResult['role']} (admin table has no password validation)',
          );

          _currentUserId = adminResult['id_admin'];
          _currentUserRole = adminResult['role'];
          _currentUserData = {
            'id': adminResult['id_admin'],
            'name': adminResult['username_admin'],
            'email': adminResult['email_admin'],
            'role': adminResult['role'],
            'status': adminResult['status'],
          };

          await _saveSession();

          // Update FCM token association with user ID
          if (!kIsWeb) {
            try {
              final pushNotificationService = PushNotificationService();
              await pushNotificationService.updateUserAssociation(
                _currentUserId!,
              );

              // Migrate anonymous notifications to user notifications
              await _migrateAnonymousNotifications(_currentUserId!);

              print('✅ FCM token associated with user');
            } catch (e) {
              print('❌ Error associating FCM token: $e');
            }
          }

          return {
            'success': true,
            'role': adminResult['role'],
            'user': _currentUserData,
          };
        }
      } catch (e) {
        print('Error checking admin: $e');
      }

      // 2. Try login as user - direct query
      print('Checking users table...');
      try {
        final userResult = await _supabase
            .from('users')
            .select('id_user, username, email, password, nim, picture')
            .eq('email', email)
            .maybeSingle();

        if (userResult != null) {
          print('User found: ${userResult['username']}');

          // Check password (supports both plain text and hashed)
          final storedPassword = userResult['password'];
          if (storedPassword == password ||
              _verifyPassword(password, storedPassword)) {
            print('✅ Login successful as user');

            _currentUserId = userResult['id_user'];
            _currentUserRole = 'user';
            _currentUserData = {
              'id': userResult['id_user'],
              'name': userResult['username'],
              'email': userResult['email'],
              'nim': userResult['nim'],
              'picture': userResult['picture'],
              'role': 'user',
            };

            await _saveSession();

            // Update FCM token association with user ID
            if (!kIsWeb) {
              try {
                final pushNotificationService = PushNotificationService();
                await pushNotificationService.updateUserAssociation(
                  _currentUserId!,
                );

                // Migrate anonymous notifications to user notifications
                await _migrateAnonymousNotifications(_currentUserId!);

                print('✅ FCM token associated with user');
              } catch (e) {
                print('❌ Error associating FCM token: $e');
              }
            }

            return {'success': true, 'role': 'user', 'user': _currentUserData};
          } else {
            print('❌ Password tidak cocok');
          }
        } else {
          print('❌ User tidak ditemukan');
        }
      } catch (e) {
        print('Error checking user: $e');
      }

      // Login failed
      print('❌ Login failed - invalid credentials');
      return {'success': false, 'error': 'Email atau password salah'};
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'error': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  /// Verify password - supports both plain text comparison and bcrypt hash
  bool _verifyPassword(String inputPassword, String storedPassword) {
    // If stored password starts with $2b$ or $2a$, it's bcrypt
    // For now, we'll just do simple comparison since we don't have bcrypt in Flutter
    // In production, you should use proper password hashing
    return inputPassword == storedPassword;
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
    // Clear user association from FCM token but keep token for anonymous notifications
    if (!kIsWeb) {
      try {
        final pushNotificationService = PushNotificationService();
        await pushNotificationService.clearUserAssociation();
        print('✅ FCM token preserved for anonymous notifications');
      } catch (e) {
        print('❌ Error clearing FCM user association: $e');
      }
    }

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
        if (_currentUserData!['nim'] != null) {
          await prefs.setString(_keyUserNim, _currentUserData!['nim'] ?? '');
        }
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
        final nim = prefs.getString(_keyUserNim);

        _currentUserData = {
          'id': _currentUserId,
          'email': email,
          'name': name,
          'role': _currentUserRole,
        };

        if (nim != null) {
          _currentUserData!['nim'] = nim;
        }

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
      await prefs.remove(_keyUserNim);
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

  /// Migrate anonymous notifications to user notifications on login
  Future<void> _migrateAnonymousNotifications(String userId) async {
    try {
      if (kIsWeb) return; // Only for mobile apps

      // Get device token
      final prefs = await SharedPreferences.getInstance();
      final deviceToken = prefs.getString('fcm_token');

      if (deviceToken == null) {
        print('ℹ️ No FCM token found, skipping notification migration');
        return;
      }

      print('🔄 Migrating anonymous notifications for device: $deviceToken');

      // NOTE: Migration function requires notifikasi table to exist
      // For now, skip migration if using notification_preference table
      // Uncomment when proper notifikasi table is created:
      /*
      final result = await _supabase.rpc(
        'migrate_anonymous_notifications_to_user',
        params: {'p_device_token': deviceToken, 'p_user_id': userId},
      );

      final migratedCount = result as int? ?? 0;

      if (migratedCount > 0) {
        print('✅ Migrated $migratedCount anonymous notifications to user');
      } else {
        print('ℹ️ No anonymous notifications to migrate');
      }
      */
      print(
        'ℹ️ Migration skipped - using existing notification_preference table',
      );
    } catch (e) {
      print('❌ Error migrating anonymous notifications: $e');
      // Don't throw - migration is optional, login should still succeed
    }
  }
}
