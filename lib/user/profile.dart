import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/config/routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController(
    text: 'Adam',
  );
  final TextEditingController _npmController = TextEditingController(
    text: '2170001',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'adam@gmail.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '••••••••••••',
  );
  final TextEditingController _tanggalLahirController = TextEditingController(
    text: '01/01/2002',
  );

  bool _isEditingUsername = false;
  bool _isEditingNpm = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;
  bool _isEditingTanggalLahir = false;

  String _selectedMenu = 'Profile';
  bool _showQRScanner = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _npmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tanggalLahirController.dispose();
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
                  child: Icon(
                    Icons.person,
                    size: isMobile ? 40 : 60,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _usernameController.text,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
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
                        onPressed: () {
                          setState(() {
                            _isEditingUsername = false;
                            _isEditingNpm = false;
                            _isEditingEmail = false;
                            _isEditingPassword = false;
                            _isEditingTanggalLahir = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Perubahan berhasil disimpan'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
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
                  title: const Text('Logout'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        AppRoutes.logout(context);
                      },
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
            child: Text(
              'Logout',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
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
  } // ==================== FLOATING TOP BAR ====================

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
