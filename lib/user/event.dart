import 'package:flutter/material.dart';
import 'package:unit_activity/config/routes.dart';

class UserEventPage extends StatefulWidget {
  const UserEventPage({Key? key}) : super(key: key);

  @override
  State<UserEventPage> createState() => _UserEventPageState();
}

class _UserEventPageState extends State<UserEventPage> {
  int _selectedIndex = 1;
  String _selectedMenu = 'Event';
  Map<String, dynamic>? _selectedEvent;

  final List<Map<String, dynamic>> _allEvents = [
    {
      'id': 1,
      'title': 'Sparing E-Sport',
      'image': 'assets/images/esport.png',
      'date': 'Kamis, 13 November 2025',
      'time': '16.00 - 18.00 WIB',
      'location': 'Ruang 6A - Universitas Katolik Darma Cendika',
      'description':
          'Sparing dengan UKM E-Sport Universitas Katolik Widya Mandala',
      'isRegistered': false,
    },
    {
      'id': 2,
      'title': 'Sparing Badminton',
      'image': 'assets/images/badminton.png',
      'date': 'Jumat, 14 November 2025',
      'time': '14.00 - 16.00 WIB',
      'location': 'GOR Universitas Katolik Darma Cendika',
      'description': 'Sparing Badminton antar UKM',
      'isRegistered': false,
    },
    {
      'id': 3,
      'title': 'KMJ Live In',
      'image': 'assets/images/kmj.png',
      'date': 'Sabtu, 15 November 2025',
      'time': '19.00 - 22.00 WIB',
      'location': 'Aula Utama UKDC',
      'description': 'Konser musik jazz live performance',
      'isRegistered': false,
    },
  ];

  List<Map<String, dynamic>> get _followedEvents {
    return _allEvents.where((event) => event['isRegistered'] == true).toList();
  }

  void _viewEventDetail(Map<String, dynamic> event) {
    setState(() {
      _selectedEvent = event;
    });
  }

  void _backToList() {
    setState(() {
      _selectedEvent = null;
    });
  }

  void _toggleRegistration() {
    setState(() {
      _selectedEvent!['isRegistered'] = !_selectedEvent!['isRegistered'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedEvent!['isRegistered']
              ? 'Berhasil mendaftar event!'
              : 'Batal mendaftar event',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
      appBar: AppBar(
        title: const Text('Unit Activity'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      drawer: Drawer(child: _buildSidebarVertical()),
      body: _selectedEvent == null
          ? _buildEventListViewMobile()
          : _buildEventDetailViewMobile(),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                SizedBox(width: 200, child: _buildSidebarVertical()),
                Expanded(
                  child: _selectedEvent == null
                      ? _buildEventListViewTablet()
                      : _buildEventDetailViewTablet(),
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
                _buildTopBar(),
                Expanded(
                  child: _selectedEvent == null
                      ? _buildEventListViewDesktop()
                      : _buildEventDetailViewDesktop(),
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

  // ==================== MENU ITEM (Desktop) ====================
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

  // ==================== MENU ITEM (Mobile) ====================
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
  Widget _buildTopBar() {
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

  // ==================== MOBILE EVENT LIST ====================
  Widget _buildEventListViewMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seluruh Event',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _allEvents.length,
            itemBuilder: (context, index) {
              return _buildEventCard(_allEvents[index]);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Event yang diikuti',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _followedEvents.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Text(
                    'Belum ada event yang diikuti',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _followedEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(_followedEvents[index]);
                  },
                ),
        ],
      ),
    );
  }

  // ==================== TABLET EVENT LIST ====================
  Widget _buildEventListViewTablet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seluruh Event',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: _allEvents.length,
            itemBuilder: (context, index) {
              return _buildEventCard(_allEvents[index]);
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Event yang diikuti',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _followedEvents.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: const Text(
                    'Belum ada event yang diikuti',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _followedEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(_followedEvents[index]);
                  },
                ),
        ],
      ),
    );
  }

  // ==================== DESKTOP EVENT LIST ====================
  Widget _buildEventListViewDesktop() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seluruh Event',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: () {}, child: const Text('Lihat Semua >')),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.2,
            ),
            itemCount: _allEvents.length,
            itemBuilder: (context, index) {
              return _buildEventCard(_allEvents[index]);
            },
          ),
          const SizedBox(height: 40),
          const Text(
            'Event yang diikuti',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _followedEvents.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: const Text(
                    'Belum ada event yang diikuti',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _followedEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(_followedEvents[index]);
                  },
                ),
        ],
      ),
    );
  }

  // ==================== EVENT CARD ====================
  Widget _buildEventCard(Map<String, dynamic> event) {
    return InkWell(
      onTap: () => _viewEventDetail(event),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          event['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lihat Detail',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MOBILE DETAIL VIEW ====================
  Widget _buildEventDetailViewMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _backToList,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Kembali'),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _selectedEvent!['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
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
                    const Text(
                      'Detail',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _toggleRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedEvent!['isRegistered']
                            ? Colors.grey[400]
                            : Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _selectedEvent!['isRegistered']
                            ? 'Terdaftar'
                            : 'Daftar',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedEvent!['description'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                _buildDetailInfo(
                  Icons.calendar_today_outlined,
                  _selectedEvent!['date'],
                ),
                const SizedBox(height: 12),
                _buildDetailInfo(Icons.access_time, _selectedEvent!['time']),
                const SizedBox(height: 12),
                _buildDetailInfo(
                  Icons.location_on_outlined,
                  _selectedEvent!['location'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TABLET DETAIL VIEW ====================
  Widget _buildEventDetailViewTablet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _backToList,
            icon: const Icon(Icons.arrow_back),
            label: Text(_selectedEvent!['title']),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 70, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          _selectedEvent!['title'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
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
                          const Text(
                            'Detail',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _toggleRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedEvent!['isRegistered']
                                  ? Colors.grey[400]
                                  : Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _selectedEvent!['isRegistered']
                                  ? 'Terdaftar'
                                  : 'Daftar',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedEvent!['description'],
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailInfo(
                        Icons.calendar_today_outlined,
                        _selectedEvent!['date'],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailInfo(
                        Icons.access_time,
                        _selectedEvent!['time'],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailInfo(
                        Icons.location_on_outlined,
                        _selectedEvent!['location'],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DESKTOP DETAIL VIEW ====================
  Widget _buildEventDetailViewDesktop() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _backToList,
            icon: const Icon(Icons.arrow_back),
            label: Text(_selectedEvent!['title']),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _selectedEvent!['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
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
                          const Text(
                            'Detail',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              onPressed: _toggleRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedEvent!['isRegistered']
                                    ? Colors.grey[400]
                                    : Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _selectedEvent!['isRegistered']
                                    ? 'Terdaftar'
                                    : 'Daftar',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _selectedEvent!['description'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 30),
                      _buildDetailInfo(
                        Icons.calendar_today_outlined,
                        _selectedEvent!['date'],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailInfo(
                        Icons.access_time,
                        _selectedEvent!['time'],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailInfo(
                        Icons.location_on_outlined,
                        _selectedEvent!['location'],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildDetailInfo(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[700]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
