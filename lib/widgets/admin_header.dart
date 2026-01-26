import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/custom_auth_service.dart';
import 'package:unit_activity/services/profile_image_service.dart';

class AdminHeader extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onLogout;
  final Function(String)? onProfilePressed;

  const AdminHeader({
    super.key,
    this.onMenuPressed,
    this.onLogout,
    this.onProfilePressed,
  });

  @override
  State<AdminHeader> createState() => _AdminHeaderState();
}

class _AdminHeaderState extends State<AdminHeader> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        await _authService.initialize();
      }

      final currentUser = _authService.currentUser;
      final currentUserId = _authService.currentUserId;
      final role = _authService.currentUserRole ?? 'admin';

      String currentName = 'Admin';
      if (currentUser != null) {
        currentName =
            currentUser['name'] ?? currentUser['username_admin'] ?? 'Admin';
        ProfileImageService.instance.updateUserName(currentName);
      }

      if (currentUserId != null) {
        // Coba load username dari table jika belum ada di session
        if (currentName == 'Admin' && (role == 'admin' || role == 'ukm')) {
          final adminData = await _supabase
              .from('admin')
              .select('username_admin')
              .eq('id_admin', currentUserId)
              .maybeSingle();

          if (adminData != null) {
            currentName = adminData['username_admin'];
            ProfileImageService.instance.updateUserName(currentName);
          }
        }

        await _loadProfileImage(currentName, role);
      }
    } catch (e) {
      print('Error loading header data: $e');
    }
  }

  Future<void> _loadProfileImage(String username, String role) async {
    try {
      bool found = false;
      for (final format in ['jpg', 'jpeg', 'png', 'webp']) {
        try {
          final fileName = '$role-$username.$format';

          final List<FileObject> objects = await _supabase.storage
              .from('profile')
              .list(searchOptions: SearchOptions(limit: 1, search: fileName));

          if (objects.isNotEmpty) {
            final publicUrl = _supabase.storage
                .from('profile')
                .getPublicUrl(fileName);

            ProfileImageService.instance.updateProfileImage(publicUrl);
            found = true;
            return;
          }
        } catch (e) {
          continue;
        }
      }

      // Jika tidak ketemu file apapun (found == false), ProfileImageService tetap null
      // yang akan memicu fallback ke asset default di UI.
    } catch (e) {
      print('Error checking profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Left Side
                if (isDesktop)
                  _buildWelcomeText()
                else
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87),
                    onPressed: widget.onMenuPressed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                // Center - Empty Space
                const Spacer(),

                // Right Side - Avatar with Dropdown
                _buildAvatarDropdown(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return ValueListenableBuilder<String?>(
      valueListenable: ProfileImageService.instance.userName,
      builder: (context, name, _) {
        return RichText(
          text: TextSpan(
            text: 'Welcome, ',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
            children: [
              TextSpan(
                text: name ?? 'Admin',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4169E1), width: 2),
        ),
        child: ValueListenableBuilder<String?>(
          valueListenable: ProfileImageService.instance.profileImageUrl,
          builder: (context, imageUrl, _) {
            return CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : const AssetImage('assets/ua.webp') as ImageProvider,
              onBackgroundImageError: (_, __) {
                // Fallback handled by ImageProvider logic usually
              },
              child: imageUrl == null
                  ? null // Gambar asset akan muncul
                  : null,
            );
          },
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text(
                'Profile',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 20, color: Colors.red),
              const SizedBox(width: 12),
              Text(
                'Log Out',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout' && widget.onLogout != null) {
          widget.onLogout!();
        } else if (value == 'profile') {
          if (widget.onProfilePressed != null) {
            widget.onProfilePressed!('profile');
          }
        }
      },
    );
  }
}
