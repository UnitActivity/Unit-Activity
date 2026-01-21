import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class UKMHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onLogout;
  final Function(String)? onMenuSelected;
  final String ukmName;
  final String? ukmLogo;
  final String periode;
  final bool showWelcomeText;

  const UKMHeader({
    super.key,
    this.onMenuPressed,
    this.onLogout,
    this.onMenuSelected,
    required this.ukmName,
    this.ukmLogo,
    required this.periode,
    this.showWelcomeText = true,
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
                if (isDesktop && showWelcomeText)
                  _buildWelcomeText()
                else if (!isDesktop)
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87),
                    onPressed: onMenuPressed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                // Spacer
                const Spacer(),

                // Periode Badge (before avatar) - Desktop only
                if (isDesktop) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4169E1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4169E1).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF4169E1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Periode $periode',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4169E1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Right Side - Avatar with Dropdown (for both mobile and desktop)
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
            text: ukmName,
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
        backgroundImage: ukmLogo != null ? NetworkImage(ukmLogo!) : null,
        child: ukmLogo == null
            ? const Icon(Icons.person, color: Color(0xFF4169E1), size: 24)
            : null,
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
        } else if (value == 'profile' && onMenuSelected != null) {
          onMenuSelected!('profile');
        }
      },
    );
  }
}
