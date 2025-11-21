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

    final result = await _dashboardService.getDashboardStats();

    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _dashboardStats = result['data'];
          _errorMessage = null;
        } else {
          _dashboardStats = null;
          _errorMessage = result['error'] ?? 'Terjadi kesalahan';
        }
        _isLoadingStats = false;
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
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 100, // Space for floating header
                      bottom: 24,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 1200;
        final isMediumScreen = constraints.maxWidth > 768;
        final isMobile = constraints.maxWidth < 768;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isLargeScreen ? 3 : (isMediumScreen ? 2 : 1),
              crossAxisSpacing: isMobile ? 12 : 16,
              mainAxisSpacing: isMobile ? 12 : 16,
              childAspectRatio: isLargeScreen
                  ? 2.5
                  : (isMediumScreen ? 2.2 : 3.2),
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
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 24 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 24 : 28),
          ),
        ],
      ),
    );
  }
}
