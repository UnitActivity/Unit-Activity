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

class DashboardUKMPage extends StatefulWidget {
  const DashboardUKMPage({super.key});

  @override
  State<DashboardUKMPage> createState() => _DashboardUKMPageState();
}

class _DashboardUKMPageState extends State<DashboardUKMPage> {
  String _selectedMenu = 'dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sample data - replace with actual data from API/database
  final String _ukmName = 'UKM Dashboard';
  final String _periode = '2025.1';

  @override
  void initState() {
    super.initState();
    // Login check removed - direct access allowed
  }

  final int _totalPeserta = 40;
  final int _totalEventPeriode = 1;
  final int _totalPertemuan = 6;

  // Sample information data
  final List<Map<String, dynamic>> _informasiList = [
    {
      'title': 'Badminton Playing At UWIKA Cup',
      'category': 'UKM Badminton',
      'image': '', // Placeholder for image
    },
    {
      'title': 'Basketball Championship 2025',
      'category': 'UKM Basket',
      'image': '',
    },
    {'title': 'Futsal Tournament', 'category': 'UKM Futsal', 'image': ''},
  ];

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
      backgroundColor: const Color(0xFFF5F7FA),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Informasi Terkini',
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),

        // Carousel Section
        _buildInformasiCarousel(isDesktop),
        const SizedBox(height: 32),

        // Statistics Cards
        _buildStatisticsCards(isDesktop),
      ],
    );
  }

  Widget _buildInformasiCarousel(bool isDesktop) {
    return Column(
      children: [
        // Carousel
        Container(
          height: isDesktop ? 300 : 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Image placeholder
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4169E1).withValues(alpha: 0.1),
                        const Color(0xFF4169E1).withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                ),

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
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _informasiList[_currentCarouselIndex]['title'],
                          style: GoogleFonts.inter(
                            fontSize: isDesktop ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _informasiList[_currentCarouselIndex]['category'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
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

  Widget _buildStatisticsCards(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 3 : 1;
        final childAspectRatio = isDesktop ? 2.5 : 3.5;

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
              value: '$_totalPeserta',
              icon: Icons.people_outline,
              color: const Color(0xFF4169E1),
            ),
            _buildStatCard(
              title: 'Total Event Periode ini',
              value: '$_totalEventPeriode',
              icon: Icons.event_note_outlined,
              color: const Color(0xFF10B981),
            ),
            _buildStatCard(
              title: 'Pertemuan',
              value: '$_totalPertemuan',
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),

          // Value and Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
