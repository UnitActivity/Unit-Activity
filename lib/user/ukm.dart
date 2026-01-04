import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/config/routes.dart';

class UserUKMPage extends StatefulWidget {
  const UserUKMPage({Key? key}) : super(key: key);

  @override
  State<UserUKMPage> createState() => _UserUKMPageState();
}

class _UserUKMPageState extends State<UserUKMPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedMenu = 'UKM';
  Map<String, dynamic>? _selectedUKM;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  bool _showQRScanner = false;
  bool _isLoading = true;

  List<Map<String, dynamic>> _allUKMs = [];
  Map<String, int> _userUKMAttendance = {}; // Store attendance for each UKM

  @override
  void initState() {
    super.initState();
    _loadUKMs();
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(_LifecycleObserver(_onResume));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_LifecycleObserver(_onResume));
    super.dispose();
  }

  void _onResume() {
    print('DEBUG: App resumed, reloading UKM data');
    _loadUKMs();
  }

  Future<void> _loadUKMs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      print('DEBUG: Current user: ${user?.email}');

      // Try minimal query first
      final response = await _supabase
          .from('ukm')
          .select('id_ukm, nama_ukm, email, logo');

      print('DEBUG: Response: $response');
      print(
        'DEBUG: Response length: ${response is List ? response.length : 'N/A'}',
      );

      // Load user's registered UKMs (baik login maupun anonymous)
      final registeredUKMIds = Set<String>();
      final Map<String, int> attendanceMap = {};

      try {
        // Get all registered UKMs from database
        final userUKMResponse = await _supabase
            .from('user_halaman_ukm')
            .select('id_ukm')
            .order('created_at', ascending: false);

        print('DEBUG: userUKMResponse: $userUKMResponse');

        if (userUKMResponse is List) {
          for (var item in userUKMResponse) {
            registeredUKMIds.add(item['id_ukm']?.toString() ?? '');
            // Set default attendance, will be updated later from database
            attendanceMap[item['id_ukm']?.toString() ?? ''] = 0;
          }
        }
      } catch (e) {
        print('DEBUG: Error loading user UKMs: $e');
      }

      final List<dynamic> data = response as List;

      print('DEBUG: Loaded ${data.length} UKMs from database');

      setState(() {
        _allUKMs = data.map((ukm) {
          final isReg = registeredUKMIds.contains(ukm['id_ukm']?.toString());
          return {
            'id': ukm['id_ukm'],
            'name': ukm['nama_ukm'] ?? 'UKM',
            'logo': ukm['logo'],
            'email': ukm['email'] ?? '',
            'description': 'Tidak ada deskripsi',
            'jadwal': '-',
            'time': '-',
            'location': '-',
            'kontak': [
              {'icon': Icons.email, 'text': ukm['email'] ?? '-'},
            ],
            'isRegistered': isReg,
            'status': isReg ? 'Sudah Terdaftar' : 'Belum Terdaftar',
            'attendance': attendanceMap[ukm['id_ukm']?.toString()] ?? 0,
          };
        }).toList();
        _userUKMAttendance = attendanceMap;
        print('DEBUG: _allUKMs size: ${_allUKMs.length}');
        print('DEBUG: _filteredUKMs size: ${_filteredUKMs.length}');
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading UKMs: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUKMs {
    // Start with filtered by category
    List<Map<String, dynamic>> filtered;
    switch (_selectedFilter) {
      case 'Bergabung':
        filtered = _allUKMs
            .where((ukm) => ukm['isRegistered'] == true)
            .toList();
        break;
      case 'Belum':
        filtered = _allUKMs
            .where((ukm) => ukm['isRegistered'] == false)
            .toList();
        break;
      case 'Aktif':
        filtered = _allUKMs
            .where(
              (ukm) =>
                  ukm['isRegistered'] == true && ukm['attendance'] ?? 0 > 0,
            )
            .toList();
        break;
      case 'Populer':
        // Sort by attendance
        filtered = _allUKMs.toList()
          ..sort(
            (a, b) => (b['attendance'] ?? 0).compareTo(a['attendance'] ?? 0),
          );
        break;
      case 'Baru':
        // New UKMs
        filtered = _allUKMs.toList();
        break;
      case 'Semua':
        // All UKMs
        filtered = _allUKMs.toList();
        break;
      default:
        filtered = _allUKMs;
    }

    // Filter by search query
    if (_searchQuery.isEmpty) {
      return filtered;
    }

    final query = _searchQuery.toLowerCase();
    return filtered
        .where(
          (ukm) =>
              (ukm['name'] as String).toLowerCase().contains(query) ||
              (ukm['description'] as String).toLowerCase().contains(query) ||
              (ukm['email'] as String).toLowerCase().contains(query),
        )
        .toList();
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
    // Reload UKM data to reflect any changes
    _loadUKMs();
  }

  void _showRegisterDialog(Map<String, dynamic> ukm) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Anda yakin mendaftar UKM ini ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Tidak',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final user = _supabase.auth.currentUser;

                            // Generate anonymous user ID jika tidak login
                            final userId =
                                user?.id ??
                                'anonymous_${DateTime.now().millisecondsSinceEpoch}';

                            // Save to Supabase
                            await _supabase.from('user_halaman_ukm').insert({
                              'id_ukm': ukm['id'],
                            });

                            print(
                              'DEBUG: Berhasil insert user_halaman_ukm untuk ${ukm['name']}',
                            );

                            // Update local state
                            setState(() {
                              final index = _allUKMs.indexWhere(
                                (element) => element['id'] == ukm['id'],
                              );
                              if (index != -1) {
                                _allUKMs[index]['isRegistered'] = true;
                                _allUKMs[index]['status'] = 'Sudah Terdaftar';
                                _allUKMs[index]['attendance'] = 0;
                                _selectedUKM = _allUKMs[index];
                              }
                            });

                            if (!mounted) return;
                            Navigator.pop(context);

                            // Reload data to ensure consistency
                            await _loadUKMs();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Berhasil mendaftar ${ukm['name']}!',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.green[600],
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          } catch (e) {
                            print('Error registering UKM: $e');
                            if (!mounted) return;

                            // Check if it's duplicate entry error
                            if (e.toString().contains('duplicate') ||
                                e.toString().contains('unique')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Anda sudah terdaftar di UKM ini',
                                  ),
                                  backgroundColor: Colors.orange[600],
                                ),
                              );
                              Navigator.pop(context);
                              await _loadUKMs();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal mendaftar UKM: ${e.toString()}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red[600],
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Ya',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      drawer: Drawer(child: _buildSidebarVerticalModern()),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 70,
              left: 12,
              right: 12,
              bottom: 12,
            ),
            child: _selectedUKM == null
                ? _buildUKMListMobile()
                : _buildUKMDetailMobile(),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingTopBar(isMobile: true),
          ),
          if (_showQRScanner) _buildQRScannerOverlay(),
        ],
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 70), // Space for floating top bar
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: Container(
                        color: Colors.white,
                        child: _buildSidebarVerticalModern(),
                      ),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingTopBar(isMobile: false),
          ),
          if (_showQRScanner) _buildQRScannerOverlay(),
        ],
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Row(
            children: [
              _buildSidebarModern(),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 70), // Space for floating top bar
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
          Positioned(
            top: 0,
            left: 250,
            right: 0,
            child: _buildFloatingTopBar(isMobile: false),
          ),
          if (_showQRScanner) _buildQRScannerOverlay(),
        ],
      ),
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebarModern() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'UNIT ACTIVITY',
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4169E1),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildModernMenuItem(
                  Icons.dashboard,
                  'Dashboard',
                  AppRoutes.userDashboard,
                ),
                _buildModernMenuItem(Icons.event, 'Event', AppRoutes.userEvent),
                _buildModernMenuItem(Icons.groups, 'UKM', AppRoutes.userUKM),
                _buildModernMenuItem(
                  Icons.history,
                  'Histori',
                  AppRoutes.userHistory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMenuItem(IconData icon, String title, String route) {
    final isSelected = _selectedMenu == title;

    return InkWell(
      onTap: () {
        setState(() => _selectedMenu = title);
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

  // ==================== MODERN VERTICAL SIDEBAR (MOBILE/TABLET) ====================
  Widget _buildSidebarVerticalModern() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.school, color: Colors.blue[700], size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'UNIT ACTIVITY',
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildMenuItemCompactModern(
            Icons.dashboard_rounded,
            'Dashboard',
            AppRoutes.userDashboard,
          ),
          _buildMenuItemCompactModern(
            Icons.event_rounded,
            'Event',
            AppRoutes.userEvent,
          ),
          _buildMenuItemCompactModern(
            Icons.groups_rounded,
            'UKM',
            AppRoutes.userUKM,
          ),
          _buildMenuItemCompactModern(
            Icons.history_rounded,
            'Histori',
            AppRoutes.userHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCompactModern(
    IconData icon,
    String title,
    String route,
  ) {
    final isSelected = _selectedMenu == title;

    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.blue[700] : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.blue[700] : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      onTap: () {
        setState(() => _selectedMenu = title);
        Navigator.pop(context);
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

  // ==================== FLOATING TOP BAR ====================
  Widget _buildFloatingTopBar({required bool isMobile}) {
    return Container(
      margin: EdgeInsets.only(left: isMobile ? 0 : 8, right: 8, top: 8),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hamburger menu for mobile
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
              ),
            ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isMobile)
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
                  icon: const Icon(Icons.home_outlined),
                  tooltip: 'Home',
                ),
              if (!isMobile) const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showQRScanner = !_showQRScanner;
                  });
                },
                icon: const Icon(Icons.qr_code_2),
                tooltip: 'Scan QR Code',
                color: _showQRScanner ? Colors.blue[700] : Colors.grey[600],
              ),
              if (!isMobile) const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
              ),
              if (!isMobile) const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.userProfile),
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
                    backgroundColor: Colors.blue[600],
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
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.userProfile),
                  child: const Text(
                    'Adam',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== QR SCANNER OVERLAY ====================
  final TextEditingController _qrCodeController = TextEditingController();

  Widget _buildQRScannerOverlay() {
    return Positioned(
      top: 70,
      right: 8,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scan QR Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showQRScanner = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code, size: 60, color: Colors.blue[400]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.laptop_mac,
                          size: 18,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kamera tidak tersedia di perangkat ini. Silakan masukkan kode QR secara manual.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _qrCodeController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kode QR',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.qr_code_scanner,
                        color: Colors.grey[500],
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.blue[700]!,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final code = _qrCodeController.text.trim();
                        if (code.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Silakan masukkan kode QR'),
                              backgroundColor: Colors.orange[600],
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        // Process QR code
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Check-in berhasil dengan kode: $code',
                            ),
                            backgroundColor: Colors.green[600],
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        _qrCodeController.clear();
                        setState(() {
                          _showQRScanner = false;
                        });
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Submit Kode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Masukkan kode dari QR untuk check-in ke event atau aktivitas',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UKM LIST VIEW - MOBILE ====================
  Widget _buildUKMListMobile() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildFilterChipsMobile(),
          const SizedBox(height: 16),
          if (_filteredUKMs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text(
                'Tidak ada UKM yang tersedia',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredUKMs.length,
              itemBuilder: (context, index) {
                return _buildUKMCard(_filteredUKMs[index], isMobile: true);
              },
            ),
        ],
      ),
    );
  }

  // ==================== UKM LIST VIEW - TABLET ====================
  Widget _buildUKMListTablet() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildFilterChipsTablet(),
          const SizedBox(height: 16),
          if (_filteredUKMs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text(
                'Tidak ada UKM yang tersedia',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: _filteredUKMs.length,
              itemBuilder: (context, index) {
                return _buildUKMCard(_filteredUKMs[index], isMobile: false);
              },
            ),
        ],
      ),
    );
  }

  // ==================== UKM LIST VIEW - DESKTOP ====================
  Widget _buildUKMListDesktop() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildFilterChipsDesktop(),
          const SizedBox(height: 24),
          if (_filteredUKMs.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Text(
                    'Tidak ada UKM yang tersedia',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total UKM: ${_allUKMs.length}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Filter: $_selectedFilter',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_allUKMs.isEmpty)
                        ElevatedButton(
                          onPressed: _loadUKMs,
                          child: const Text('Muat Ulang Data'),
                        ),
                      if (_allUKMs.isNotEmpty) ...[
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'Semua';
                            });
                          },
                          child: const Text('Reset Filter'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.9,
              ),
              itemCount: _filteredUKMs.length,
              itemBuilder: (context, index) {
                return _buildUKMCard(_filteredUKMs[index], isMobile: false);
              },
            ),
        ],
      ),
    );
  }

  // ==================== UKM CARD ====================
  Widget _buildUKMCard(Map<String, dynamic> ukm, {required bool isMobile}) {
    final isRegistered = ukm['isRegistered'] as bool;
    final attendance = ukm['attendance'] as int? ?? 0;

    return InkWell(
      onTap: () => _viewUKMDetail(ukm),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
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
                      _buildUKMLogo(ukm['logo'], size: isMobile ? 50 : 70),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRegistered) ...[
                    // Progress bar untuk pertemuan
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$attendance/3 Pertemuan Dihadiri',
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          height: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: attendance / 3,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation(
                                attendance >= 3
                                    ? Colors.green[600]
                                    : Colors.blue[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Belum terdaftar - tampilkan empty progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '0/3 Pertemuan Dihadiri',
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          height: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: 0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation(
                                Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRegistered ? 'Terdaftar' : 'Belum Terdaftar',
                        style: TextStyle(
                          color: isRegistered
                              ? Colors.green[700]
                              : Colors.grey[600],
                          fontSize: isMobile ? 10 : 12,
                          fontWeight: isRegistered
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: isMobile ? 12 : 16,
                        color: isRegistered
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UKM LOGO HELPER ====================
  Widget _buildUKMLogo(String? logoPath, {double size = 50}) {
    if (logoPath == null || logoPath.isEmpty) {
      return _buildUKMLogoPlaceholder(size: size);
    }

    // Check if it's a network URL
    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: Image.network(
          logoPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildUKMLogoPlaceholder(size: size);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.blue[600],
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Assume it's an emoji or fallback
      return Text(logoPath, style: TextStyle(fontSize: size * 0.7));
    }
  }

  Widget _buildUKMLogoPlaceholder({double size = 50}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Icon(Icons.groups, size: size * 0.5, color: Colors.grey[500]),
      ),
    );
  }

  // ==================== FILTER CHIPS ====================
  Widget _buildFilterChipsMobile() {
    final filters = ['Semua', 'Bergabung', 'Belum', 'Aktif', 'Populer'];
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
    final filters = ['Semua', 'Bergabung', 'Belum', 'Aktif', 'Populer'];
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
    final filters = ['Semua', 'Bergabung', 'Belum', 'Aktif', 'Populer'];
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

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari UKM...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  color: Colors.grey[600],
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 0,
          ),
        ),
        style: const TextStyle(fontSize: 14),
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
                  _buildUKMLogo(_selectedUKM!['logo'], size: 80),
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
                        _buildUKMLogo(_selectedUKM!['logo'], size: 80),
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
                      _buildUKMLogo(_selectedUKM!['logo'], size: 120),
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
        }).toList(),
      ],
    );
  }
}

// Lifecycle observer untuk reload data ketika app resume
class _LifecycleObserver extends WidgetsBindingObserver {
  final Function() onResume;

  _LifecycleObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
