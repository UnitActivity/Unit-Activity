import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

/// A reusable profile avatar widget for headers that loads user data from database.
/// This widget displays the user's profile picture or their initial if no picture exists.
class HeaderProfileAvatar extends StatefulWidget {
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  const HeaderProfileAvatar({
    super.key,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
  });

  @override
  State<HeaderProfileAvatar> createState() => _HeaderProfileAvatarState();
}

class _HeaderProfileAvatarState extends State<HeaderProfileAvatar> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  String? _pictureUrl;
  String _username = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = await _supabase
          .from('users')
          .select('username, picture')
          .eq('id_user', userId)
          .maybeSingle();

      if (userData != null && mounted) {
        setState(() {
          _username = userData['username']?.toString() ?? '';
          _pictureUrl = userData['picture'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.backgroundColor ?? const Color(0xFF4169E1).withOpacity(0.2);
    final iColor = widget.iconColor ?? const Color(0xFF4169E1);

    if (_isLoading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: bgColor,
        child: SizedBox(
          width: widget.radius,
          height: widget.radius,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: iColor,
          ),
        ),
      );
    }

    // Show profile picture if available
    if (_pictureUrl != null && _pictureUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: widget.onTap,
        child: CircleAvatar(
          radius: widget.radius,
          backgroundImage: NetworkImage(_pictureUrl!),
          backgroundColor: bgColor,
          onBackgroundImageError: (_, __) {
            // Fallback to initial if image fails to load
          },
        ),
      );
    }

    // Show initial letter if username exists
    if (_username.isNotEmpty) {
      return GestureDetector(
        onTap: widget.onTap,
        child: CircleAvatar(
          radius: widget.radius,
          backgroundColor: bgColor,
          child: Text(
            _username[0].toUpperCase(),
            style: TextStyle(
              color: iColor,
              fontWeight: FontWeight.bold,
              fontSize: widget.radius * 0.8,
            ),
          ),
        ),
      );
    }

    // Fallback to person icon
    return GestureDetector(
      onTap: widget.onTap,
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: bgColor,
        child: Icon(
          Icons.person,
          color: iColor,
          size: widget.radius * 1.2,
        ),
      ),
    );
  }
}
