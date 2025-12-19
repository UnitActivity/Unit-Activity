import 'package:flutter/material.dart';
import 'package:unit_activity/config/routes.dart';
import 'package:unit_activity/widgets/user_sidebar.dart';
import 'package:unit_activity/widgets/user_header.dart';

class UserUKMPage extends StatefulWidget {
  const UserUKMPage({super.key});

  @override
  State<UserUKMPage> createState() => _UserUKMPageState();
}

class _UserUKMPageState extends State<UserUKMPage> {
  Map<String, dynamic>? _selectedUKM;
  String _selectedFilter = 'Semua';

  final List<Map<String, dynamic>> _allUKMs = [
    {
      'id': 1,
      'name': 'UKM Badminton',
      'image':
          'https://via.placeholder.com/300x300/FF9800/FFFFFF?text=UKM+Badminton',
      'logo': '🏸',
      'jadwal': 'Setiap Sabtu',
      'time': '10:00 - 13:00 WIB',
      'location': 'Merr Badminton Court',
      'kontak': [
        {'icon': Icons.phone, 'text': '081-234-789-101'},
        {'icon': Icons.person, 'text': '@ukmBadminton'},
      ],
      'isRegistered': true,
      'status': 'Sudah Terdaftar',
    },
    {
      'id': 2,
      'name': 'UKM Basketball',
      'image':
          'https://via.placeholder.com/300x300/2196F3/FFFFFF?text=UKM+Basketball',
      'logo': '🏀',
      'jadwal': 'Setiap Minggu',
      'time': '14:00 - 16:00 WIB',
      'location': 'Lapangan Basket UKDC',
      'kontak': [
        {'icon': Icons.phone, 'text': '081-234-789-102'},
        {'icon': Icons.person, 'text': '@ukmBasketball'},
      ],
      'isRegistered': false,
      'status': 'Belum Terdaftar',
    },
    {
      'id': 3,
      'name': 'UKM Dance',
      'image':
          'https://via.placeholder.com/300x300/9C27B0/FFFFFF?text=UKM+Dance',
      'logo': '💃',
      'jadwal': 'Setiap Rabu',
      'time': '16:00 - 18:00 WIB',
      'location': 'Studio Dance UKDC',
      'kontak': [
        {'icon': Icons.phone, 'text': '081-234-789-103'},
        {'icon': Icons.person, 'text': '@ukmDance'},
      ],
      'isRegistered': false,
      'status': 'Belum Terdaftar',
    },
    {
      'id': 4,
      'name': 'UKM E-Sports',
      'image':
          'https://via.placeholder.com/300x300/F44336/FFFFFF?text=UKM+E-Sports',
      'logo': '🎮',
      'jadwal': 'Setiap Jumat',
      'time': '16:00 - 18:00 WIB',
      'location': 'Ruang Gaming UKDC',
      'kontak': [
        {'icon': Icons.phone, 'text': '081-234-789-104'},
        {'icon': Icons.person, 'text': '@ukmEsports'},
      ],
      'isRegistered': false,
      'status': 'Belum Terdaftar',
    },
    {
      'id': 5,
      'name': 'UKM Music',
      'image':
          'https://via.placeholder.com/300x300/FF5722/FFFFFF?text=UKM+Music',
      'logo': '🎵',
      'jadwal': 'Setiap Kamis',
      'time': '15:00 - 17:00 WIB',
      'location': 'Ruang Musik UKDC',
      'kontak': [
        {'icon': Icons.phone, 'text': '081-234-789-105'},
        {'icon': Icons.person, 'text': '@ukmMusic'},
      ],
      'isRegistered': false,
      'status': 'Belum Terdaftar',
    },
    {
      'id': 6,
      'name': 'UKM Jurnalistik',
      'image':
          'https://via.placeholder.com/300x300/4CAF50/FFFFFF?text=UKM+Jurnalistik',
      'logo': '📰',
      'jadwal': 'Setiap Selasa',
      'time': '14:00 - 16:00 WIB',
      'location': 'Ruang Media UKDC',
      'kontak': [
        {'icon': Icons.phone, 'text': '081-234-789-106'},
        {'icon': Icons.person, 'text': '@ukmJurnalistik'},
      ],
      'isRegistered': false,
      'status': 'Belum Terdaftar',
    },
  ];

  List<Map<String, dynamic>> get _registeredUKMs {
    return _allUKMs.where((ukm) => ukm['isRegistered'] == true).toList();
  }

  void _viewUKMDetail(Map<String, dynamic> ukm) {
    setState(() {
      _selectedUKM = ukm;
    });
  }

  void _backToList() {
    setState(() {
      _selectedUKM = null;
    });
  }

