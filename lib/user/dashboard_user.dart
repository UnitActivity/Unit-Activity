import 'package:flutter/material.dart';
import 'package:unit_activity/config/routes.dart';

class DashboardUser extends StatefulWidget {
  const DashboardUser({super.key});

  @override
  State<DashboardUser> createState() => _DashboardUserState();
}

class _DashboardUserState extends State<DashboardUser> {
  int _currentSlideIndex = 0;
  String _selectedMenu = 'Dashboard';

  final List<Map<String, String>> _sliderImages = [
    {
      'image':
          'https://via.placeholder.com/800x400/4CAF50/FFFFFF?text=Badminton+Playing+At+UWIKA+Cup',
      'title': 'Badminton Playing At UWIKA Cup',
      'subtitle': 'UKM Badminton',
    },
    {
      'image':
          'https://via.placeholder.com/800x400/2196F3/FFFFFF?text=E-Sports+Tournament+2025',
      'title': 'E-Sports Tournament 2025',
      'subtitle': 'UKM E-Sports',
    },
    {
      'image':
          'https://via.placeholder.com/800x400/FF9800/FFFFFF?text=Music+Festival+Event',
      'title': 'Music Festival Event',
      'subtitle': 'UKM Music',
    },
  ];

  final List<Map<String, dynamic>> _ukmSchedule = [
    {
      'title': 'UKM Badminton',
      'date': 'Sabtu, 01 November 2025',
      'time': '10:00 - 13:00 WIB',
      'location': 'Lapangan MERR Court',
      'icon': Icons.sports_tennis,
      'color': Colors.orange,
    },
    {
      'title': 'UKM E-Sports',
      'date': 'Jumat, 07 November 2025',
      'time': '16:00 - 18:00 WIB',
      'location': 'Ruang A - Universitas Katolik Darma Cendika',
      'icon': Icons.sports_esports,
      'color': Colors.blue,
    },
    {
      'title': 'UKM E-Sports',
      'date': 'Jumat, 07 November 2025',
      'time': '16:00 - 18:00 WIB',
      'location': 'Kampus C - Universitas Katolik Darma Cendika',
      'icon': Icons.sports_esports,
      'color': Colors.purple,
    },
  ];

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
      appBar: AppBar(
        title: const Text('Unit Activity'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      drawer: Drawer(child: _buildSidebarVertical()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
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
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildTopBar(isMobile: false),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Container(
                    color: Colors.white,
                    child: _buildSidebarVertical(),
                  ),
                ),
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
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isMobile: false),
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
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unit Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.blue[700],
              ),
            ),
          ),
          _buildMenuItem(Icons.dashboard, 'Dashboard', AppRoutes.userDashboard),
          _buildMenuItem(Icons.event, 'Event', AppRoutes.userEvent),
          _buildMenuItem(Icons.groups, 'UKM', AppRoutes.userUKM),
          _buildMenuItem(Icons.history, 'Histori', AppRoutes.userHistory),
          _buildMenuItem(Icons.person, 'Profile', AppRoutes.userProfile),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  AppRoutes.logout(context);
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarVertical() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Unit Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.blue[700],
              ),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItemCompact(
            Icons.dashboard,
            'Dashboard',
            AppRoutes.userDashboard,
          ),
          _buildMenuItemCompact(Icons.event, 'Event', AppRoutes.userEvent),
          _buildMenuItemCompact(Icons.groups, 'UKM', AppRoutes.userUKM),
          _buildMenuItemCompact(
            Icons.history,
            'Histori',
            AppRoutes.userHistory,
          ),
          _buildMenuItemCompact(Icons.person, 'Profile', AppRoutes.userProfile),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  AppRoutes.logout(context);
                },
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Log Out', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String route) {
    final isSelected = _selectedMenu == title;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMenu = title;
        });
        if (route == AppRoutes.userDashboard) {
          AppRoutes.navigateToUserDashboard(context);
        } else if (route == AppRoutes.userEvent) {
          AppRoutes.navigateToUserEvent(context);
        } else if (route == AppRoutes.userUKM) {
          AppRoutes.navigateToUserUKM(context);
        } else if (route == AppRoutes.userHistory) {
          AppRoutes.navigateToUserHistory(context);
        } else if (route == AppRoutes.userProfile) {
          AppRoutes.navigateToUserProfile(context);
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

  Widget _buildMenuItemCompact(IconData icon, String title, String route) {
    final isSelected = _selectedMenu == title;

    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? Colors.blue[700] : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.blue[700] : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      onTap: () {
        setState(() {
          _selectedMenu = title;
        });
        Navigator.pop(context); // Close drawer first
        Future.delayed(const Duration(milliseconds: 200), () {
          if (route == AppRoutes.userDashboard) {
            AppRoutes.navigateToUserDashboard(context);
          } else if (route == AppRoutes.userEvent) {
            AppRoutes.navigateToUserEvent(context);
          } else if (route == AppRoutes.userUKM) {
            AppRoutes.navigateToUserUKM(context);
          } else if (route == AppRoutes.userHistory) {
            AppRoutes.navigateToUserHistory(context);
          } else if (route == AppRoutes.userProfile) {
            AppRoutes.navigateToUserProfile(context);
          }
        });
      },
    );
  }

  // ==================== TOP BAR ====================
  Widget _buildTopBar({required bool isMobile}) {
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
              onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
              icon: const Icon(Icons.home_outlined),
            ),
          if (!isMobile) const SizedBox(width: 8),
          if (!isMobile)
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          if (!isMobile) const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          if (!isMobile) const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.userProfile),
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
                radius: isMobile ? 14 : 16,
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.person,
                  size: isMobile ? 16 : 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (!isMobile) const SizedBox(width: 8),
          if (!isMobile)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.userProfile),
              child: const Text(
                'Adam',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== INFORMASI TERKINI ====================
  Widget _buildInformasiTerkini({required bool isMobile}) {
    final sliderHeight = isMobile ? 220 : 300;

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
                PageView.builder(
                  itemCount: _sliderImages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSlideIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _sliderImages[index]['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
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
                        Positioned(
                          bottom: isMobile ? 12 : 24,
                          left: isMobile ? 12 : 24,
                          right: isMobile ? 12 : 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sliderImages[index]['title']!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 14 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!isMobile) const SizedBox(height: 4),
                              if (!isMobile)
                                Row(
                                  children: [
                                    Text(
                                      _sliderImages[index]['subtitle']!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                      ),
                                      child: const Row(
                                        children: [
                                          Text(
                                            'Lihat Detail',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _sliderImages.length,
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
              const Text(
                'Jadwal UKM',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [
                    Text('Lihat Semua'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          )
        else
          const Text(
            'Jadwal UKM',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 12),
        isMobile ? _buildJadwalMobileList() : _buildJadwalDesktopList(),
      ],
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
            padding: const EdgeInsets.all(12),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildJadwalInfo(Icons.calendar_today, item['date'], isMobile),
                const SizedBox(height: 4),
                _buildJadwalInfo(Icons.access_time, item['time'], isMobile),
                const SizedBox(height: 4),
                _buildJadwalInfo(Icons.location_on, item['location'], isMobile),
              ],
            ),
          )
        : Container(
            width: 320,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildJadwalInfo(Icons.calendar_today, item['date'], isMobile),
                const SizedBox(height: 8),
                _buildJadwalInfo(Icons.access_time, item['time'], isMobile),
                const SizedBox(height: 8),
                _buildJadwalInfo(Icons.location_on, item['location'], isMobile),
              ],
            ),
          );
  }

  Widget _buildJadwalInfo(IconData icon, String text, bool isMobile) {
    return Row(
      children: [
        Icon(icon, size: isMobile ? 12 : 14, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==================== STATISTIK ====================
  Widget _buildStatistik({required bool isMobile}) {
    final chartHeight = isMobile ? 280 : 360;

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
                    eSportsData: eSportsData,
                    badmintonData: badmintonData,
                    months: months,
                  ),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.blue[600]!, 'E-Sports', isMobile),
                  SizedBox(width: isMobile ? 16 : 24),
                  _buildLegendItem(Colors.yellow[700]!, 'Badminton', isMobile),
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
