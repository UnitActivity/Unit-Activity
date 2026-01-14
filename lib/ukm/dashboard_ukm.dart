import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/components/ukm_sidebar.dart';
import 'package:unit_activity/widgets/ukm_header.dart';
import 'package:unit_activity/ukm/peserta_ukm.dart';
import 'package:unit_activity/ukm/event_ukm.dart';
import 'package:unit_activity/ukm/pertemuan_ukm.dart';
import 'package:unit_activity/ukm/informasi_ukm.dart';
import 'package:unit_activity/ukm/notifikasi_ukm.dart';
import 'package:unit_activity/ukm/akun_ukm.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';
import 'package:unit_activity/services/custom_auth_service.dart';
import 'package:unit_activity/services/event_service_new.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:unit_activity/auth/login.dart';

class DashboardUKMPage extends StatefulWidget {
  const DashboardUKMPage({super.key});

  @override
  State<DashboardUKMPage> createState() => _DashboardUKMPageState();
}

class _DashboardUKMPageState extends State<DashboardUKMPage> {
  String _selectedMenu = 'dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final UkmDashboardService _dashboardService = UkmDashboardService();
  final CustomAuthService _authService = CustomAuthService();
  final EventService _eventService = EventService();
  final PageController _pageController = PageController();
  final _supabase = Supabase.instance.client;
  Timer? _carouselTimer;

