import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/components/admin_sidebar.dart';
import 'package:unit_activity/components/admin_header.dart';
import 'package:unit_activity/admin/pengguna.dart';
import 'package:unit_activity/admin/ukm.dart';
import 'package:unit_activity/admin/event.dart';
import 'package:unit_activity/admin/periode.dart';
import 'package:unit_activity/admin/informasi.dart';
import 'package:unit_activity/services/dashboard_service.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  String _selectedMenu = 'dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DashboardService _dashboardService = DashboardService();

  // Dashboard stats
  Map<String, dynamic>? _dashboardStats;
  bool _isLoadingStats = true;
  String? _errorMessage;

  // Additional dashboard data
  Map<String, dynamic>? _eventsByMonth;
  List<dynamic>? _ukmRanking;
  Map<String, dynamic>? _followerTrend;
  List<dynamic>? _recentActivities;
  List<dynamic>? _upcomingEvents;
  List<dynamic>? _alerts;

  // Filter states
  String _eventTrendPeriod = 'hari_ini';
  String _followerTrendPeriod = 'hari_ini';

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoadingStats = true;
      _errorMessage = null;
    });

    // Load all dashboard data in parallel
    final results = await Future.wait([
      _dashboardService.getDashboardStats(),
      _dashboardService.getEventsByMonth(_eventTrendPeriod),
      _dashboardService.getUkmRanking(),
      _dashboardService.getFollowerTrend(_followerTrendPeriod),
      _dashboardService.getRecentActivities(),
      _dashboardService.getUpcomingEvents(),
      _dashboardService.getAlerts(),
    ]);

    if (mounted) {
      setState(() {
        // Main stats
        if (results[0]['success'] == true) {
          _dashboardStats = results[0]['data'];
        }

        // Events by month
        if (results[1]['success'] == true) {
          _eventsByMonth = results[1]['data'];
        }

        // UKM ranking
        if (results[2]['success'] == true) {
          _ukmRanking = results[2]['data'];
        }

        // Follower trend
        if (results[3]['success'] == true) {
          _followerTrend = results[3]['data'];
        }

        // Recent activities
        if (results[4]['success'] == true) {
          _recentActivities = results[4]['data'];
        }

        // Upcoming events
        if (results[5]['success'] == true) {
          _upcomingEvents = results[5]['data'];
        }

        // Alerts
        if (results[6]['success'] == true) {
          _alerts = results[6]['data'];
        }

        _isLoadingStats = false;
      });
    }
  }

  Future<void> _reloadEventTrend() async {
    final result = await _dashboardService.getEventsByMonth(_eventTrendPeriod);
    if (mounted && result['success'] == true) {
      setState(() {
        _eventsByMonth = result['data'];
      });
    }
  }

  Future<void> _reloadFollowerTrend() async {
    final result = await _dashboardService.getFollowerTrend(
      _followerTrendPeriod,
    );
    if (mounted && result['success'] == true) {
      setState(() {
        _followerTrend = result['data'];
      });
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
  }

  void _handleLogout() {
    // TODO: Implement logout logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login page
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
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
              child: AdminSidebar(
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
            AdminSidebar(
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
                    child: _buildContent(),
                  ),
                ),

                // Floating Header
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AdminHeader(
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    onLogout: _handleLogout,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedMenu) {
      case 'dashboard':
        return _buildDashboardContent();
      case 'pengguna':
        return const PenggunaPage();
      case 'ukm':
        return const UkmPage();
      case 'event':
        return const EventPage();
      case 'periode':
        return const PeriodePage();
      case 'informasi':
        return const InformasiPage();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dashboardStats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data dashboard',
              style: GoogleFonts.inter(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_errorMessage != null) const SizedBox(height: 8),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboardStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
              ),
            ),
          ],
        ),
      );
    }

    final totalUkm = _dashboardStats!['totalUkm'] ?? 0;
    final totalUsers = _dashboardStats!['totalUsers'] ?? 0;
    final totalEvent = _dashboardStats!['totalEvent'] ?? 0;
    final activeEvents = _dashboardStats!['activeEvents'] ?? 0;
    final openRegistrations = _dashboardStats!['openRegistrations'] ?? 0;
    final totalFollowers = _dashboardStats!['totalFollowers'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 1200;
        final isMediumScreen = constraints.maxWidth > 768;
        final isMobile = constraints.maxWidth < 768;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // All Stats Cards in ONE Grid (6 cards)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isLargeScreen ? 3 : (isMediumScreen ? 2 : 1),
              crossAxisSpacing: isMobile ? 8 : 12,
              mainAxisSpacing: isMobile ? 8 : 12,
              childAspectRatio: isLargeScreen
                  ? 3
                  : (isMediumScreen ? 2.2 : 2.9),
              children: [
                _buildStatCard(
                  title: 'Total UKM',
                  value: '$totalUkm',
                  icon: Icons.groups,
                  color: const Color(0xFF4169E1),
                  isMobile: isMobile,
                ),
                _buildStatCard(
                  title: 'Total Mahasiswa',
                  value: '$totalUsers',
                  icon: Icons.people,
                  color: const Color(0xFF10B981),
                  isMobile: isMobile,
                ),
                _buildStatCard(
                  title: 'Total Event',
                  value: '$totalEvent',
                  icon: Icons.event,
                  color: const Color(0xFFF59E0B),
                  isMobile: isMobile,
                ),
                _buildStatCard(
                  title: 'Event Aktif',
                  value: '$activeEvents',
                  icon: Icons.check_circle,
                  color: const Color(0xFF8B5CF6),
                  isMobile: isMobile,
                ),
                _buildStatCard(
                  title: 'Registrasi Terbuka',
                  value: '$openRegistrations',
                  icon: Icons.how_to_reg,
                  color: const Color(0xFFEC4899),
                  isMobile: isMobile,
                ),
                _buildStatCard(
                  title: 'Total Anggota UKM',
                  value: '$totalFollowers',
                  icon: Icons.person_add,
                  color: const Color(0xFF06B6D4),
                  isMobile: isMobile,
                ),
              ],
            ),

            SizedBox(height: isMobile ? 12 : 20),

            // Alerts Section
            if (_alerts != null && _alerts!.isNotEmpty) ...[
              _buildSectionTitle('⚠️ Alerts & Warnings', isMobile),
              SizedBox(height: isMobile ? 6 : 8),
              ..._alerts!.map((alert) => _buildAlertCard(alert, isMobile)),
              SizedBox(height: isMobile ? 10 : 14),
            ],

            // Charts Row
            if (isLargeScreen)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitleWithDropdown(
                          '📊 Event Trend',
                          _eventTrendPeriod,
                          (newPeriod) {
                            setState(() {
                              _eventTrendPeriod = newPeriod!;
                            });
                            _reloadEventTrend();
                          },
                          isMobile,
                        ),
                        const SizedBox(height: 6),
                        _buildEventChart(isMobile),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '🏆 Top UKM',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 17),
                        _buildUkmRanking(isMobile),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitleWithDropdown(
                    '📊 Event Trend',
                    _eventTrendPeriod,
                    (newPeriod) {
                      setState(() {
                        _eventTrendPeriod = newPeriod!;
                      });
                      _reloadEventTrend();
                    },
                    isMobile,
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  _buildEventChart(isMobile),
                  SizedBox(height: isMobile ? 10 : 14),
                  _buildSectionTitle('🏆 Top UKM', isMobile),
                  SizedBox(height: isMobile ? 6 : 8),
                  _buildUkmRanking(isMobile),
                ],
              ),

            SizedBox(height: isMobile ? 10 : 14),

            // Follower Trend Chart
            _buildSectionTitleWithDropdown(
              '📈 Pertumbuhan Anggota',
              _followerTrendPeriod,
              (newPeriod) {
                setState(() {
                  _followerTrendPeriod = newPeriod!;
                });
                _reloadFollowerTrend();
              },
              isMobile,
            ),
            SizedBox(height: isMobile ? 6 : 8),
            _buildFollowerTrendChart(isMobile),

            SizedBox(height: isMobile ? 10 : 14),

            // Recent Activities and Upcoming Events
            if (isLargeScreen)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('🕐 Recent Activities', isMobile),
                        const SizedBox(height: 6),
                        _buildRecentActivities(isMobile),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('📅 Upcoming Events', isMobile),
                        const SizedBox(height: 6),
                        _buildUpcomingEvents(isMobile),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('🕐 Recent Activities', isMobile),
                  SizedBox(height: isMobile ? 6 : 8),
                  _buildRecentActivities(isMobile),
                  SizedBox(height: isMobile ? 10 : 14),
                  _buildSectionTitle('📅 Upcoming Events', isMobile),
                  SizedBox(height: isMobile ? 6 : 8),
                  _buildUpcomingEvents(isMobile),
                ],
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
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isMobile ? 20 : 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isMobile) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: isMobile ? 14 : 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSectionTitleWithDropdown(
    String title,
    String selectedPeriod,
    ValueChanged<String?> onChanged,
    bool isMobile,
  ) {
    final periodOptions = {
      'hari_ini': 'Hari Ini',
      'minggu_ini': 'Minggu Ini',
      'bulan_ini': 'Bulan Ini',
      '3_bulan': '3 Bulan',
      '6_bulan': '6 Bulan',
      'tahun_ini': 'Tahun Ini',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<String>(
            value: selectedPeriod,
            underline: const SizedBox(),
            isDense: true,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 11 : 12,
              color: Colors.black87,
            ),
            items: periodOptions.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, bool isMobile) {
    Color alertColor;
    Color alertTextColor;
    IconData alertIcon;

    switch (alert['type']) {
      case 'danger':
        alertColor = Colors.red;
        alertTextColor = Colors.red[700]!;
        alertIcon = Icons.error;
        break;
      case 'warning':
        alertColor = Colors.orange;
        alertTextColor = Colors.orange[700]!;
        alertIcon = Icons.warning;
        break;
      case 'info':
        alertColor = Colors.blue;
        alertTextColor = Colors.blue[700]!;
        alertIcon = Icons.info;
        break;
      default:
        alertColor = Colors.grey;
        alertTextColor = Colors.grey[700]!;
        alertIcon = Icons.notifications;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 10),
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(alertIcon, color: alertColor, size: isMobile ? 20 : 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: alertTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 12 : 13,
                    color: alertTextColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (alert['count'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: alertColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${alert['count']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventChart(bool isMobile) {
    if (_eventsByMonth == null || _eventsByMonth!.isEmpty) {
      return _buildEmptyCard('Tidak ada data event', isMobile);
    }

    final sortedEntries = _eventsByMonth!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
      child: Column(
        children: sortedEntries.map((entry) {
          final month = entry.key;
          final count = entry.value as int;
          final maxCount = sortedEntries
              .map((e) => e.value as int)
              .reduce((a, b) => a > b ? a : b);
          final percentage = maxCount > 0 ? count / maxCount : 0.0;

          return Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 8 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      month,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '$count events',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4169E1),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUkmRanking(bool isMobile) {
    if (_ukmRanking == null || _ukmRanking!.isEmpty) {
      return _buildEmptyCard('Tidak ada data UKM', isMobile);
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
      child: Column(
        children: _ukmRanking!.asMap().entries.map((entry) {
          final index = entry.key;
          final ukm = entry.value;
          final rank = index + 1;

          Color rankColor;
          if (rank == 1) {
            rankColor = const Color(0xFFFFD700); // Gold
          } else if (rank == 2)
            rankColor = const Color(0xFFC0C0C0); // Silver
          else if (rank == 3)
            rankColor = const Color(0xFFCD7F32); // Bronze
          else
            rankColor = Colors.grey;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ukm['name'] ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${ukm['members']} anggota',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFollowerTrendChart(bool isMobile) {
    if (_followerTrend == null || _followerTrend!.isEmpty) {
      return _buildEmptyCard('Tidak ada data pertumbuhan anggota', isMobile);
    }

    final sortedEntries = _followerTrend!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
      child: Column(
        children: sortedEntries.map((entry) {
          final month = entry.key;
          final count = entry.value as int;
          final maxCount = sortedEntries
              .map((e) => e.value as int)
              .reduce((a, b) => a > b ? a : b);
          final percentage = maxCount > 0 ? count / maxCount : 0.0;

          return Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 8 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      month,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '+$count anggota',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivities(bool isMobile) {
    if (_recentActivities == null || _recentActivities!.isEmpty) {
      return _buildEmptyCard('Tidak ada aktivitas terbaru', isMobile);
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
      child: Column(
        children: _recentActivities!.map((activity) {
          final createdAt = activity['create_at'] != null
              ? DateTime.parse(activity['create_at'])
              : null;
          final timeAgo = createdAt != null
              ? _getTimeAgo(createdAt)
              : 'Unknown';

          return Container(
            margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event_note,
                    color: Color(0xFF4169E1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['nama_event'] ?? 'Unknown Event',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity['ukm']?['nama_ukm'] ?? 'Unknown UKM',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 10 : 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpcomingEvents(bool isMobile) {
    if (_upcomingEvents == null || _upcomingEvents!.isEmpty) {
      return _buildEmptyCard('Tidak ada event mendatang', isMobile);
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
      child: Column(
        children: _upcomingEvents!.map((event) {
          final tanggalMulai = event['tanggal_mulai'] != null
              ? DateTime.parse(event['tanggal_mulai'])
              : null;
          final dateStr = tanggalMulai != null
              ? '${tanggalMulai.day}/${tanggalMulai.month}/${tanggalMulai.year}'
              : 'TBD';

          return Container(
            margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['nama_event'] ?? 'Unknown Event',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event['ukm']?['nama_ukm'] ?? 'Unknown UKM',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (event['lokasi'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          event['lokasi'],
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 10 : 11,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyCard(String message, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: isMobile ? 40 : 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}h yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m yang lalu';
    } else {
      return 'Baru saja';
    }
  }
}
