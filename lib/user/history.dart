import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/widgets/user_sidebar.dart';
import 'package:unit_activity/widgets/qr_scanner_mixin.dart';
import 'package:unit_activity/widgets/notification_bell_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:unit_activity/user/notifikasi_user.dart';
import 'package:unit_activity/user/profile.dart';
import 'package:unit_activity/user/dashboard_user.dart';
import 'package:unit_activity/user/event.dart';
import 'package:unit_activity/user/ukm.dart';
import 'package:unit_activity/services/user_dashboard_service.dart';
import 'package:unit_activity/services/attendance_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with QRScannerMixin, TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedMenu = 'history';
  final UserDashboardService _dashboardService = UserDashboardService();
  final AttendanceService _attendanceService = AttendanceService();

  bool _isLoading = true;
  bool _isLoadingPertemuan = true;
  Map<String, List<Map<String, dynamic>>> _historyData = {};
  List<Map<String, dynamic>> _pertemuanData = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistoryData();
    _loadPertemuanData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPertemuanData() async {
    setState(() => _isLoadingPertemuan = true);

    try {
      final pertemuanList = await _dashboardService.getUserPertemuan();

      setState(() {
        _pertemuanData = pertemuanList;
        _isLoadingPertemuan = false;
      });
    } catch (e) {
      print('Error loading pertemuan: $e');
      setState(() => _isLoadingPertemuan = false);
    }
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);

    try {
      // getUserHistory returns Map<String, List<Map<String, dynamic>>>
      final historyData = await _dashboardService.getUserHistory();

      // Transform the data to include additional fields
      final Map<String, List<Map<String, dynamic>>> groupedData = {};

      for (var entry in historyData.entries) {
        final periodKey = entry.key;
        groupedData[periodKey] = [];

        for (var event in entry.value) {
          groupedData[periodKey]!.add({
            'id': event['id']?.toString() ?? '',
            'title': event['title'] ?? event['nama_event'] ?? 'Unnamed Event',
            'description': event['description'] ?? event['deskripsi'] ?? '',
            'tanggal_mulai': event['date_start'] ?? event['tanggal_mulai'],
            'tanggal_selesai': event['date_end'] ?? event['tanggal_selesai'],
            'lokasi': event['location'] ?? event['lokasi'] ?? '',
            'biaya': event['biaya'],
            'gambar': event['image'] ?? event['gambar'],
            'ukm_name': event['ukm_name'] ?? '',
            'status': event['status'] ?? 'selesai',
            'logbook_url': event['logbook'] ?? event['logbook_url'],
            'is_attended': event['is_attended'] ?? false,
            'illustration':
                event['illustration'] ?? _getIllustrationByType(null),
          });
        }
      }

      // Sort periods descending (newest first)
      final sortedKeys = groupedData.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      final sortedData = <String, List<Map<String, dynamic>>>{};
      for (var key in sortedKeys) {
        sortedData[key] = groupedData[key]!;
      }

      setState(() {
        _historyData = sortedData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getIllustrationByType(String? kategori) {
    switch (kategori?.toLowerCase()) {
      case 'olahraga':
        return 'person_badminton';
      case 'esport':
      case 'gaming':
        return 'person_gaming';
      case 'alam':
      case 'camping':
        return 'person_camping';
      default:
        return 'person_camping';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 70), // Space for floating header
              
              // Header Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Riwayat Aktivitas',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue[700],
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue[700],
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Event'),
                    Tab(text: 'Pertemuan'),
                  ],
                ),
              ),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventHistoryTab(isMobile: true),
                    _buildPertemuanTab(isMobile: true),
                  ],
                ),
              ),
            ],
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

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: 250,
                child: UserSidebar(
                  selectedMenu: 'histori',
                  onMenuSelected: (menu) {
                    if (menu == 'dashboard') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardUser(),
                        ),
                      );
                    } else if (menu == 'event') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserEventPage(),
                        ),
                      );
                    } else if (menu == 'ukm') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserUKMPage(),
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
                  onLogout: _showLogoutDialog,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 70),
                    // Header Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Riwayat Aktivitas',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                    // Tab Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue[700],
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Colors.blue[700],
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Event'),
                          Tab(text: 'Pertemuan'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEventHistoryTab(isMobile: false),
                          _buildPertemuanTab(isMobile: false),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Riwayat',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kamu belum mengikuti event apapun.\nAyo ikuti event yang tersedia!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserEventPage()),
                );
              },
              icon: const Icon(Icons.event),
              label: const Text('Lihat Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
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

  List<Widget> _buildHistoryList() {
    return _historyData.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Periode ${entry.key}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...entry.value.map((activity) {
            return _buildActivityCard(activity);
          }),
          const SizedBox(height: 16),
        ],
      );
    }).toList();
  }

  // ==================== ACTIVITY CARD ====================
  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryDetailPage(
              activity: activity,
              onRefresh: _loadHistoryData,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Event Image or Illustration
            Container(
              width: isMobile ? 70 : 100,
              height: isMobile ? 70 : 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                image: activity['gambar'] != null
                    ? DecorationImage(
                        image: NetworkImage(activity['gambar']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: activity['gambar'] == null
                  ? _buildIllustration(activity['illustration'])
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // UKM Badge
                  if (activity['ukm_name'] != null &&
                      activity['ukm_name'].isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activity['ukm_name'],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  Text(
                    activity['title'],
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 14 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(activity['tanggal_selesai']),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (activity['is_attended'] == true) 
                          ? Colors.green[50] 
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (activity['is_attended'] == true) 
                              ? Icons.check_circle 
                              : Icons.schedule,
                          size: 12,
                          color: (activity['is_attended'] == true) 
                              ? Colors.green[700] 
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (activity['is_attended'] == true) ? 'Hadir' : 'Selesai',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: (activity['is_attended'] == true) 
                                ? Colors.green[700] 
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: isMobile ? 14 : 18,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(String type) {
    return CustomPaint(painter: IllustrationPainter(type: type));
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

      // Refresh data after successful attendance
      if (result['success']) {
        await _loadHistoryData();
        await _loadPertemuanData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
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

  // ==================== EVENT HISTORY TAB ====================
  Widget _buildEventHistoryTab({required bool isMobile}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadHistoryData();
        await _loadPertemuanData();
      },
      child: _historyData.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Column(
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
                        child: Icon(
                          Icons.history,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Histori Event',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Riwayat event yang pernah kamu ikuti',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildHistoryList(),
                ],
              ),
            ),
    );
  }

  // ==================== PERTEMUAN TAB ====================
  Widget _buildPertemuanTab({required bool isMobile}) {
    if (_isLoadingPertemuan) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadHistoryData();
        await _loadPertemuanData();
      },
      child: _pertemuanData.isEmpty
          ? _buildEmptyPertemuanState()
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.groups,
                          color: Colors.purple[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pertemuan UKM',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pertemuan dari UKM yang kamu ikuti',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildPertemuanList(isMobile),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildPertemuanList(bool isMobile) {
    return _pertemuanData.map((pertemuan) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Could navigate to pertemuan detail if needed
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon section
                Container(
                  width: isMobile ? 60 : 80,
                  height: isMobile ? 60 : 80,
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.groups,
                    size: isMobile ? 30 : 40,
                    color: Colors.purple[700],
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pertemuan['judul'] ?? 'Pertemuan',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pertemuan['user_status_hadir'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: pertemuan['user_status_hadir'] == 'hadir'
                                    ? Colors.green[50]
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                pertemuan['user_status_hadir'] == 'hadir'
                                    ? 'Hadir'
                                    : 'Tidak Hadir',
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      pertemuan['user_status_hadir'] == 'hadir'
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // UKM Badge
                      if (pertemuan['ukm_name'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pertemuan['ukm_name'],
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 10 : 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: isMobile ? 12 : 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _formatDate(pertemuan['tanggal']),
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: isMobile ? 12 : 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${pertemuan['waktu_mulai'] ?? '-'} - ${pertemuan['waktu_selesai'] ?? '-'}',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (pertemuan['lokasi'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: isMobile ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                pertemuan['lokasi'],
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyPertemuanState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada pertemuan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pertemuan dari UKM yang kamu ikuti\nakan muncul di sini',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
      case 'history':
        // Already on history page
        break;
    }
  }
}

// ==================== ILLUSTRATION PAINTER ====================
class IllustrationPainter extends CustomPainter {
  final String type;

  IllustrationPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    if (type == 'person_camping') {
      canvas.drawCircle(Offset(cx - 10, cy - 15), 6, fillPaint);
      canvas.drawLine(Offset(cx - 10, cy - 9), Offset(cx - 10, cy + 5), paint);
      canvas.drawLine(Offset(cx - 10, cy + 5), Offset(cx - 20, cy + 15), paint);
      canvas.drawLine(Offset(cx - 10, cy + 5), Offset(cx, cy + 15), paint);
      canvas.drawLine(Offset(cx - 10, cy - 5), Offset(cx - 20, cy + 5), paint);
      canvas.drawLine(Offset(cx - 10, cy - 5), Offset(cx, cy), paint);
      canvas.drawCircle(Offset(cx + 15, cy + 10), 8, paint);
      canvas.drawCircle(Offset(cx + 15, cy + 10), 4, paint);
    } else if (type == 'person_badminton') {
      canvas.drawCircle(Offset(cx, cy - 20), 6, fillPaint);
      canvas.drawLine(Offset(cx, cy - 14), Offset(cx, cy + 5), paint);
      canvas.drawLine(Offset(cx, cy + 5), Offset(cx - 10, cy + 20), paint);
      canvas.drawLine(Offset(cx, cy + 5), Offset(cx + 10, cy + 20), paint);
      canvas.drawLine(Offset(cx, cy - 10), Offset(cx - 15, cy - 20), paint);
      canvas.drawLine(Offset(cx, cy - 10), Offset(cx + 15, cy - 20), paint);
      canvas.drawCircle(Offset(cx - 20, cy - 25), 6, paint);
    } else if (type == 'person_gaming') {
      canvas.drawCircle(Offset(cx, cy - 15), 6, fillPaint);
      canvas.drawLine(Offset(cx, cy - 9), Offset(cx, cy + 5), paint);
      canvas.drawLine(Offset(cx, cy - 5), Offset(cx - 15, cy), paint);
      canvas.drawLine(Offset(cx, cy - 5), Offset(cx + 15, cy), paint);
      final rectPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + 5), width: 20, height: 10),
          const Radius.circular(5),
        ),
        rectPaint,
      );
      canvas.drawLine(Offset(cx, cy + 5), Offset(cx - 8, cy + 20), paint);
      canvas.drawLine(Offset(cx, cy + 5), Offset(cx + 8, cy + 20), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== HISTORY DETAIL PAGE ====================
class HistoryDetailPage extends StatefulWidget {
  final Map<String, dynamic> activity;
  final VoidCallback? onRefresh;

  const HistoryDetailPage({super.key, required this.activity, this.onRefresh});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserDashboardService _dashboardService = UserDashboardService();

  List<Map<String, dynamic>> _participants = []; // Attendees
  List<Map<String, dynamic>> _registeredParticipants = []; // Registered
  bool _isLoadingParticipants = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadParticipants();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoadingParticipants = true);

    try {
      final eventId = widget.activity['id']?.toString() ?? '';
      
      // Load attendees (those who already attended via QR scan)
      final participants = await _dashboardService.getEventParticipants(eventId);
      
      // Load registered participants (those who registered but may not have attended yet)
      final registered = await _dashboardService.getEventRegisteredParticipants(eventId);

      setState(() {
        _participants = participants;
        _registeredParticipants = registered;
        _isLoadingParticipants = false;
      });
    } catch (e) {
      print('Error loading participants: $e');
      setState(() => _isLoadingParticipants = false);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Gratis';
    try {
      final value = double.parse(amount.toString());
      if (value == 0) return 'Gratis';
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(value);
    } catch (e) {
      return amount.toString();
    }
  }

  Future<void> _downloadLogbook() async {
    setState(() => _isDownloading = true);

    try {
      final logbookUrl = widget.activity['logbook_url'];

      if (logbookUrl != null && logbookUrl.isNotEmpty) {
        // In a real implementation, you would use url_launcher or download the file
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.download_done, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(child: Text('Logbook berhasil didownload!')),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Logbook belum tersedia untuk event ini'),
                ),
              ],
            ),
            backgroundColor: Colors.orange[600],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading logbook: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return _buildMobileDetailLayout(context);
    } else {
      return _buildDesktopDetailLayout(context);
    }
  }

  // ==================== MOBILE DETAIL LAYOUT ====================
  Widget _buildMobileDetailLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Detail Event',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeaderCard(isMobile: true),
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue[700],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[700],
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Peserta'),
              Tab(text: 'Logbook'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildParticipantsTab(isMobile: true),
                _buildLogbookTab(isMobile: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DESKTOP DETAIL LAYOUT ====================
  Widget _buildDesktopDetailLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildHeaderCard(isMobile: false),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              TabBar(
                                controller: _tabController,
                                labelColor: Colors.blue[700],
                                unselectedLabelColor: Colors.grey[600],
                                indicatorColor: Colors.blue[700],
                                labelStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                                tabs: const [
                                  Tab(text: 'Peserta'),
                                  Tab(text: 'Logbook'),
                                ],
                              ),
                              SizedBox(
                                height: 400,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildParticipantsTab(isMobile: false),
                                    _buildLogbookTab(isMobile: false),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildHeaderCard({required bool isMobile}) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 0),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          Container(
            width: isMobile ? 80 : 150,
            height: isMobile ? 80 : 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              image: widget.activity['gambar'] != null
                  ? DecorationImage(
                      image: NetworkImage(widget.activity['gambar']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.activity['gambar'] == null
                ? CustomPaint(
                    painter: IllustrationPainter(
                      type: widget.activity['illustration'] ?? 'person_camping',
                    ),
                  )
                : null,
          ),
          SizedBox(width: isMobile ? 12 : 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // UKM Badge
                if (widget.activity['ukm_name'] != null &&
                    widget.activity['ukm_name'].isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.activity['ukm_name'],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                Text(
                  widget.activity['title'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Event Selesai',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.calendar_today,
                  _formatDate(widget.activity['tanggal_mulai']),
                  isMobile,
                ),
                const SizedBox(height: 6),
                _buildDetailRow(
                  Icons.location_on,
                  widget.activity['lokasi'] ?? '-',
                  isMobile,
                ),
                const SizedBox(height: 6),
                _buildDetailRow(
                  Icons.monetization_on,
                  _formatCurrency(widget.activity['biaya']),
                  isMobile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogbookTab({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logbook Event',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download logbook untuk melihat rekap kegiatan event',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.description, size: 48, color: Colors.blue[600]),
                const SizedBox(height: 12),
                Text(
                  'Logbook ${widget.activity['title']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Format: PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadLogbook,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _isDownloading ? 'Downloading...' : 'Download Logbook',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildParticipantsTab({required bool isMobile}) {
    if (_isLoadingParticipants) {
      return const Center(child: CircularProgressIndicator());
    }

    // Create a map of attended user IDs for quick lookup
    final attendedUserIds = <String>{};
    for (var p in _participants) {
      final userId = p['users']?['id_user']?.toString() ?? '';
      if (userId.isNotEmpty) attendedUserIds.add(userId);
    }

    if (_registeredParticipants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Belum ada peserta yang terdaftar',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      itemCount: _registeredParticipants.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final participant = _registeredParticipants[index];
        final user = participant['users'];
        final participantUserId = user?['id_user']?.toString() ?? '';
        final hasAttended = attendedUserIds.contains(participantUserId);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: hasAttended 
                    ? Colors.green.withOpacity(0.1) 
                    : const Color(0xFF4169E1).withOpacity(0.1),
                child: Text(
                  (user?['nama'] ?? user?['username'] ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: hasAttended ? Colors.green[700] : const Color(0xFF4169E1),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['nama'] ?? user?['username'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user?['nim']?.toString() ?? user?['email'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasAttended ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasAttended ? 'Hadir' : 'Terdaftar',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: hasAttended ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar(BuildContext context) {
    return UserSidebar(
      selectedMenu: 'historu',
      onMenuSelected: (menu) {
        if (menu == 'dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardUser()),
          );
        } else if (menu == 'event') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserEventPage()),
          );
        } else if (menu == 'ukm') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserUKMPage()),
          );
        } else if (menu == 'histori') {
          Navigator.pop(context); // Go back to History page list
        }
      },
      onLogout: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      ),
    );
  }

  Widget _buildMenuItemDetail(
    IconData icon,
    String title,
    String route,
    BuildContext context,
  ) {
    final isSelected = title == 'Histori';
    return InkWell(
      onTap: () {
        if (route == 'dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardUser()),
          );
        } else if (route == 'event') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserEventPage()),
          );
        } else if (route == 'ukm') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserUKMPage()),
          );
        } else if (route == 'history') {
          // Already on history
        } else if (route == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.blue[700]! : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.blue[700] : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue[700] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TOP BAR ====================
  Widget _buildTopBar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isMobile)
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/user'),
              icon: const Icon(Icons.home_outlined),
            ),
          if (!isMobile) const SizedBox(width: 8),
          if (!isMobile)
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          if (!isMobile) const SizedBox(width: 8),
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
          if (!isMobile) const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF4169E1).withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  size: 24,
                  color: Color(0xFF4169E1),
                ),
              ),
            ),
          ),
          if (!isMobile) const SizedBox(width: 8),
          if (!isMobile)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ),
              child: const Text(
                'Adam',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, bool isMobile) {
    return Row(
      children: [
        Icon(icon, size: isMobile ? 14 : 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
