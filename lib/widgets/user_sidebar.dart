import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserSidebar extends StatelessWidget {
  final String selectedMenu;
  final Function(String) onMenuSelected;
  final VoidCallback onLogout;

  const UserSidebar({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Text(
              'UNIT ACTIVITY',
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4169E1),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(height: 1),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  value: 'dashboard',
                  isSelected: selectedMenu == 'dashboard',
                  onTap: () => onMenuSelected('dashboard'),
                ),
                _buildMenuItem(
                  icon: Icons.event_note_outlined,
                  title: 'Event',
                  value: 'event',
                  isSelected: selectedMenu == 'event',
                  onTap: () => onMenuSelected('event'),
                ),
                _buildMenuItem(
                  icon: Icons.groups_outlined,
                  title: 'UKM',
                  value: 'ukm',
                  isSelected: selectedMenu == 'ukm',
                  onTap: () => onMenuSelected('ukm'),
                ),
                _buildMenuItem(
                  icon: Icons.history_outlined,
                  title: 'Histori',
                  value: 'histori',
                  isSelected: selectedMenu == 'histori',
                  onTap: () => onMenuSelected('histori'),
                ),
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  value: 'profile',
                  isSelected: selectedMenu == 'profile',
                  onTap: () => onMenuSelected('profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F0FE) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF4169E1) : Colors.grey[700],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF4169E1) : Colors.grey[800],
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
