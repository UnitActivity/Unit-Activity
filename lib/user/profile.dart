import 'package:flutter/material.dart';
import 'package:unit_activity/config/routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
      appBar: AppBar(
        title: const Text('Unit Activity'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      drawer: Drawer(child: _buildSidebarVertical()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: _buildProfileContent(isMobile: true),
      ),
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
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.userProfile);
            },
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
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
