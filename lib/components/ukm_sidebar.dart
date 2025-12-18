import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UKMSidebar extends StatelessWidget {
  final String selectedMenu;
  final Function(String) onMenuSelected;
  final VoidCallback onLogout;

  const UKMSidebar({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF1F2937),
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unit Activity',
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4169E1),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF374151)),

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
                  icon: Icons.people_outline,
                  title: 'Peserta',
                  value: 'peserta',
                  isSelected: selectedMenu == 'peserta',
                  onTap: () => onMenuSelected('peserta'),
                ),
                _buildMenuItem(
                  icon: Icons.event_note_outlined,
                  title: 'Event',
                  value: 'event',
                  isSelected: selectedMenu == 'event',
                  onTap: () => onMenuSelected('event'),
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'Informasi',
                  value: 'informasi',
                  isSelected: selectedMenu == 'informasi',
                  onTap: () => onMenuSelected('informasi'),
                ),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifikasi',
                  value: 'notifikasi',
                  isSelected: selectedMenu == 'notifikasi',
                  onTap: () => onMenuSelected('notifikasi'),
                ),
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Akun',
                  value: 'akun',
                  isSelected: selectedMenu == 'akun',
                  onTap: () => onMenuSelected('akun'),
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: Text(
                'Log Out',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4169E1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[400],
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[300],
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
