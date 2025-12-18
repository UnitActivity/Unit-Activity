import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class UserHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onLogout;
  final String userName;

  const UserHeader({
    super.key,
    this.onMenuPressed,
    this.onLogout,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
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
                    onPressed: onMenuPressed,
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
    return RichText(
      text: TextSpan(
        text: 'Welcome, ',
        style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
        children: [
          TextSpan(
            text: userName,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF4169E1).withOpacity(0.2),
        child: const Icon(Icons.person, color: Color(0xFF4169E1), size: 24),
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
        if (value == 'logout' && onLogout != null) {
          onLogout!();
        } else if (value == 'profile') {
          // TODO: Navigate to profile
        }
      },
    );
  }
}
