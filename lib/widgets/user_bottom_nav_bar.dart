import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserBottomNavBar extends StatelessWidget {
  final String selectedMenu;
  final Function(String) onMenuSelected;
  final VoidCallback? onQRScan;

  const UserBottomNavBar({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelected,
    this.onQRScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: _buildNavItem(
                      Icons.home_rounded,
                      'Dashboard',
                      selectedMenu == 'dashboard',
                      () => onMenuSelected('dashboard'),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildNavItem(
                      Icons.event_rounded,
                      'Event',
                      selectedMenu == 'event',
                      () => onMenuSelected('event'),
                    ),
                  ),
                ),
                // Center QR Scanner button
                Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[600],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onQRScan,
                      borderRadius: BorderRadius.circular(28),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_2,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildNavItem(
                      Icons.school_rounded,
                      'UKM',
                      selectedMenu == 'ukm',
                      () => onMenuSelected('ukm'),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildNavItem(
                      Icons.history_rounded,
                      'History',
                      selectedMenu == 'history' || selectedMenu == 'histori',
                      () => onMenuSelected('history'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4169E1) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.blue[600] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
