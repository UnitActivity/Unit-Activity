import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/user/profile.dart';
import 'package:unit_activity/auth/login.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

class UserProfileButton extends StatefulWidget {
  const UserProfileButton({super.key});

  @override
  State<UserProfileButton> createState() => _UserProfileButtonState();
}

class _UserProfileButtonState extends State<UserProfileButton> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();
  String? _pictureUrl;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      final userData = await _supabase
          .from('users')
          .select('username, picture')
          .eq('id_user', userId)
          .maybeSingle();

      if (userData != null && mounted) {
        setState(() {
          _username = userData['username']?.toString() ?? '';
          _pictureUrl = userData['picture'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.logout();
              } catch (e) {
                debugPrint('Error signing out: $e');
              }
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        } else if (value == 'logout') {
          _showLogoutDialog();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, size: 20, color: Colors.blue[700]),
              const SizedBox(width: 12),
              const Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: Colors.red[600]),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(color: Colors.red[600]),
              ),
            ],
          ),
        ),
      ],
      child: _pictureUrl != null && _pictureUrl!.isNotEmpty
          ? CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(_pictureUrl!),
              backgroundColor: const Color(0xFF4169E1).withOpacity(0.2),
            )
          : CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF4169E1).withOpacity(0.2),
              child: _username.isNotEmpty
                  ? Text(
                      _username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF4169E1),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Color(0xFF4169E1),
                      size: 24,
                    ),
            ),
    );
  }
}
