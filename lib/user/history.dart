import 'package:flutter/material.dart';
import 'package:unit_activity/config/routes.dart';
import 'package:unit_activity/widgets/user_sidebar.dart';
import 'package:unit_activity/widgets/user_header.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Map<String, List<Map<String, dynamic>>> _historyData = {
    '2025.1': [
      {
        'id': '1',
        'title': 'UKM Live In',
        'icon': Icons.local_fire_department,
        'illustration': 'person_camping',
      },
    ],
    '2024.3': [
      {
        'id': '2',
        'title': 'UKM Badminton Sparing',
        'icon': Icons.sports_tennis,
        'illustration': 'person_badminton',
      },
      {
        'id': '3',
        'title': 'UKM E-Sport 2024',
        'icon': Icons.sports_esports,
        'illustration': 'person_gaming',
      },
    ],
  };

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
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          UserHeader(
            userName: 'Adam',
            onMenuPressed: () {
              Scaffold.of(context).openDrawer();
            },
            onLogout: () => AppRoutes.logout(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Histori Aktivitas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._buildHistoryList(),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: UserSidebar(
          selectedMenu: 'histori',
          onMenuSelected: (menu) {
            Navigator.pop(context);
            if (menu == 'dashboard') {
              AppRoutes.navigateToUserDashboard(context);
            } else if (menu == 'event') {
              AppRoutes.navigateToUserEvent(context);
            } else if (menu == 'ukm') {
              AppRoutes.navigateToUserUKM(context);
            } else if (menu == 'profile') {
              AppRoutes.navigateToUserProfile(context);
            }
          },
          onLogout: () => AppRoutes.logout(context),
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          UserSidebar(
            selectedMenu: 'histori',
            onMenuSelected: (menu) {
              if (menu == 'dashboard') {
                AppRoutes.navigateToUserDashboard(context);
              } else if (menu == 'event') {
                AppRoutes.navigateToUserEvent(context);
              } else if (menu == 'ukm') {
                AppRoutes.navigateToUserUKM(context);
              } else if (menu == 'profile') {
                AppRoutes.navigateToUserProfile(context);
              }
            },
            onLogout: () => AppRoutes.logout(context),
          ),
          Expanded(
            child: Column(
              children: [
                UserHeader(
                  userName: 'Adam',
                  onLogout: () => AppRoutes.logout(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Histori Aktivitas',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ..._buildHistoryList(),
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

  List<Widget> _buildHistoryList() {
    return _historyData.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              entry.key,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
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
            builder: (context) => HistoryDetailPage(activity: activity),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isMobile ? 12 : 24),
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
        child: Row(
          children: [
            Container(
              width: isMobile ? 60 : 80,
              height: isMobile ? 60 : 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildIllustration(activity['illustration']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                activity['title'],
                style: TextStyle(
                  fontSize: isMobile ? 14 : 24,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: isMobile ? 14 : 20,
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
class HistoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> activity;

  const HistoryDetailPage({super.key, required this.activity});

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
      appBar: AppBar(
        title: const Text('Unit Activity'),
        backgroundColor: Colors.blue[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: _buildDetailContent(context, isMobile: true),
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
                    child: _buildDetailContent(context, isMobile: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DETAIL CONTENT ====================
  Widget _buildDetailContent(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity['title'] == 'UKM Live In'
              ? 'KMK Live In'
              : activity['title'],
          style: TextStyle(
            fontSize: isMobile ? 20 : 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: isMobile ? 200 : 300,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  activity['title'] == 'UKM Live In'
                      ? 'KMK Live In'
                      : activity['title'],
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 32,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: isMobile ? 100 : 150,
                  height: isMobile ? 100 : 150,
                  child: CustomPaint(
                    painter: IllustrationPainter(
                      type: activity['illustration'],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 8 : 12,
                      ),
                    ),
                    child: Text(
                      'Terdaftar',
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                activity['title'] == 'UKM Live In'
                    ? 'KMK Live In'
                    : activity['title'],
                style: TextStyle(
                  fontSize: isMobile ? 14 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.calendar_today,
                '1-2 November 2025',
                isMobile,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.location_on, 'Puhsarang', isMobile),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.monetization_on, 'Rp 200.000', isMobile),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.book),
                  label: const Text('Logbook'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                    side: BorderSide(color: Colors.grey[300]!),
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
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar(BuildContext context) {
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
          _buildMenuItemDetail(
            Icons.dashboard,
            'Dashboard',
            AppRoutes.userDashboard,
            context,
          ),
          _buildMenuItemDetail(
            Icons.event,
            'Event',
            AppRoutes.userEvent,
            context,
          ),
          _buildMenuItemDetail(Icons.groups, 'UKM', AppRoutes.userUKM, context),
          _buildMenuItemDetail(
            Icons.history,
            'Histori',
            AppRoutes.userHistory,
            context,
          ),
          _buildMenuItemDetail(
            Icons.person,
            'Profile',
            AppRoutes.userProfile,
            context,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => AppRoutes.logout(context),
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

  Widget _buildMenuItemDetail(
    IconData icon,
    String title,
    String route,
    BuildContext context,
  ) {
    final isSelected = title == 'Histori';
    return InkWell(
      onTap: () {
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
