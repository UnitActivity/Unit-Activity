import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/services/user_notification_service.dart';
import 'package:unit_activity/widgets/user_sidebar.dart';
import 'package:unit_activity/widgets/qr_scanner_mixin.dart';
import 'package:unit_activity/user/dashboard_user.dart';
import 'package:unit_activity/user/event.dart';
import 'package:unit_activity/user/ukm.dart';
import 'package:unit_activity/user/history.dart';
import 'package:unit_activity/user/profile.dart';

class NotifikasiUserPage extends StatefulWidget {
  const NotifikasiUserPage({super.key});

  @override
  State<NotifikasiUserPage> createState() => _NotifikasiUserPageState();
}

class _NotifikasiUserPageState extends State<NotifikasiUserPage>
    with QRScannerMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final UserNotificationService _notificationService =
      UserNotificationService();
  String _selectedMenu = 'notifikasi';

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationUpdate);
    _notificationService.loadNotifications();
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMenuSelected(String menu) {
    setState(() {
      _selectedMenu = menu;
    });
    // Close drawer on mobile
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }

    // Navigate based on menu
    switch (menu) {
      case 'dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardUser()),
        );
        break;
      case 'event':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserEventPage()),
        );
        break;
      case 'ukm':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserUKMPage()),
        );
        break;
      case 'histori':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryPage()),
        );
        break;
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: isDesktop
          ? null
          : Drawer(
              child: UserSidebar(
                selectedMenu: _selectedMenu,
                onMenuSelected: _handleMenuSelected,
                onLogout: _handleLogout,
              ),
            ),
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar - Desktop only
              if (isDesktop)
                UserSidebar(
                  selectedMenu: _selectedMenu,
                  onMenuSelected: _handleMenuSelected,
                  onLogout: _handleLogout,
                ),

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 70), // Space for floating top bar
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildNotificationContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: isDesktop ? 260 : 0,
            right: 0,
            child: _buildFloatingTopBar(isMobile: !isDesktop),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(),
    );
  }

  Widget _buildFloatingTopBar({required bool isMobile}) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isMobile)
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          Text(
            'Pemberitahuan',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          // QR Scanner Button (Desktop only)
          if (!isMobile) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () =>
                    openQRScannerDialog(onCodeScanned: _handleQRCodeScanned),
                icon: Icon(Icons.qr_code_scanner, color: Colors.blue[700]),
                tooltip: 'Scan QR Code',
              ),
            ),
            const SizedBox(width: 12),
          ],
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== QR SCANNER HANDLER ====================
  void _handleQRCodeScanned(String code) {
    print('DEBUG: QR Code scanned: $code');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR Code scanned: $code'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildNotificationContent() {
    final notifications = _notificationService.notifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with mark all as read
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Semua Pemberitahuan',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            if (_notificationService.unreadCount > 0)
              TextButton.icon(
                onPressed: () {
                  _notificationService.markAllAsRead();
                },
                icon: const Icon(Icons.done_all, size: 18),
                label: Text(
                  'Tandai semua telah dibaca',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_notificationService.unreadCount} belum dibaca dari ${notifications.length} pemberitahuan',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        // Notification list
        if (notifications.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Icon(
                  Icons.notifications_off_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada pemberitahuan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pemberitahuan dari admin akan muncul di sini',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          ),
      ],
    );
  }

  Widget _buildNotificationCard(UserNotification notification) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.shade200
              : Colors.blue.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _notificationService.markAsRead(notification.id);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon based on type
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getIconColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(notification.type),
                    color: _getIconColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4169E1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'BARU',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getIconColor(
                            notification.type,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notification.typeName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getIconColor(notification.type),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.message,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.timeAgo,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'announcement':
        return Icons.campaign;
      case 'reminder':
        return Icons.alarm;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'event':
        return Colors.blue;
      case 'announcement':
        return Colors.orange;
      case 'reminder':
        return Colors.purple;
      case 'info':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBottomNavBar() {
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  Icons.dashboard_outlined,
                  'Dashboard',
                  'dashboard',
                ),
                _buildNavItem(Icons.event_outlined, 'Event', 'event'),
                _buildNavItem(Icons.groups_outlined, 'UKM', 'ukm'),
                _buildNavItem(Icons.history_outlined, 'Histori', 'histori'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String menu) {
    final isSelected = _selectedMenu == menu;
    return InkWell(
      onTap: () => _handleMenuSelected(menu),
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
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isSelected ? const Color(0xFF4169E1) : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
