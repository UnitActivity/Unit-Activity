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

  // Dummy data untuk slider
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

  // Dummy data untuk jadwal UKM
  final List<Map<String, dynamic>> _ukmSchedule = [
    {
      'title': 'UKM Badminton',
      'date': 'Sabtu, 01 November 2025',
      'time': '10:00 - 13:00 WIB',
      'location': 'Lapangan MERS Court',
      'icon': Icons.sports_tennis,
      'color': Colors.orange,
    },
    {
      'title': 'UKM E-Sports',
      'date': 'Jumat, 07 November 2025',
      'time': '16:00 - 18:00 WIB',
      'location': 'Ruang A - Universitas Widya Karya Candle',
      'icon': Icons.sports_esports,
      'color': Colors.blue,
    },
    {
      'title': 'UKM E-Sports',
      'date': 'Jumat, 07 November 2025',
      'time': '16:00 - 18:00 WIB',
      'location': 'Kampus C - Universitas Widya Karya Candle',
      'icon': Icons.sports_esports,
      'color': Colors.purple,
    },
  ];

  // Data untuk chart
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),

                // Content Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informasi Terkini Section
                        _buildInformasiTerkini(),
                        const SizedBox(height: 32),

                        // Jadwal UKM Section
                        _buildJadwalUKM(),
                        const SizedBox(height: 32),

                        // Statistik Section
                        _buildStatistik(),
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

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
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

          // Menu Items
          _buildMenuItem(Icons.dashboard, 'Dashboard', AppRoutes.userDashboard),
          _buildMenuItem(Icons.event, 'Event', AppRoutes.userEvent),
          _buildMenuItem(Icons.groups, 'UKM', AppRoutes.userUKM),
          _buildMenuItem(Icons.history, 'Histori', AppRoutes.userHistory),

          const Spacer(),

          // Logout Button
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

  Widget _buildMenuItem(IconData icon, String title, String route) {
    final isSelected = _selectedMenu == title;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMenu = title;
        });
        Navigator.pushNamed(context, route);
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

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          const Text(
            'Adam',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInformasiTerkini() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Terkini',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Image Slider
        Container(
          height: 400,
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
                // Slider Images
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
                        ),
                        // Gradient Overlay
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
                        // Text Overlay
                        Positioned(
                          bottom: 40,
                          left: 24,
                          right: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sliderImages[index]['title']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _sliderImages[index]['subtitle']!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {},
                                    child: const Row(
                                      children: [
                                        Text(
                                          'Lihat Detail',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 16,
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

                // Dots Indicator
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _sliderImages.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildJadwalUKM() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ),
        const SizedBox(height: 16),

        // Horizontal Scrollable List
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _ukmSchedule.length,
            itemBuilder: (context, index) {
              final item = _ukmSchedule[index];
              return Container(
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
                            color: item['color'].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item['icon'],
                            color: item['color'],
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
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['date'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['location'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatistik() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Jumlah Pertemuan UKM Tahunan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tahun 2025',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        Container(
          height: 400,
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 16),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.blue[600]!, 'E-Sports'),
                  const SizedBox(width: 24),
                  _buildLegendItem(Colors.yellow[700]!, 'Badminton'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

    const leftPadding = 40.0;
    const rightPadding = 20.0;
    const topPadding = 20.0;
    const bottomPadding = 40.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Draw grid lines
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

    // Draw Y-axis labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (int i = 0; i <= 6; i++) {
      final value = 12 - (i * 2);
      final y = topPadding + (chartHeight / 6) * i;

      textPainter.text = TextSpan(
        text: value.toString(),
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Draw X-axis labels
    for (int i = 0; i < months.length; i++) {
      final x = leftPadding + (chartWidth / (months.length - 1)) * i;
      textPainter.text = TextSpan(
        text: months[i],
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 10),
      );
    }

    // Draw E-Sports line
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

    // Draw Badminton line
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
