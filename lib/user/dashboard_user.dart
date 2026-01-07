import 'package:flutter/material.dart';
import 'package:unit_activity/widgets/user_sidebar.dart';
import 'package:unit_activity/widgets/qr_scanner_mixin.dart';
import 'package:unit_activity/widgets/notification_bell_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/user/notifikasi_user.dart';
import 'package:unit_activity/user/profile.dart';
import 'package:unit_activity/user/event.dart';
import 'package:unit_activity/user/ukm.dart';
import 'package:unit_activity/user/history.dart';
import 'package:unit_activity/services/user_dashboard_service.dart';
import 'package:unit_activity/services/attendance_service.dart';
import 'dart:async';

class DashboardUser extends StatefulWidget {
  const DashboardUser({super.key});

  @override
  State<DashboardUser> createState() => _DashboardUserState();
}

class _DashboardUserState extends State<DashboardUser> with QRScannerMixin {
  int _currentSlideIndex = 0;
  String _selectedMenu = 'dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserDashboardService _dashboardService = UserDashboardService();
  final AttendanceService _attendanceService = AttendanceService();
  Timer? _autoSlideTimer;

  bool _isLoadingEvents = true;
  bool _isLoadingSchedule = true;
  List<Map<String, dynamic>> _sliderEvents = [];
  List<Map<String, dynamic>> _ukmSchedule = [];

