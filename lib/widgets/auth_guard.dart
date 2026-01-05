import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/auth/login.dart';

/// Middleware untuk memastikan user sudah login
/// Digunakan untuk melindungi halaman yang memerlukan autentikasi
class AuthGuard extends StatefulWidget {
  final Widget child;
  final String? requiredRole; // 'user', 'admin', 'ukm'

  const AuthGuard({Key? key, required this.child, this.requiredRole})
    : super(key: key);

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          _isAuthenticated = false;
          _isChecking = false;
        });
        return;
      }

      // Check role if required
      if (widget.requiredRole != null) {
        // Get user role from database
        final userData = await _supabase
            .from('users')
            .select('role')
            .eq('id_user', user.id)
            .maybeSingle();

        if (userData == null || userData['role'] != widget.requiredRole) {
          setState(() {
            _isAuthenticated = false;
            _isChecking = false;
          });
          return;
        }
      }

      setState(() {
        _isAuthenticated = true;
        _isChecking = false;
      });
    } catch (e) {
      print('Auth check error: $e');
      setState(() {
        _isAuthenticated = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      // Redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      });

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return widget.child;
  }
}
