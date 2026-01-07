import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/widgets/qr_scanner_mixin.dart';
import 'package:unit_activity/widgets/notification_bell_widget.dart';
import 'package:unit_activity/user/notifikasi_user.dart';
import 'package:unit_activity/user/dashboard_user.dart';
import 'package:unit_activity/user/event.dart';
import 'package:unit_activity/user/ukm.dart';
import 'package:unit_activity/user/history.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with QRScannerMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _npmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(
    text: '••••••••••••',
  );
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();

  bool _isEditingUsername = false;
  bool _isEditingNpm = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;
  bool _isEditingTanggalLahir = false;
  bool _isLoading = true;
  bool _isSaving = false;

  String _selectedMenu = 'profile';
  bool _showQRScanner = false;
  String? _avatarUrl;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        // No user logged in
        setState(() => _isLoading = false);
        return;
      }

      _userId = user.id;

      // Load user data from database
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id_user', user.id)
          .maybeSingle();

      if (userData != null) {
        _usernameController.text = userData['username'] ?? '';
        _npmController.text = userData['npm']?.toString() ?? '';
        _emailController.text = userData['email'] ?? user.email ?? '';
        _tanggalLahirController.text = userData['tanggal_lahir'] ?? '';
        _avatarUrl = userData['avatar'];
      } else {
        // Use auth email if no user data found
        _emailController.text = user.email ?? '';
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_userId == null) return;

    setState(() => _isSaving = true);

    try {
      await _supabase.from('users').upsert({
        'id_user': _userId,
        'username': _usernameController.text.trim(),
        'npm': _npmController.text.trim(),
        'email': _emailController.text.trim(),
        'tanggal_lahir': _tanggalLahirController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil berhasil disimpan'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditingUsername = false;
          _isEditingNpm = false;
          _isEditingEmail = false;
          _isEditingPassword = false;
          _isEditingTanggalLahir = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _npmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tanggalLahirController.dispose();
    _qrCodeController.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 70,
              left: 12,
              right: 12,
              bottom: 80,
            ),
            child: _buildProfileContent(isMobile: true),
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
      bottomNavigationBar: _buildBottomNavBar(),
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildProfileContent(isMobile: false),
                      ),
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildProfileContent(isMobile: false),
                      ),
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

  // ==================== PROFILE CONTENT ====================
  Widget _buildProfileContent({required bool isMobile}) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'My Profile',
          style: TextStyle(
            fontSize: isMobile ? 18 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Card Profile
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              children: [
                // Avatar & Name
                CircleAvatar(
                  radius: isMobile ? 40 : 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: isMobile ? 40 : 60,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _usernameController.text.isEmpty
                      ? 'User'
                      : _usernameController.text,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_emailController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _emailController.text,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Username
                _buildProfileField(
                  label: 'USERNAME',
                  controller: _usernameController,
                  isEditing: _isEditingUsername,
                  isMobile: isMobile,
                  onEditPressed: () {
                    setState(() {
                      _isEditingUsername = !_isEditingUsername;
                    });
                  },
                ),

                // NPM
                _buildProfileField(
                  label: 'NPM',
                  controller: _npmController,
                  isEditing: _isEditingNpm,
                  isMobile: isMobile,
                  onEditPressed: () {
                    setState(() {
                      _isEditingNpm = !_isEditingNpm;
                    });
                  },
                ),

                // Email
                _buildProfileField(
                  label: 'EMAIL',
                  controller: _emailController,
                  isEditing: _isEditingEmail,
                  icon: Icons.email_outlined,
                  isMobile: isMobile,
                  onEditPressed: () {
                    setState(() {
                      _isEditingEmail = !_isEditingEmail;
                    });
                  },
                ),

                // Password
                _buildProfileField(
                  label: 'PASSWORD',
                  controller: _passwordController,
                  isEditing: _isEditingPassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  isMobile: isMobile,
                  onEditPressed: () {
                    setState(() {
                      _isEditingPassword = !_isEditingPassword;
                    });
                  },
                ),

                // Tanggal Lahir
                _buildProfileField(
                  label: 'TANGGAL LAHIR',
                  controller: _tanggalLahirController,
                  isEditing: _isEditingTanggalLahir,
                  icon: Icons.calendar_today_outlined,
                  isMobile: isMobile,
                  onEditPressed: () {
                    setState(() {
                      _isEditingTanggalLahir = !_isEditingTanggalLahir;
                    });
                  },
                ),

                // Save Button
                if (_isEditingUsername ||
                    _isEditingNpm ||
                    _isEditingEmail ||
                    _isEditingPassword ||
                    _isEditingTanggalLahir)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: isMobile ? 44 : 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Logout Button
        SizedBox(
          width: double.infinity,
          height: isMobile ? 44 : 48,
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red[600]),
                      const SizedBox(width: 12),
                      const Text('Logout'),
                    ],
                  ),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await _supabase.auth.signOut();
                        } catch (e) {
                          debugPrint('Error signing out: $e');
                        }
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebarModern() {
    return Container(
      width: 260,
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
                _buildModernMenuItem(Icons.dashboard, 'Dashboard', 'dashboard'),
                _buildModernMenuItem(Icons.event, 'Event', 'event'),
                _buildModernMenuItem(Icons.groups, 'UKM', 'ukm'),
                _buildModernMenuItem(Icons.history, 'Histori', 'history'),
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
        if (route == 'dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardUser()),
          );
        } else if (route == 'event') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserEventPage()),
          );
        } else if (route == 'ukm') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserUKMPage()),
          );
        } else if (route == 'history') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HistoryPage()),
          );
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
            'dashboard',
          ),
          _buildMenuItemCompactModern(Icons.event_rounded, 'Event', 'event'),
          _buildMenuItemCompactModern(Icons.groups_rounded, 'UKM', 'ukm'),
          _buildMenuItemCompactModern(
            Icons.history_rounded,
            'Histori',
            'history',
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
          if (route == 'dashboard') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardUser()),
            );
          } else if (route == 'event') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserEventPage()),
            );
          } else if (route == 'ukm') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserUKMPage()),
            );
          } else if (route == 'history') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
          }
        });
      },
    );
  } // ==================== FLOATING TOP BAR ====================

  Widget _buildFloatingTopBar({required bool isMobile}) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
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
      child: isMobile
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NotificationBellWidget(
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotifikasiUserPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 20, color: Colors.white),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // QR Scanner Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => openQRScannerDialog(
                      onCodeScanned: _handleQRCodeScanned,
                    ),
                    icon: Icon(Icons.qr_code_scanner, color: Colors.blue[700]),
                    tooltip: 'Scan QR Code',
                  ),
                ),
                const SizedBox(width: 12),
                NotificationBellWidget(
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotifikasiUserPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }

  // ==================== QR SCANNER HANDLER ====================
  void _handleQRCodeScanned(String code) {
    print('DEBUG: QR Code scanned: $code');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR Code scanned: $code'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==================== BOTTOM NAVIGATION BAR ====================
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Dashboard
                _buildNavItem(
                  Icons.home_rounded,
                  'Dashboard',
                  _selectedMenu == 'dashboard',
                  () => _handleMenuSelected('dashboard'),
                ),
                // Event
                _buildNavItem(
                  Icons.event_rounded,
                  'Event',
                  _selectedMenu == 'event',
                  () => _handleMenuSelected('event'),
                ),
                // Center QR Scanner button
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[600],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => openQRScannerDialog(
                        onCodeScanned: (code) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('QR Code scanned: $code'),
                              backgroundColor: Colors.green[600],
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      borderRadius: BorderRadius.circular(28),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_2,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                // UKM
                _buildNavItem(
                  Icons.school_rounded,
                  'UKM',
                  _selectedMenu == 'ukm',
                  () => _handleMenuSelected('ukm'),
                ),
                // History
                _buildNavItem(
                  Icons.history_rounded,
                  'History',
                  _selectedMenu == 'history',
                  () => _handleMenuSelected('history'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NAV ITEM WIDGET ====================
  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue[600] : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue[600] : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MENU HANDLERS ====================
  void _handleMenuSelected(String menu) {
    if (_selectedMenu == menu) return;

    setState(() {
      _selectedMenu = menu;
    });

    switch (menu) {
      case 'dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardUser()),
        );
        break;
      case 'event':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserEventPage()),
        );
        break;
      case 'ukm':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserUKMPage()),
        );
        break;
      case 'history':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryPage()),
        );
        break;
    }
  }

  // ==================== QR SCANNER OVERLAY ====================
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

  // ==================== PROFILE FIELD ====================
  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required bool isMobile,
    required VoidCallback onEditPressed,
    IconData? icon,
    bool obscureText = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: isMobile ? 16 : 18, color: Colors.grey[500]),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: controller,
                        obscureText: obscureText && isEditing,
                        onChanged: (value) {
                          // Update UI in real-time when username changes
                          if (label == 'USERNAME') {
                            setState(() {});
                          }
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue[700]!),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blue[700]!,
                              width: 2,
                            ),
                          ),
                        ),
                        autofocus: true,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.text,
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(height: 1, color: Colors.grey[300]),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEditPressed,
                icon: Icon(
                  Icons.edit_outlined,
                  size: isMobile ? 16 : 18,
                  color: Colors.grey[600],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