  final List<int> eSportsData = [4, 4, 4, 4, 6, 7, 8, 7, 6, 5, 5, 5];
  final List<int> badmintonData = [5, 5, 4, 3, 3, 4, 4, 5, 4, 4, 5, 5];
  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late List<int> _statistikData1 = [];
  late List<int> _statistikData2 = [];
  late String _statistikLabel1 = '';
  late String _statistikLabel2 = '';
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadSliderEvents();
    _loadStatisticsData();
    _loadScheduleData();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  /// Start auto-slide timer for slider
  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_sliderEvents.isNotEmpty && mounted) {
        setState(() {
          _currentSlideIndex = (_currentSlideIndex + 1) % _sliderEvents.length;
        });
      }
    });
  }

  /// Load schedule data from database
  Future<void> _loadScheduleData() async {
    try {
      setState(() => _isLoadingSchedule = true);

      final schedules = await _dashboardService.getUpcomingSchedules(limit: 10);

      // Convert to UI format with icons and colors
      final colors = [
        Colors.orange,
        Colors.blue,
        Colors.purple,
        Colors.green,
        Colors.red,
      ];
      final icons = {'event': Icons.event, 'pertemuan': Icons.groups};

      if (mounted) {
        setState(() {
          _ukmSchedule = schedules.asMap().entries.map((entry) {
            final item = entry.value;
            final index = entry.key;
            return {
              'id': item['id'],
              'type': item['type'],
              'title': item['title'] ?? 'UKM',
              'subtitle': item['subtitle'] ?? '',
              'date': _formatDate(item['date']),
              'time': item['time'] ?? '',
              'location': item['location'] ?? 'Lokasi belum ditentukan',
              'icon': icons[item['type']] ?? Icons.event,
              'color': colors[index % colors.length],
            };
          }).toList();

          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      print('Error loading schedule: $e');
      if (mounted) {
        setState(() {
          _ukmSchedule = [];
          _isLoadingSchedule = false;
        });
      }
    }
  }

  /// Format date string
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
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
      return '${days[date.weekday % 7]}, ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  /// Handle QR Code scanned - records attendance to database
  void _handleQRCodeScanned(String code) async {
    print('========== QR CODE SCANNED ==========');
    print('Code: $code');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text('Memproses absensi...', style: GoogleFonts.inter()),
          ],
        ),
      ),
    );

    // Process attendance
    final result = await _attendanceService.processQRCodeAttendance(code);

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    // Show result
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: result['success']
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  result['success'] ? Icons.check_circle : Icons.error,
                  color: result['success'] ? Colors.green : Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result['success'] ? 'Berhasil!' : 'Gagal',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['message'] ?? 'Terjadi kesalahan',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
              if (result['success'] && result['time'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Jam: ${result['time']}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: result['success'] ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadStatisticsData() async {
    try {
      // Get top 2 UKMs by number of events/activities
      final ukmResponse = await _supabase
          .from('ukm')
          .select('id_ukm, nama_ukm')
          .limit(2);

      if (ukmResponse.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
        return;
      }

      List<int> data1 = [];
      List<int> data2 = [];

      // Load meeting counts for first UKM
      if (ukmResponse.isNotEmpty) {
        final ukm1Id = ukmResponse[0]['id_ukm'];
        final meetings1 = await _supabase
            .from('pertemuan')
            .select('id_pertemuan')
            .eq('id_ukm', ukm1Id);

        _statistikLabel1 = ukmResponse[0]['nama_ukm'] ?? 'UKM 1';

        // Generate monthly data based on available meetings
        int meetingCount = meetings1.length;
        data1 = List.generate(12, (index) {
          // Distribute meetings throughout the year
          if (meetingCount > 0) {
            final monthData = (meetingCount / (index + 1)).toInt();
            return monthData.clamp(0, 10).toInt();
          }
          return (4 + (index % 4)).toInt();
        });
      }

      // Load meeting counts for second UKM
      if (ukmResponse.length > 1) {
        final ukm2Id = ukmResponse[1]['id_ukm'];
        final meetings2 = await _supabase
            .from('pertemuan')
            .select('id_pertemuan')
            .eq('id_ukm', ukm2Id);

        _statistikLabel2 = ukmResponse[1]['nama_ukm'] ?? 'UKM 2';

        int meetingCount = meetings2.length;
        data2 = List.generate(12, (index) {
          if (meetingCount > 0) {
            final monthData = (meetingCount / (index + 1)).toInt();
            return monthData.clamp(0, 10).toInt();
          }
          return (5 + (index % 3)).toInt();
        });
      } else {
        // If only 1 UKM, use fallback for second
        _statistikLabel2 = 'UKM Lainnya';
        data2 = List.generate(12, (index) => (5 + (index % 3)).toInt());
      }

      if (mounted) {
        setState(() {
          _statistikData1 = data1.isNotEmpty
              ? data1
              : [4, 4, 4, 4, 6, 7, 8, 7, 6, 5, 5, 5];
          _statistikData2 = data2.isNotEmpty
              ? data2
              : [5, 5, 4, 3, 3, 4, 4, 5, 4, 4, 5, 5];
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _statistikData1 = [4, 4, 4, 4, 6, 7, 8, 7, 6, 5, 5, 5];
          _statistikData2 = [5, 5, 4, 3, 3, 4, 4, 5, 4, 4, 5, 5];
          _statistikLabel1 = 'UKM 1';
          _statistikLabel2 = 'UKM 2';
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadSliderEvents() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      print('========== DEBUG INFORMASI ==========');
      print('Current user ID: $userId');

      List<Map<String, dynamic>> allInformasi = [];

      // 1. Load informasi from Admin (id_ukm is null or empty)
      final adminResponse = await _supabase
          .from('informasi')
          .select(
            'id_informasi, judul, deskripsi, gambar, create_at, status_aktif, id_ukm',
          )
          .eq('status', 'Publish')
          .eq('status_aktif', true)
          .filter('id_ukm', 'is', null)
          .order('create_at', ascending: false)
          .limit(10);

      print('Admin informasi count: ${(adminResponse as List).length}');

      for (var item in adminResponse) {
        String? imageUrl;
        if (item['gambar'] != null) {
          try {
            imageUrl = _supabase.storage
                .from('informasi-images')
                .getPublicUrl(item['gambar']);
          } catch (e) {
            print('Error getting image URL: $e');
          }
        }

        allInformasi.add({
          'id': item['id_informasi'],
          'title': item['judul'] ?? 'Informasi',
          'description': item['deskripsi'] ?? '',
          'subtitle': 'Admin',
          'source': 'admin',
          'date': _formatDate(item['create_at']),
          'imageUrl': imageUrl,
          'image': null,
        });
      }

      // 2. Load informasi from UKM that user has joined
      if (userId != null) {
        try {
          // Get UKMs user has joined
          final userUkms = await _supabase
              .from('user_halaman_ukm')
              .select('id_ukm, ukm(nama_ukm)')
              .eq('id_user', userId)
              .eq('status', 'active');

          print('User joined UKMs: ${(userUkms as List).length}');

          if (userUkms.isNotEmpty) {
            final ukmIds = userUkms.map((e) => e['id_ukm']).toList();

            // Get informasi from these UKMs
            final ukmResponse = await _supabase
                .from('informasi')
                .select(
                  'id_informasi, judul, deskripsi, gambar, create_at, status_aktif, id_ukm, ukm(nama_ukm)',
                )
                .inFilter('id_ukm', ukmIds)
                .eq('status_aktif', true)
                .order('create_at', ascending: false)
                .limit(10);

            print('UKM informasi count: ${(ukmResponse as List).length}');

            for (var item in ukmResponse) {
              String? imageUrl;
              if (item['gambar'] != null) {
                try {
                  imageUrl = _supabase.storage
                      .from('informasi-images')
                      .getPublicUrl(item['gambar']);
                } catch (e) {
                  print('Error getting image URL: $e');
                }
              }

              allInformasi.add({
                'id': item['id_informasi'],
                'title': item['judul'] ?? 'Informasi',
                'description': item['deskripsi'] ?? '',
                'subtitle': item['ukm']?['nama_ukm'] ?? 'UKM',
                'source': 'ukm',
                'date': _formatDate(item['create_at']),
                'imageUrl': imageUrl,
                'image': null,
              });
            }
          }
        } catch (e) {
          print('Error loading UKM informasi: $e');
        }
      }

      // Sort by date (newest first)
      allInformasi.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['date']);
          final dateB = DateTime.parse(b['date']);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      // Take top 5
      final topInformasi = allInformasi.take(5).toList();

      print('Total informasi loaded: ${topInformasi.length}');
      print('====================================');

      if (mounted) {
        setState(() {
          _sliderEvents = topInformasi;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      print('========== ERROR ==========');
      print('ERROR loading informasi: $e');
      print('===========================');

      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
          _sliderEvents = [];
        });
      }
    }
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 70,
              left: 12,
              right: 12,
              bottom: 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInformasiTerkini(isMobile: true),
                const SizedBox(height: 24),
                _buildJadwalUKM(isMobile: true),
                const SizedBox(height: 24),
                _buildStatistik(isMobile: true),
              ],
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

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Row(
            children: [
              UserSidebar(
                selectedMenu: _selectedMenu,
                onMenuSelected: _handleMenuSelected,
                onLogout: _handleLogout,
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 70),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInformasiTerkini(isMobile: false),
                            const SizedBox(height: 24),
                            _buildJadwalUKM(isMobile: false),
                            const SizedBox(height: 24),
                            _buildStatistik(isMobile: false),
                          ],
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
            left: 250,
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
                selectedMenu: _selectedMenu,
                onMenuSelected: _handleMenuSelected,
                onLogout: _handleLogout,
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 70),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInformasiTerkini(isMobile: false),
                            const SizedBox(height: 32),
                            _buildJadwalUKM(isMobile: false),
                            const SizedBox(height: 32),
                            _buildStatistik(isMobile: false),
                          ],
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

  void _handleMenuSelected(String menu) {
    setState(() {
      _selectedMenu = menu;
    });

    // Navigate based on menu selection
    switch (menu) {
      case 'dashboard':
        // Already on dashboard, do nothing
        break;
      case 'event':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserEventPage()),
        );
        break;
      case 'ukm':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserUKMPage()),
        );
        break;
      case 'histori':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryPage()),
        );
        break;
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  void _handleLogout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  /// Navigate to informasi detail page
  void _navigateToInformasiDetail(Map<String, dynamic> item) {
    // Show detail in a modal bottom sheet for now
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header image
            if (item['imageUrl'] != null)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(item['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: item['source'] == 'admin'
                            ? Colors.purple.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['subtitle'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item['source'] == 'admin'
                              ? Colors.purple
                              : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      item['title'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item['date'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      item['description'] ?? 'Tidak ada deskripsi',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
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
                    Navigator.pushNamed(context, '/user/notifikasi');
                  },
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  ),
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
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
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

  // ==================== BOTTOM NAVIGATION BAR (MOBILE) ====================
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
                  Icons.home_rounded,
                  'Dashboard',
                  _selectedMenu == 'dashboard',
                  () => _handleMenuSelected('dashboard'),
                ),
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
                _buildNavItem(
                  Icons.school_rounded,
                  'UKM',
                  _selectedMenu == 'ukm',
                  () => _handleMenuSelected('ukm'),
                ),
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
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.blue[600] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INFORMASI TERKINI ====================
  Widget _buildInformasiTerkini({required bool isMobile}) {
    final sliderHeight = isMobile ? 220 : 300;

    if (_isLoadingEvents) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Terkini',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            height: sliderHeight.toDouble(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(color: Colors.blue[600]),
            ),
          ),
        ],
      );
    }

    // Show empty state if no informasi available
    if (_sliderEvents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Terkini',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            height: sliderHeight.toDouble(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: isMobile ? 48 : 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada informasi',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Informasi dari admin akan muncul di sini',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Terkini',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: sliderHeight.toDouble(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Image and content
                Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image - prioritize imageUrl from database
                    _sliderEvents[_currentSlideIndex]['imageUrl'] != null
                        ? Image.network(
                            _sliderEvents[_currentSlideIndex]['imageUrl']!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Show placeholder if image fails to load
                              return Container(
                                color: Colors.blue[300],
                                child: Center(
                                  child: Icon(
                                    Icons.info,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.blue[300],
                            child: Center(
                              child: Icon(
                                Icons.info,
                                size: 80,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                    // Dark gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    // Title and info
                    Positioned(
                      bottom: isMobile ? 12 : 24,
                      left: isMobile ? 12 : 24,
                      right: isMobile ? 60 : 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Source badge (Admin or UKM)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _sliderEvents[_currentSlideIndex]['source'] ==
                                      'admin'
                                  ? Colors.purple.withOpacity(0.9)
                                  : Colors.blue.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _sliderEvents[_currentSlideIndex]['source'] ==
                                          'admin'
                                      ? Icons.admin_panel_settings
                                      : Icons.school,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _sliderEvents[_currentSlideIndex]['subtitle'] ??
                                      '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _sliderEvents[_currentSlideIndex]['title'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 14 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _sliderEvents[_currentSlideIndex]['date'] ?? '',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isMobile ? 10 : 12,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  // Navigate to informasi detail page
                                  final currentItem =
                                      _sliderEvents[_currentSlideIndex];
                                  _navigateToInformasiDetail(currentItem);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8 : 12,
                                    vertical: isMobile ? 4 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Lebih Lanjut',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isMobile ? 10 : 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: isMobile ? 4 : 6),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: isMobile ? 12 : 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Previous button (left)
                if (_sliderEvents.length > 1)
                  Positioned(
                    left: isMobile ? 8 : 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _currentSlideIndex =
                                  (_currentSlideIndex -
                                      1 +
                                      _sliderEvents.length) %
                                  _sliderEvents.length;
                            });
                          },
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Next button (right)
                if (_sliderEvents.length > 1)
                  Positioned(
                    right: isMobile ? 8 : 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _currentSlideIndex =
                                  (_currentSlideIndex + 1) %
                                  _sliderEvents.length;
                            });
                          },
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Dot indicators
                if (_sliderEvents.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _sliderEvents.length,
                        (index) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentSlideIndex == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== JADWAL UKM ====================
  Widget _buildJadwalUKM({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Jadwal UKM',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_ukmSchedule.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserUKMPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Lihat Semua'),
                ),
            ],
          )
        else
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Jadwal UKM',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        _isLoadingSchedule
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            : _ukmSchedule.isEmpty
            ? _buildEmptySchedule(isMobile)
            : isMobile
            ? _buildJadwalMobileList()
            : _buildJadwalDesktopList(),
      ],
    );
  }

  Widget _buildEmptySchedule(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: isMobile ? 48 : 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada jadwal',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jadwal akan muncul setelah kamu bergabung dengan UKM',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserUKMPage()),
              );
            },
            icon: const Icon(Icons.groups, size: 18),
            label: const Text('Lihat UKM'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: isMobile ? 10 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalDesktopList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _ukmSchedule.length,
        itemBuilder: (context, index) {
          return _buildJadwalCard(_ukmSchedule[index], false);
        },
      ),
    );
  }

  Widget _buildJadwalMobileList() {
    return Column(
      children: _ukmSchedule.map((item) {
        return _buildJadwalCard(item, true);
      }).toList(),
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> item, bool isMobile) {
    return isMobile
        ? Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  (item['color'] as Color).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (item['color'] as Color).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (item['color'] as Color).withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (item['color'] as Color).withOpacity(0.1),
                        (item['color'] as Color).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      topRight: Radius.circular(11),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (item['color'] as Color),
                              (item['color'] as Color).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: (item['color'] as Color).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildJadwalInfo(
                        Icons.calendar_today,
                        item['date'],
                        isMobile,
                        item['color'] as Color,
                      ),
                      const SizedBox(height: 8),
                      _buildJadwalInfo(
                        Icons.access_time,
                        item['time'],
                        isMobile,
                        item['color'] as Color,
                      ),
                      const SizedBox(height: 8),
                      _buildJadwalInfo(
                        Icons.location_on,
                        item['location'],
                        isMobile,
                        item['color'] as Color,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Container(
            width: 320,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  (item['color'] as Color).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (item['color'] as Color).withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (item['color'] as Color).withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (item['color'] as Color).withOpacity(0.15),
                        (item['color'] as Color).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (item['color'] as Color),
                              (item['color'] as Color).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (item['color'] as Color).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildJadwalInfo(
                          Icons.calendar_today,
                          item['date'],
                          isMobile,
                          item['color'] as Color,
                        ),
                        _buildJadwalInfo(
                          Icons.access_time,
                          item['time'],
                          isMobile,
                          item['color'] as Color,
                        ),
                        _buildJadwalInfo(
                          Icons.location_on,
                          item['location'],
                          isMobile,
                          item['color'] as Color,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildJadwalInfo(
    IconData icon,
    String text,
    bool isMobile,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: isMobile ? 14 : 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 11 : 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATISTIK ====================
  Widget _buildStatistik({required bool isMobile}) {
    final chartHeight = isMobile ? 280 : 360;

    if (_isLoadingStats) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Jumlah Pertemuan UKM Tahunan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tahun 2025',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Container(
            height: chartHeight.toDouble(),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(color: Colors.blue[600]),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Jumlah Pertemuan UKM Tahunan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tahun 2025',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Container(
          height: chartHeight.toDouble(),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: LineChartPainter(
                    eSportsData: _statistikData1.isNotEmpty
                        ? _statistikData1
                        : [4, 4, 4, 4, 6, 7, 8, 7, 6, 5, 5, 5],
                    badmintonData: _statistikData2.isNotEmpty
                        ? _statistikData2
                        : [5, 5, 4, 3, 3, 4, 4, 5, 4, 4, 5, 5],
                    months: months,
                  ),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    Colors.blue[600]!,
                    _statistikLabel1.isNotEmpty ? _statistikLabel1 : 'UKM 1',
                    isMobile,
                  ),
                  SizedBox(width: isMobile ? 16 : 24),
                  _buildLegendItem(
                    Colors.yellow[700]!,
                    _statistikLabel2.isNotEmpty ? _statistikLabel2 : 'UKM 2',
                    isMobile,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isMobile) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Custom Line Chart Painter
class LineChartPainter extends CustomPainter {
  final List<int> eSportsData;
  final List<int> badmintonData;
  final List<String> months;

  LineChartPainter({
    required this.eSportsData,
    required this.badmintonData,
    required this.months,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const leftPadding = 35.0;
    const rightPadding = 15.0;
    const topPadding = 15.0;
    const bottomPadding = 35.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1;

    for (int i = 0; i <= 6; i++) {
      final y = topPadding + (chartHeight / 6) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (int i = 0; i <= 6; i++) {
      final value = 12 - (i * 2);
      final y = topPadding + (chartHeight / 6) * i;

      textPainter.text = TextSpan(
        text: value.toString(),
        style: const TextStyle(color: Colors.black, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    for (int i = 0; i < months.length; i++) {
      final x = leftPadding + (chartWidth / (months.length - 1)) * i;
      textPainter.text = TextSpan(
        text: months[i],
        style: const TextStyle(color: Colors.black, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 8),
      );
    }

    paint.color = Colors.blue[600]!;
    final eSportsPath = Path();
    for (int i = 0; i < eSportsData.length; i++) {
      final x = leftPadding + (chartWidth / (eSportsData.length - 1)) * i;
      final y = topPadding + chartHeight - (eSportsData[i] / 12) * chartHeight;
      if (i == 0) {
        eSportsPath.moveTo(x, y);
      } else {
        eSportsPath.lineTo(x, y);
      }
    }
    canvas.drawPath(eSportsPath, paint);

    paint.color = Colors.yellow[700]!;
    final badmintonPath = Path();
    for (int i = 0; i < badmintonData.length; i++) {
      final x = leftPadding + (chartWidth / (badmintonData.length - 1)) * i;
      final y =
          topPadding + chartHeight - (badmintonData[i] / 12) * chartHeight;
      if (i == 0) {
        badmintonPath.moveTo(x, y);
      } else {
        badmintonPath.lineTo(x, y);
      }
    }
    canvas.drawPath(badmintonPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
