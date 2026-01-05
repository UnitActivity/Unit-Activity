import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/config/routes.dart';
import 'dart:ui';

class UKMHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onLogout;
  final String ukmName;
  final String periode;
  final VoidCallback? onHomePressed;
  final VoidCallback? onQrPressed;
  final VoidCallback? onNotificationPressed;
  final bool showWelcomeText;

  const UKMHeader({
    super.key,
    this.onMenuPressed,
    this.onLogout,
    required this.ukmName,
    required this.periode,
    this.onHomePressed,
    this.onQrPressed,
    this.onNotificationPressed,
    this.showWelcomeText = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Container(
      margin: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                if (isDesktop && showWelcomeText)
                  _buildWelcomeText()
                else if (!isDesktop)
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87),
                    onPressed: onMenuPressed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                // Center - Action Icons (Desktop only)
                if (isDesktop) ...[
                  const Spacer(),
                  _buildActionButton(
                    icon: Icons.home_outlined,
                    tooltip: 'Home',
                    onPressed: onHomePressed ?? () {},
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.qr_code_scanner,
                    tooltip: 'Scan QR Code',
                    onPressed: onQrPressed ?? () {},
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.notifications_outlined,
                    tooltip: 'Notifications',
                    onPressed: onNotificationPressed ?? () {},
                  ),
                ],

                // Right Side - Spacer or Direct Avatar
                if (!isDesktop) const Spacer(),
                const SizedBox(width: 12),

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

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 24),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
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