  // Helper to get public URL for informasi image
  String _getInformasiImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) return imagePath;
    // Otherwise, get public URL from informasi-images bucket
    return _supabase.storage.from('informasi-images').getPublicUrl(imagePath);
  }

  // Dashboard data
  String _ukmName = 'UKM Dashboard';
  String? _ukmLogo;
  String _periode = '2025.1';
  String? _ukmId;
  String? _periodeId;

  // Statistics data
  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _informasiList = [];
  List<dynamic> _upcomingEventsList = [];
  List<Map<String, dynamic>> _eventTrendData = [];
  List<Map<String, dynamic>> _topMembers = [];
  List<dynamic>? _alerts;
  bool _isLoadingStats = true;
  bool _isLoadingInformasi = true;
  String? _errorMessage;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoadData() async {
    print('========== DASHBOARD AUTH CHECK ==========');

    // Check if user is authenticated using CustomAuthService
    if (!_authService.isLoggedIn) {
      print('❌ User not logged in');
      // User not logged in, redirect to login
      if (mounted) {
        setState(() {
          _errorMessage = 'Anda belum login. Silakan login terlebih dahulu.';
          _isLoadingStats = false;
          _isLoadingInformasi = false;
        });
      }
      return;
    }

    print('✅ User logged in: ${_authService.currentUserRole}');
    print('User data: ${_authService.currentUser}');

    // User is authenticated, load dashboard data
    _loadDashboardData();
  }

  // Load all dashboard data
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingStats = true;
      _isLoadingInformasi = true;
      _errorMessage = null;
    });

    try {
      // Get current UKM details (includes UKM ID and name)
      final ukmDetailsResponse = await _dashboardService.getCurrentUkmDetails();

      if (ukmDetailsResponse == null) {
        setState(() {
          _errorMessage =
              'Tidak dapat mengidentifikasi UKM. Pastikan akun Anda terdaftar sebagai admin UKM dan memiliki profil UKM.';
          _isLoadingStats = false;
          _isLoadingInformasi = false;
        });
        return;
      }

      // Set UKM ID and name
      _ukmId = ukmDetailsResponse['id_ukm'];
      setState(() {
        _ukmName = ukmDetailsResponse['nama_ukm'] ?? 'UKM Dashboard';
        
        // Process logo URL
        final String? rawLogo = ukmDetailsResponse['logo'];
        if (rawLogo != null && rawLogo.isNotEmpty) {
          if (rawLogo.startsWith('http')) {
            _ukmLogo = rawLogo;
          } else {
            // Generate public URL for 'ukm-logos' bucket
            _ukmLogo = _supabase.storage.from('ukm-logos').getPublicUrl(rawLogo);
          }
        } else {
          _ukmLogo = null;
        }
      });

      // Get current periode
      final periode = await _dashboardService.getCurrentPeriode(_ukmId!);
      if (periode != null) {
        setState(() {
          _periodeId = periode['id_periode'];
          _periode = '${periode['semester']} ${periode['tahun']}';
        });
      }

      // Load stats, informasi, and events in parallel
      final results = await Future.wait([
        _dashboardService.getUkmStats(_ukmId!, periodeId: _periodeId),
        _dashboardService.getUkmInformasi(
          _ukmId!,
          limit: 5,
          periodeId: _periodeId,
        ),
        _loadUpcomingEvents(),
        _loadEventTrendData(),
        _dashboardService.getAlerts(_ukmId!),
        _dashboardService.getTopMembers(_ukmId!),
      ]);

      if (mounted) {
        setState(() {
          // Update statistics: results[0]
          final statsResult = results[0] as Map<String, dynamic>;
          if (statsResult['success'] == true) {
            _dashboardStats = statsResult['data'];
          }

          // Update informasi: results[1]
          final infoResult = results[1] as Map<String, dynamic>;
          if (infoResult['success'] == true) {
            _informasiList = infoResult['data'] ?? [];
            if (_informasiList.length > 1) {
              _startCarouselAutoPlay();
            }
          }

          // Update alerts: results[4]
          final alertsResult = results[4] as Map<String, dynamic>;
          if (alertsResult['success'] == true) {
            _alerts = alertsResult['data'];
          }

          // Update Top Members: results[5]
          if (results[5] is List) {
            _topMembers = List<Map<String, dynamic>>.from(results[5] as List);
          }

          _isLoadingStats = false;
          _isLoadingInformasi = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data dashboard';
          _isLoadingStats = false;
          _isLoadingInformasi = false;
        });
      }
    }
  }

  void _startCarouselAutoPlay() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_informasiList.isEmpty || !mounted) {
        timer.cancel();
        return;
      }

      // Check if PageController is attached before animating
      if (!_pageController.hasClients) {
        return;
      }

      final nextIndex = (_currentCarouselIndex + 1) % _informasiList.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<Map<String, dynamic>> _loadUpcomingEvents() async {
    try {
      if (_ukmId == null) return {'success': false};

      // Get events for this UKM that are upcoming (tanggal_mulai >= today)
      final now = DateTime.now();
      final events = await _dashboardService.supabase
          .from('events')
          .select('*')
          .eq('id_ukm', _ukmId!)
          .gte('tanggal_mulai', now.toIso8601String().split('T')[0])
          .order('tanggal_mulai', ascending: true)
          .limit(5);

      if (mounted) {
        setState(() {
          _upcomingEventsList = events ?? [];
        });
      }
      return {'success': true};
    } catch (e) {
      print('Error loading upcoming events: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> _loadEventTrendData() async {
    try {
      if (_ukmId == null) return {'success': false};

      // Get all events for this UKM
      final events = await _eventService.getEventsByUkm(
        ukmId: _ukmId!,
        periodeId: _periodeId,
      );

      // Calculate event trend for last 6 months
      final now = DateTime.now();
      final List<Map<String, dynamic>> monthlyData = [];

      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);

        // Count events in this month
        int count = events.where((event) {
          if (event['tanggal_mulai'] == null) return false;
          try {
            final eventDate = DateTime.parse(event['tanggal_mulai'].toString());
            return eventDate.year == monthDate.year &&
                eventDate.month == monthDate.month;
          } catch (e) {
            return false;
          }
        }).length;

        // Get month name
        final monthName = _getMonthName(monthDate.month);

        monthlyData.add({
          'month': monthName,
          'count': count,
          'monthNumber': monthDate.month,
        });
      }

      if (mounted) {
        setState(() {
          _eventTrendData = monthlyData;
        });
      }

      return {'success': true};
    } catch (e) {
      print('Error loading event trend data: $e');
      return {'success': false};
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  void _handleMenuSelected(String menu) {
    setState(() {
      _selectedMenu = menu;
    });
    // Close drawer on mobile
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    // Reload dashboard data when navigating back to dashboard
    if (menu == 'dashboard') {
      _loadDashboardData();
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
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
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
      backgroundColor: Colors.grey[100],
      drawer: !isDesktop
          ? Drawer(
              child: UKMSidebar(
                selectedMenu: _selectedMenu,
                onMenuSelected: _handleMenuSelected,
                onLogout: _handleLogout,
              ),
            )
          : null,
      body: Row(
        children: [
          // Desktop Sidebar
          if (isDesktop)
            UKMSidebar(
              selectedMenu: _selectedMenu,
              onMenuSelected: _handleMenuSelected,
              onLogout: _handleLogout,
            ),

          // Main Content
          Expanded(
            child: Stack(
              children: [
                // Content Area
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: isDesktop ? 20 : 14,
                      right: isDesktop ? 20 : 14,
                      top: isDesktop ? 95 : 75,
                      bottom: isDesktop ? 20 : 16,
                    ),
                    child: _buildContent(isDesktop),
                  ),
                ),

                // Floating Header
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: UKMHeader(
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    onLogout: _handleLogout,
                    onMenuSelected: _handleMenuSelected,
                    ukmName: _ukmName,
                    ukmLogo: _ukmLogo,
                    periode: _periode,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDesktop) {
    switch (_selectedMenu) {
      case 'dashboard':
        return _buildDashboardContent(isDesktop);
      case 'peserta':
        return const PesertaUKMPage();
      case 'event':
        return const EventUKMPage();
      case 'pertemuan':
        return const PertemuanUKMPage();
      case 'informasi':
        return const InformasiUKMPage();
      case 'notifikasi':
        return const NotifikasiUKMPage();
      case 'profile':
        return const AkunUKMPage();
      default:
        return _buildDashboardContent(isDesktop);
    }
  }

  Widget _buildDashboardContent(bool isDesktop) {
    // Show loading state
    if (_isLoadingStats && _isLoadingInformasi) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Memuat dashboard...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      final isNotLoggedIn = _errorMessage!.contains('belum login');

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNotLoggedIn ? Icons.lock_outline : Icons.error_outline,
                size: 60,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isNotLoggedIn)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                icon: const Icon(Icons.login, size: 20),
                label: Text(
                  'Login Sekarang',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(
                  'Coba Lagi',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
          ],
        ),
      );
    }

    // Show dashboard content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alerts & Warnings Section
        _buildAlertsSection(isDesktop),
        const SizedBox(height: 24),

        // Statistics Cards
        _buildStatisticsCards(isDesktop),
        const SizedBox(height: 24),

        // Event Trend & Top Members Row
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildEventTrend()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTopMembers()),
                ],
              )
            : Column(
                children: [
                  _buildEventTrend(),
                  const SizedBox(height: 16),
                  _buildTopMembers(),
                ],
              ),
        const SizedBox(height: 24),

        // Recent Activities & Upcoming Events
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRecentActivities()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUpcomingEvents()),
                ],
              )
            : Column(
                children: [
                  _buildRecentActivities(),
                  const SizedBox(height: 16),
                  _buildUpcomingEvents(),
                ],
              ),
      ],
    );
  }

  Widget _buildAlertsSection(bool isDesktop) {
    // Collect all alerts
    final allAlerts = <Map<String, dynamic>>[];

    // Add API alerts
    if (_alerts?.isNotEmpty ?? false) {
      allAlerts.addAll(_alerts!.cast<Map<String, dynamic>>());
    }

    // Add static guides if empty
    final totalEvent = _dashboardStats?['totalEvent'] ?? 0;
    final totalPeserta = _dashboardStats?['totalPeserta'] ?? 0;

    if (totalEvent == 0) {
      allAlerts.add({
        'type': 'info',
        'title': 'Belum Ada Event',
        'message': 'Buat event pertama untuk UKM Anda',
        'count': 0,
      });
    }

    if (totalPeserta < 10) {
      allAlerts.add({
        'type': 'info',
        'title': 'Rekrutmen Anggota',
        'message': 'Tambah anggota baru untuk memperkuat UKM',
        'count': 0,
      });
    }

    if (allAlerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Alerts & Warnings',
              style: GoogleFonts.inter(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...allAlerts.map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isWarning = alert['type'] == 'warning';
    final color = isWarning ? Colors.orange : const Color(0xFF4169E1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isWarning ? Icons.warning_rounded : Icons.info_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'],
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          if (alert['count'] != null && alert['count'] > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${alert['count']}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventTrend() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Event Trend',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: (_eventTrendData.isEmpty)
                ? Center(
                    child: Text(
                      'Belum ada data event',
                      style: GoogleFonts.inter(color: Colors.grey[400]),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getEventMaxY(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => Colors.blue[700]!,
                            tooltipRoundedRadius: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final index = group.x.toInt();
                              if (index < 0 ||
                                  index >= _eventTrendData.length) {
                                return null;
                              }
                              final month =
                                  _eventTrendData[index]['month'] ?? '';
                              final count = rod.toY.toInt();
                              return BarTooltipItem(
                                '$month\n$count event',
                                GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < _eventTrendData.length) {
                                  final month = _eventTrendData[index]['month'];
                                  if (month != null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        month.toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: _getEventYInterval(),
                              reservedSize: 32,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value == meta.max) return const Text('');
                                return Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _getEventYInterval(),
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[200]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        barGroups: _eventTrendData.asMap().entries.map((entry) {
                          final count = entry.value['count'];
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: (count is int ? count : 0).toDouble(),
                                color: Colors.blue[700]!,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _getEventMaxY() {
    if (_eventTrendData.isEmpty) return 10;
    try {
      final maxCount = _eventTrendData
          .map((d) => (d['count'] as int?) ?? 0)
          .reduce((a, b) => a > b ? a : b);
      // Add 20% padding to max value, minimum 5
      return (maxCount * 1.2).ceilToDouble().clamp(5, double.infinity);
    } catch (e) {
      return 10;
    }
  }

  double _getEventYInterval() {
    final maxY = _getEventMaxY();
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    return 20;
  }

  Widget _buildTopMembers() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Top Anggota',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _topMembers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Belum ada data',
                      style: GoogleFonts.inter(color: Colors.grey[400]),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topMembers.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey[100]),
                  itemBuilder: (context, index) {
                    final member = _topMembers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // Rank
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? Colors.amber
                                  : index == 1
                                  ? Colors.grey[400]
                                  : index == 2
                                  ? Colors.brown[300]
                                  : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                color: index < 3
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Avatar
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue[50],
                            backgroundImage: member['picture'] != null
                                ? NetworkImage(member['picture'])
                                : null,
                            child: member['picture'] == null
                                ? Text(
                                    (member['nama'] ?? 'U')[0].toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // Name & NIM
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member['nama'] ?? 'Unknown',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  member['nim'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Attendance Count
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${member['kehadiran_count']}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Activities',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Belum ada aktivitas',
              style: GoogleFonts.inter(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Upcoming Events',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _upcomingEventsList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada event mendatang',
                          style: GoogleFonts.inter(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _upcomingEventsList.length > 3
                      ? 3
                      : _upcomingEventsList.length,
                  itemBuilder: (context, index) {
                    final event = _upcomingEventsList[index];
                    final tanggal = event['tanggal_mulai'] != null
                        ? DateTime.parse(event['tanggal_mulai'])
                        : null;
                    final tanggalStr = tanggal != null
                        ? '${tanggal.day}/${tanggal.month}/${tanggal.year}'
                        : '-';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.event,
                              color: Colors.green[700],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['nama_event'] ?? 'Event',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tanggalStr,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildInformasiCarousel(bool isDesktop) {
    // Handle empty state
    if (_informasiList.isEmpty) {
      return Container(
        height: isDesktop ? 300 : 250,
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum ada informasi',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Carousel with PageView
        SizedBox(
          height: isDesktop ? 300 : 250,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
                itemCount: _informasiList.length,
                itemBuilder: (context, index) {
                  final info = _informasiList[index];
                  return _buildCarouselItem(info, isDesktop);
                },
              ),

              // Navigation Arrows (only show on desktop and when multiple items)
              if (isDesktop && _informasiList.length > 1) ...[
                // Left Arrow
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () {
                        final prevIndex =
                            (_currentCarouselIndex - 1) % _informasiList.length;
                        _pageController.animateToPage(
                          prevIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ),

                // Right Arrow
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () {
                        final nextIndex =
                            (_currentCarouselIndex + 1) % _informasiList.length;
                        _pageController.animateToPage(
                          nextIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Carousel Indicators
        if (_informasiList.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _informasiList.length,
              (index) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentCarouselIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentCarouselIndex == index
                        ? const Color(0xFF4169E1)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCarouselItem(Map<String, dynamic> info, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image or placeholder
            if (info['gambar'] != null && info['gambar'].toString().isNotEmpty)
              Image.network(
                _getInformasiImageUrl(info['gambar']?.toString()),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
              )
            else
              _buildImagePlaceholder(),

            // Content overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info['judul'] ?? 'Tanpa Judul',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (info['deskripsi'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        info['deskripsi'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMenu = 'informasi';
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Lihat Detail',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
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

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4169E1).withOpacity(0.1),
            const Color(0xFF4169E1).withOpacity(0.05),
          ],
        ),
      ),
      child: Icon(Icons.image_outlined, size: 80, color: Colors.grey[300]),
    );
  }

  Widget _buildStatisticsCards(bool isDesktop) {
    // Get statistics from loaded data or use defaults
    final totalPeserta = _dashboardStats?['totalPeserta'] ?? 0;
    final totalEvent = _dashboardStats?['totalEvent'] ?? 0;
    final totalPertemuan = _dashboardStats?['totalPertemuan'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 3 : 1;
        final childAspectRatio = isDesktop ? 2.2 : 2.2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              title: 'Total Peserta',
              value: '$totalPeserta',
              icon: Icons.people_outline,
              color: const Color(0xFF4169E1),
            ),
            _buildStatCard(
              title: 'Total Event Periode ini',
              value: '$totalEvent',
              icon: Icons.event_note_outlined,
              color: const Color(0xFF10B981),
            ),
            _buildStatCard(
              title: 'Pertemuan',
              value: '$totalPertemuan',
              icon: Icons.calendar_today_outlined,
              color: const Color(0xFFF59E0B),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Create gradient from the base color
    final gradient = LinearGradient(colors: [color, color.withOpacity(0.8)]);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
