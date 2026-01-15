import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/user_notification_service.dart';
import 'package:unit_activity/services/attendance_service.dart';
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
  final UserNotificationService _notificationService = UserNotificationService(); // Instantiate locally
  final AttendanceService _attendanceService = AttendanceService();
  String _selectedMenu = 'notifikasi';
  String _filterType = 'all'; // 'all', 'admin', 'ukm', 'event'
  // No scroll controller needed for pagination
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationUpdate);
    
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    // Auto-refresh unread count periodically
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
       _notificationService.fetchUnreadCount();
    });
  }

  Future<void> _loadData() async {
    await _notificationService.loadPage(0);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationService.removeListener(_onNotificationUpdate);
    super.dispose();
  }
  
  void _onNotificationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleRefresh() async {
    await _notificationService.refresh();
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet =
        MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 70,
                left: 12,
                right: 12,
                bottom: 80,
              ),
              child: _buildNotificationContent(),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingTopBar(isMobile: true),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 70),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: UserSidebar(
                        selectedMenu: _selectedMenu,
                        onMenuSelected: _handleMenuSelected,
                        onLogout: _showLogoutDialog,
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: _buildNotificationContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 200,
            right: 0,
            child: _buildFloatingTopBar(isMobile: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar - Desktop only
              SizedBox(
                width: 260,
                child: UserSidebar(
                  selectedMenu: _selectedMenu,
                  onMenuSelected: _handleMenuSelected,
                  onLogout: _showLogoutDialog,
                ),
              ),

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 70), // Space for floating top bar
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: _buildNotificationContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 260,
            right: 0,
            child: _buildFloatingTopBar(isMobile: false),
          ),
        ],
      ),
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
          PopupMenuButton<String>(
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
                    Text('Logout', style: TextStyle(color: Colors.red[600])),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF4169E1).withOpacity(0.2),
              child: const Icon(
                Icons.person,
                color: Color(0xFF4169E1),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
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
            Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (e) {
                debugPrint('Error signing out: $e');
              }
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
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

  // ==================== QR SCANNER HANDLER ====================
  Future<void> _handleQRCodeScanned(String code) async {
    print('DEBUG: QR Code scanned: $code');

    try {
      final result = await _attendanceService.processQRCodeAttendance(code);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result['success'] ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(result['message'])),
            ],
          ),
          backgroundColor: result['success']
              ? Colors.green[600]
              : Colors.red[600],
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  List<UserNotification> _getFilteredNotifications() {
    final notifications = _notificationService.notifications;
    if (_filterType == 'all') return notifications;

    return notifications.where((n) {
      switch (_filterType) {
        case 'admin':
          return n.sender == 'Admin';
        case 'ukm':
          return n.sender != 'Admin' && n.sender != 'Sistem';
        case 'event':
          return n.type == 'event';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildNotificationContent() {
    final filteredNotifications = _getFilteredNotifications();
    final allNotifications = _notificationService.notifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with mark all as read
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semua Pemberitahuan',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_notificationService.unreadCount} belum dibaca dari ${allNotifications.length} pemberitahuan',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (_notificationService.unreadCount > 0)
              TextButton.icon(
                onPressed: () {
                  _notificationService.markAllAsRead();
                },
                icon: const Icon(Icons.done_all, size: 18),
                label: Text(
                  'Tandai semua',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'Semua', Icons.all_inbox),
              const SizedBox(width: 8),
              _buildFilterChip('admin', 'Admin', Icons.admin_panel_settings),
              const SizedBox(width: 8),
              _buildFilterChip('ukm', 'UKM', Icons.groups),
              const SizedBox(width: 8),
              _buildFilterChip('event', 'Event', Icons.event),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Notification list
        if (filteredNotifications.isEmpty && !_notificationService.isLoading)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada pemberitahuan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _filterType == 'all'
                      ? 'Pemberitahuan akan muncul di sini'
                      : 'Tidak ada pemberitahuan untuk filter ini',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredNotifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index];
              return _buildNotificationCard(notification);
            },
          ),

          // Loading Indicator
          if (_notificationService.isLoading)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 20),
               child: Center(
                 child: SizedBox(
                   width: 24,
                   height: 24,
                   child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue[600]),
                 ),
               ),             ),

          // Pagination Controls
          if (allNotifications.isNotEmpty || _notificationService.currentPage > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   // Previous Button
                   ElevatedButton.icon(
                     onPressed: !_notificationService.isLoading && _notificationService.currentPage > 0
                         ? () => _notificationService.prevPage()
                         : null,
                     icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                     label: const Text('Sebelumnya'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.white,
                       foregroundColor: Colors.blue[700],
                       disabledBackgroundColor: Colors.grey[100],
                       disabledForegroundColor: Colors.grey[400],
                       elevation: 0,
                       side: BorderSide(color: Colors.grey.shade300),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                     ),
                   ),

                   const SizedBox(width: 16),

                   // Page Indicator
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.blue[50],
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: Colors.blue.shade100),
                     ),
                     child: Text(
                       'Hal ${_notificationService.currentPage + 1}',
                       style: GoogleFonts.poppins(
                         fontWeight: FontWeight.w600,
                         color: Colors.blue[800],
                         fontSize: 12,
                       ),
                     ),
                   ),

                   const SizedBox(width: 16),

                   // Next Button
                   ElevatedButton(
                     onPressed: !_notificationService.isLoading && _notificationService.hasMore
                         ? () => _notificationService.nextPage()
                         : null,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.white,
                       foregroundColor: Colors.blue[700],
                       disabledBackgroundColor: Colors.grey[100],
                       disabledForegroundColor: Colors.grey[400],
                       elevation: 0,
                       side: BorderSide(color: Colors.grey.shade300),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                     ),
                     child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           const Text('Selanjutnya'),
                           const SizedBox(width: 8),
                           const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        ],
                     ),
                   ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String type, String label, IconData icon) {
    final isSelected = _filterType == type;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = type;
        });
      },
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : Colors.grey[600],
      ),
      label: Text(label),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isSelected ? Colors.white : Colors.grey[700],
      ),
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.blue[600],
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildNotificationCard(UserNotification notification) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.shade200
              : Colors.blue.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _notificationService.markAsRead(notification.id);
          },
          borderRadius: BorderRadius.circular(16),
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
                              style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Sender and Type badges
                      Row(
                        children: [
                          // Sender Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getSenderColor(
                                notification.sender,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSenderIcon(notification.sender),
                                  size: 12,
                                  color: _getSenderColor(notification.sender),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notification.sender,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getSenderColor(notification.sender),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Type Badge
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
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getIconColor(notification.type),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notification.message,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.timeAgo,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade500,
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

  Color _getSenderColor(String sender) {
    if (sender == 'Admin') {
      return Colors.red;
    } else if (sender == 'Sistem') {
      return Colors.grey;
    } else {
      // UKM
      return Colors.blue;
    }
  }

  IconData _getSenderIcon(String sender) {
    if (sender == 'Admin') {
      return Icons.admin_panel_settings;
    } else if (sender == 'Sistem') {
      return Icons.computer;
    } else {
      // UKM
      return Icons.groups;
    }
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
