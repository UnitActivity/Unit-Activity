import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/components/ukm_sidebar.dart';
import 'package:unit_activity/components/ukm_header.dart';
import 'package:unit_activity/ukm/peserta_ukm.dart';
import 'package:unit_activity/ukm/event_ukm.dart';
import 'package:unit_activity/ukm/pertemuan_ukm.dart';
import 'package:unit_activity/ukm/informasi_ukm.dart';
import 'package:unit_activity/ukm/notifikasi_ukm.dart';
import 'package:unit_activity/ukm/akun_ukm.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

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

  // Dashboard data
  String _ukmName = 'UKM Dashboard';
  String _periode = '2025.1';
  String? _ukmId;
  String? _periodeId;

  // Statistics data
  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _informasiList = [];
  bool _isLoadingStats = true;
  bool _isLoadingInformasi = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
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
      // Get current UKM ID from auth
      _ukmId = await _dashboardService.getCurrentUkmId();

      if (_ukmId == null) {
        setState(() {
          _errorMessage =
              'Tidak dapat mengidentifikasi UKM. Pastikan akun Anda terdaftar sebagai admin UKM.';
          _isLoadingStats = false;
          _isLoadingInformasi = false;
        });
        return;
      }

      // Get UKM details
      final ukmDetails = await _dashboardService.getUkmDetails(_ukmId!);
      if (ukmDetails['success'] == true) {
        setState(() {
          _ukmName = ukmDetails['data']['nama_ukm'] ?? 'UKM Dashboard';
        });
      }

      // Get current periode
      final periode = await _dashboardService.getCurrentPeriode(_ukmId!);
      if (periode != null) {
        setState(() {
          _periodeId = periode['id_periode'];
          _periode = '${periode['semester']} ${periode['tahun']}';
        });
      }

      // Load stats and informasi in parallel
      final results = await Future.wait([
        _dashboardService.getUkmStats(_ukmId!, periodeId: _periodeId),
        _dashboardService.getUkmInformasi(
          _ukmId!,
          limit: 5,
          periodeId: _periodeId,
        ),
      ]);

      if (mounted) {
        setState(() {
          // Update statistics
          if (results[0]['success'] == true) {
            _dashboardStats = results[0]['data'];
          }

          // Update informasi
          if (results[1]['success'] == true) {
            _informasiList = results[1]['data'] ?? [];
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

  int _currentCarouselIndex = 0;

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
              Navigator.pushReplacementNamed(context, '/login');
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
      drawer: isDesktop
          ? null
          : Drawer(
              child: UKMSidebar(
                selectedMenu: _selectedMenu,
                onMenuSelected: _handleMenuSelected,
                onLogout: _handleLogout,
              ),
            ),
      body: Row(
        children: [
          // Sidebar - Desktop only
          if (isDesktop)
            UKMSidebar(
              selectedMenu: _selectedMenu,
              onMenuSelected: _handleMenuSelected,
              onLogout: _handleLogout,
            ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                UKMHeader(
                  onMenuPressed: isDesktop
                      ? null
                      : () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                  onLogout: _handleLogout,
                  ukmName: _ukmName,
                  periode: _periode,
                ),

                // Content Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildContent(isDesktop),
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
      case 'akun':
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
                  Navigator.pushReplacementNamed(context, '/login');
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
        // Title
        Text(
          '📰 Informasi Terkini',
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Carousel Section
        _buildInformasiCarousel(isDesktop),
        const SizedBox(height: 24),

        // Section Title for Statistics
        Text(
          '📊 Statistik',
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Statistics Cards
        _buildStatisticsCards(isDesktop),
      ],
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

    // Ensure current index is valid
    if (_currentCarouselIndex >= _informasiList.length) {
      _currentCarouselIndex = 0;
    }

    final currentInfo = _informasiList[_currentCarouselIndex];

    return Column(
      children: [
        // Carousel
        Container(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Image or placeholder
                if (currentInfo['gambar'] != null &&
                    currentInfo['gambar'].toString().isNotEmpty)
                  Image.network(
                    currentInfo['gambar'],
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
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentInfo['judul'] ?? 'Tanpa Judul',
                          style: GoogleFonts.inter(
                            fontSize: isDesktop ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (currentInfo['deskripsi'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            currentInfo['deskripsi'],
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
                  setState(() {
                    _currentCarouselIndex = index;
                  });
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
