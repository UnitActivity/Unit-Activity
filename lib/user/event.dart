import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/widgets/user_sidebar.dart';
import 'package:unit_activity/widgets/qr_scanner_mixin.dart';
import 'package:unit_activity/widgets/notification_bell_widget.dart';
import 'package:unit_activity/user/notifikasi_user.dart';
import 'package:unit_activity/user/profile.dart';
import 'package:unit_activity/user/dashboard_user.dart';
import 'package:unit_activity/user/ukm.dart';
import 'package:unit_activity/user/history.dart';
import 'package:unit_activity/user/event_detail_user.dart';
import 'package:unit_activity/services/user_dashboard_service.dart';
import 'package:unit_activity/services/attendance_service.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

class UserEventPage extends StatefulWidget {
  const UserEventPage({super.key});

  @override
  State<UserEventPage> createState() => _UserEventPageState();
}

class _UserEventPageState extends State<UserEventPage>
    with QRScannerMixin, TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedMenu = 'event';
  final UserDashboardService _dashboardService = UserDashboardService();
  final AttendanceService _attendanceService = AttendanceService();
  final CustomAuthService _authService = CustomAuthService();

  // Tab controller for event categories
  late TabController _tabController;

  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _followedEvents = [];
  List<Map<String, dynamic>> _myUKMEvents = [];
  bool _isLoading = true;
  Set<String> _registeredEventIds = {};
  List<String> _userUKMIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      // Load user's joined UKMs
      await _loadUserUKMs();

      // Load all events from database
      final events = await _dashboardService.getAllEvents();

      // Load user's registered events
      final registeredEvents = await _dashboardService
          .getUserRegisteredEvents();

      // Get set of registered event IDs
      _registeredEventIds = registeredEvents
          .map((e) => e['events']?['id_events']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      // Map events to UI format
      _allEvents = events.map((event) {
        final eventId = event['id_events']?.toString() ?? '';
        final ukmId = event['id_ukm']?.toString() ?? '';
        return {
          'id': eventId,
          'id_ukm': ukmId,
          'title': event['nama_event'] ?? 'Event',
          'image': null,
          'date': _formatDate(event['tanggal_mulai']),
          'time':
              '${event['jam_mulai'] ?? ''} - ${event['jam_akhir'] ?? ''} WIB',
          'location': event['lokasi'] ?? '',
          'description': event['deskripsi'] ?? '',
          'isRegistered': _registeredEventIds.contains(eventId),
          'isMyUKM': _userUKMIds.contains(ukmId),
          'ukm_name': event['ukm']?['nama_ukm'] ?? '',
          'ukm_logo': event['ukm']?['logo'],
          'max_participant': event['max_participant'],
          'tanggal_mulai': event['tanggal_mulai'],
          'tanggal_akhir': event['tanggal_akhir'],
          'jam_mulai': event['jam_mulai'],
          'jam_akhir': event['jam_akhir'],
          'id_events': eventId,
          'nama_event': event['nama_event'],
          'lokasi': event['lokasi'],
        };
      }).toList();

      // Filter followed events
      _followedEvents = _allEvents
          .where((e) => e['isRegistered'] == true)
          .toList();

      // Filter events from user's UKMs
      _myUKMEvents = _allEvents.where((e) => e['isMyUKM'] == true).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserUKMs() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = _authService.currentUserId;

      if (userId == null || userId.isEmpty) {
        _userUKMIds = [];
        return;
      }

      final response = await supabase
          .from('user_halaman_ukm')
          .select('id_ukm')
          .eq('id_user', userId)
          .or('status.eq.aktif,status.eq.active');

      _userUKMIds = (response as List)
          .map((e) => e['id_ukm']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      print('DEBUG: User joined ${_userUKMIds.length} UKMs');
    } catch (e) {
      print('Error loading user UKMs: $e');
      _userUKMIds = [];
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      final days = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
      ];
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _viewEventDetail(Map<String, dynamic> event) {
    // Navigate to detail page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserEventDetailPage(eventId: event['id_events']?.toString() ?? ''),
      ),
    ).then((_) {
      // Refresh data when returning
      _loadEvents();
    });
  }

  /// Handle QR Code scanned for attendance
  Future<void> _handleQRCodeScanned(String code) async {
    try {
      final result = await _attendanceService.processQRCodeAttendance(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result['success'] == true ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(result['message'] ?? 'Proses selesai')),
              ],
            ),
            backgroundColor: result['success'] == true
                ? Colors.green[600]
                : Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh events if successful
        if (result['success'] == true) {
          _loadEvents();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width < 1200;

    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Top bar
          _buildFloatingTopBar(isMobile: true),
          const SizedBox(height: 16),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              indicator: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(height: 42, text: 'Seluruh Event'),
                Tab(height: 42, text: 'Event Diikuti'),
                Tab(height: 42, text: 'UKM Saya'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventTabContent(
                        _allEvents,
                        'Belum ada event tersedia',
                        isMobile: true,
                      ),
                      _buildEventTabContent(
                        _followedEvents,
                        'Belum ada event yang diikuti',
                        isMobile: true,
                      ),
                      _buildEventTabContent(
                        _myUKMEvents,
                        'Belum ada event dari UKM yang kamu ikuti',
                        isMobile: true,
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Build event content for each tab
  Widget _buildEventTabContent(
    List<Map<String, dynamic>> events,
    String emptyMessage, {
    required bool isMobile,
  }) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: GridView.builder(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile
              ? 1
              : (MediaQuery.of(context).size.width < 1200 ? 2 : 3),
          mainAxisSpacing: isMobile ? 12 : 16,
          crossAxisSpacing: isMobile ? 12 : 16,
          childAspectRatio: isMobile ? 1.4 : 1.3,
        ),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(events[index]);
        },
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Row(
            children: [
              UserSidebar(
                selectedMenu: 'event',
                onMenuSelected: (menu) {
                  if (menu == 'dashboard') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardUser(),
                      ),
                    );
                  } else if (menu == 'ukm') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserUKMPage(),
                      ),
                    );
                  } else if (menu == 'histori') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryPage(),
                      ),
                    );
                  } else if (menu == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  }
                },
                onLogout: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 70), // Space for floating top bar
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue[700],
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Colors.blue[700],
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Seluruh Event'),
                          Tab(text: 'Event yang Diikuti'),
                          Tab(text: 'Event dari UKM Saya'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildEventTabContent(
                                  _allEvents,
                                  'Belum ada event tersedia',
                                  isMobile: false,
                                ),
                                _buildEventTabContent(
                                  _followedEvents,
                                  'Belum ada event yang diikuti',
                                  isMobile: false,
                                ),
                                _buildEventTabContent(
                                  _myUKMEvents,
                                  'Belum ada event dari UKM yang kamu ikuti',
                                  isMobile: false,
                                ),
                              ],
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

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Row(
            children: [
              UserSidebar(
                selectedMenu: 'event',
                onMenuSelected: (menu) {
                  if (menu == 'dashboard') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardUser(),
                      ),
                    );
                  } else if (menu == 'ukm') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserUKMPage(),
                      ),
                    );
                  } else if (menu == 'histori') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryPage(),
                      ),
                    );
                  } else if (menu == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  }
                },
                onLogout: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 70), // Space for floating top bar
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue[700],
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Colors.blue[700],
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Seluruh Event'),
                          Tab(text: 'Event yang Diikuti'),
                          Tab(text: 'Event dari UKM Saya'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildEventTabContent(
                                  _allEvents,
                                  'Belum ada event tersedia',
                                  isMobile: false,
                                ),
                                _buildEventTabContent(
                                  _followedEvents,
                                  'Belum ada event yang diikuti',
                                  isMobile: false,
                                ),
                                _buildEventTabContent(
                                  _myUKMEvents,
                                  'Belum ada event dari UKM yang kamu ikuti',
                                  isMobile: false,
                                ),
                              ],
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

  // ==================== FLOATING TOP BAR ====================
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
      child: isMobile
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NotificationBellWidget(
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotifikasiUserPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'profile') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
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
                          Text(
                            'Logout',
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // QR Scanner Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => openQRScannerDialog(
                      onCodeScanned: _handleQRCodeScanned,
                    ),
                    icon: Icon(Icons.qr_code_scanner, color: Colors.blue[700]),
                    tooltip: 'Scan QR Code',
                  ),
                ),
                const SizedBox(width: 12),
                NotificationBellWidget(
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotifikasiUserPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'profile') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
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
                          Text(
                            'Logout',
                            style: TextStyle(color: Colors.red[600]),
                          ),
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

  // ==================== MOBILE EVENT LIST ====================
  Widget _buildEventListViewMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.event, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Seluruh Event',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _allEvents.isEmpty
            ? _buildEmptyState('Belum ada event tersedia')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: _allEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_allEvents[index]);
                },
              ),
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Event yang diikuti',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _followedEvents.isEmpty
            ? _buildEmptyState('Belum ada event yang diikuti')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: _followedEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_followedEvents[index]);
                },
              ),
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.groups, color: Colors.purple[700], size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Event dari UKM Saya',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _myUKMEvents.isEmpty
            ? _buildEmptyState('Belum ada event dari UKM yang kamu ikuti')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: _myUKMEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_myUKMEvents[index]);
                },
              ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ==================== TABLET EVENT LIST ====================
  Widget _buildEventListViewTablet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.event, color: Colors.blue[700], size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Seluruh Event',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _allEvents.isEmpty
            ? _buildEmptyState('Belum ada event tersedia')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                ),
                itemCount: _allEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_allEvents[index]);
                },
              ),
        const SizedBox(height: 32),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Event yang diikuti',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _followedEvents.isEmpty
            ? _buildEmptyState('Belum ada event yang diikuti')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                ),
                itemCount: _followedEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_followedEvents[index]);
                },
              ),
        const SizedBox(height: 32),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.groups, color: Colors.purple[700], size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Event dari UKM Saya',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _myUKMEvents.isEmpty
            ? _buildEmptyState('Belum ada event dari UKM yang kamu ikuti')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                ),
                itemCount: _myUKMEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_myUKMEvents[index]);
                },
              ),
      ],
    );
  }

  // ==================== DESKTOP EVENT LIST ====================
  Widget _buildEventListViewDesktop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event, color: Colors.blue[700], size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              'Seluruh Event',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _allEvents.isEmpty
            ? _buildEmptyState('Belum ada event tersedia')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                itemCount: _allEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_allEvents[index]);
                },
              ),
        const SizedBox(height: 40),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Event yang diikuti',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _followedEvents.isEmpty
            ? _buildEmptyState('Belum ada event yang diikuti')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                itemCount: _followedEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_followedEvents[index]);
                },
              ),
        const SizedBox(height: 40),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.groups, color: Colors.purple[700], size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              'Event dari UKM Saya',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _myUKMEvents.isEmpty
            ? _buildEmptyState('Belum ada event dari UKM yang kamu ikuti')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                itemCount: _myUKMEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_myUKMEvents[index]);
                },
              ),
      ],
    );
  }

  // ==================== EVENT CARD ====================
  Widget _buildEventCard(Map<String, dynamic> event) {
    final String eventId = event['id_events']?.toString() ?? '';
    final String? imageUrl = event['gambar'];
    final String title = event['nama_event'] ?? 'Event';
    final String location = event['lokasi'] ?? '-';
    final String? dateStr = event['tanggal_mulai'];
    final bool isRegistered = _registeredEventIds.contains(event['id_events']);
    final bool isMyUKM = event['isMyUKM'] == true;
    final String ukmName = event['ukm_name'] ?? '';
    // ukm_logo available in event['ukm_logo'] if needed

    return InkWell(
      key: ValueKey(eventId),
      onTap: () => _viewEventDetail(event),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              cacheWidth: 400, // Optimize memory
                              cacheHeight: 300,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.event,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.event,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                  // UKM Badge
                  if (ukmName.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isMyUKM
                              ? Colors.purple[700]
                              : Colors.blue[700],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMyUKM ? Icons.star : Icons.groups,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ukmName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Registration badge
                  if (isRegistered)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Terdaftar',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr != null ? _formatDate(dateStr) : '-',
                              style: GoogleFonts.poppins(
                                color: Colors.blue[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BOTTOM NAVIGATION BAR ====================
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
                // Dashboard
                _buildNavItem(
                  Icons.home_rounded,
                  'Dashboard',
                  _selectedMenu == 'dashboard',
                  () => _handleMenuSelected('dashboard'),
                ),
                // Event
                _buildNavItem(
                  Icons.event_rounded,
                  'Event',
                  _selectedMenu == 'event',
                  () => _handleMenuSelected('event'),
                ),
                // Center QR Scanner button
                Container(
                  width: 56,
                  height: 56,
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
                      onTap: () => openQRScannerDialog(
                        onCodeScanned: _handleQRCodeScanned,
                      ),
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
                // UKM
                _buildNavItem(
                  Icons.school_rounded,
                  'UKM',
                  _selectedMenu == 'ukm',
                  () => _handleMenuSelected('ukm'),
                ),
                // History
                _buildNavItem(
                  Icons.history_rounded,
                  'History',
                  _selectedMenu == 'history',
                  () => _handleMenuSelected('history'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NAV ITEM WIDGET ====================
  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue[600] : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue[600] : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MENU HANDLERS ====================
  void _handleMenuSelected(String menu) {
    if (_selectedMenu == menu) return;

    setState(() {
      _selectedMenu = menu;
    });

    switch (menu) {
      case 'dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardUser()),
        );
        break;
      case 'event':
        // Already on event page
        break;
      case 'ukm':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserUKMPage()),
        );
        break;
      case 'history':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryPage()),
        );
        break;
    }
  }
}