  void _showRegisterDialog(Map<String, dynamic> ukm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bergabung dengan UKM'),
        content: Text('Apakah ingin mendaftar event ${ukm['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedUKM!['isRegistered'] = true;
                _selectedUKM!['status'] = 'Sudah Terdaftar';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Berhasil mendaftar ${ukm['name']}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
            child: const Text('Ya'),
          ),
        ],
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
            child: _selectedUKM == null
                ? _buildUKMListMobile()
                : _buildUKMDetailMobile(),
          ),
        ],
      ),
      drawer: Drawer(
        child: UserSidebar(
          selectedMenu: 'ukm',
          onMenuSelected: (menu) {
            Navigator.pop(context);
            if (menu == 'dashboard') {
              AppRoutes.navigateToUserDashboard(context);
            } else if (menu == 'event') {
              AppRoutes.navigateToUserEvent(context);
            } else if (menu == 'histori') {
              AppRoutes.navigateToUserHistory(context);
            } else if (menu == 'profile') {
              AppRoutes.navigateToUserProfile(context);
            }
          },
          onLogout: () => AppRoutes.logout(context),
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
          UserHeader(
            userName: 'Adam',
            onLogout: () => AppRoutes.logout(context),
          ),
          Expanded(
            child: Row(
              children: [
                UserSidebar(
                  selectedMenu: 'ukm',
                  onMenuSelected: (menu) {
                    if (menu == 'dashboard') {
                      AppRoutes.navigateToUserDashboard(context);
                    } else if (menu == 'event') {
                      AppRoutes.navigateToUserEvent(context);
                    } else if (menu == 'histori') {
                      AppRoutes.navigateToUserHistory(context);
                    } else if (menu == 'profile') {
                      AppRoutes.navigateToUserProfile(context);
                    }
                  },
                  onLogout: () => AppRoutes.logout(context),
                ),
                Expanded(
                  child: _selectedUKM == null
                      ? _buildUKMListTablet()
                      : _buildUKMDetailTablet(),
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
          UserSidebar(
            selectedMenu: 'ukm',
            onMenuSelected: (menu) {
              if (menu == 'dashboard') {
                AppRoutes.navigateToUserDashboard(context);
              } else if (menu == 'event') {
                AppRoutes.navigateToUserEvent(context);
              } else if (menu == 'histori') {
                AppRoutes.navigateToUserHistory(context);
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
                  child: _selectedUKM == null
                      ? _buildUKMListDesktop()
                      : _buildUKMDetailDesktop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== UKM LIST VIEW - MOBILE ====================
  Widget _buildUKMListMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan UKM',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFilterChipsMobile(),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _allUKMs.length,
            itemBuilder: (context, index) {
              return _buildUKMCard(_allUKMs[index], isMobile: true);
            },
          ),
        ],
      ),
    );
  }

  // ==================== UKM LIST VIEW - TABLET ====================
  Widget _buildUKMListTablet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan UKM',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFilterChipsTablet(),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: _allUKMs.length,
            itemBuilder: (context, index) {
              return _buildUKMCard(_allUKMs[index], isMobile: false);
            },
          ),
        ],
      ),
    );
  }

  // ==================== UKM LIST VIEW - DESKTOP ====================
  Widget _buildUKMListDesktop() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan UKM',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFilterChipsDesktop(),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.9,
            ),
            itemCount: _allUKMs.length,
            itemBuilder: (context, index) {
              return _buildUKMCard(_allUKMs[index], isMobile: false);
            },
          ),
        ],
      ),
    );
  }

  // ==================== UKM CARD ====================
  Widget _buildUKMCard(Map<String, dynamic> ukm, {required bool isMobile}) {
    return InkWell(
      onTap: () => _viewUKMDetail(ukm),
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
                      Text(
                        ukm['logo'],
                        style: TextStyle(fontSize: isMobile ? 36 : 50),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ukm['name'],
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 16,
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
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ukm['isRegistered'] ? 'Terdaftar' : 'Lihat Detail',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 10 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: isMobile ? 12 : 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== FILTER CHIPS ====================
  Widget _buildFilterChipsMobile() {
    final filters = ['Semua', 'Populer', 'Terbaru'];
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[200],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChipsTablet() {
    final filters = ['Semua', 'Populer', 'Aktif', 'Terbaru'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[200],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChipsDesktop() {
    final filters = ['Semua', 'Populer', 'Aktif', 'Bergerak', 'Terbaru'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[200],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== UKM DETAIL VIEW - MOBILE ====================
  Widget _buildUKMDetailMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _backToList,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Kembali', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedUKM!['logo'],
                    style: const TextStyle(fontSize: 50),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _selectedUKM!['name'],
                      style: const TextStyle(
                        fontSize: 14,
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
          const SizedBox(height: 12),
          _buildDetailCard(isMobile: true),
        ],
      ),
    );
  }

  // ==================== UKM DETAIL VIEW - TABLET ====================
  Widget _buildUKMDetailTablet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _backToList,
            icon: const Icon(Icons.arrow_back),
            label: Text(
              _selectedUKM!['name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedUKM!['logo'],
                          style: const TextStyle(fontSize: 45),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _selectedUKM!['name'],
                            style: const TextStyle(
                              fontSize: 14,
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
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildDetailCard(isMobile: false)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== UKM DETAIL VIEW - DESKTOP ====================
  Widget _buildUKMDetailDesktop() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _backToList,
            icon: const Icon(Icons.arrow_back),
            label: Text(_selectedUKM!['name']),
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedUKM!['logo'],
                        style: const TextStyle(fontSize: 80),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedUKM!['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              Expanded(child: _buildDetailCard(isMobile: false)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DETAIL CARD ====================
  Widget _buildDetailCard({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (!_selectedUKM!['isRegistered'])
                SizedBox(
                  width: isMobile ? 80 : 120,
                  child: ElevatedButton(
                    onPressed: () => _showRegisterDialog(_selectedUKM!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 6 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Daftar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 11 : 14,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green[700]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Terdaftar',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailSection(
            title: 'Jadwal',
            items: [
              {'icon': Icons.calendar_today, 'text': _selectedUKM!['jadwal']},
              {'icon': Icons.access_time, 'text': _selectedUKM!['time']},
            ],
            isMobile: isMobile,
          ),
          const SizedBox(height: 12),
          _buildDetailSection(
            title: 'Lokasi',
            items: [
              {'icon': Icons.location_on, 'text': _selectedUKM!['location']},
            ],
            isMobile: isMobile,
          ),
          const SizedBox(height: 12),
          _buildDetailSection(
            title: 'Kontak',
            items: _selectedUKM!['kontak'] as List,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List items,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: isMobile ? 14 : 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item['text'] as String,
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
