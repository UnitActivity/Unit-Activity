import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

class ProfileAdminPage extends StatefulWidget {
  const ProfileAdminPage({super.key});

  @override
  State<ProfileAdminPage> createState() => _ProfileAdminPageState();
}

class _ProfileAdminPageState extends State<ProfileAdminPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _changePassword = false;

  // User data
  Map<String, dynamic>? _userData;

  // Controllers for edit mode
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    print('=== Loading User Profile ===');
    setState(() => _isLoading = true);

    try {
      // Get user data from CustomAuthService
      final userData = _authService.currentUser;
      final userId = _authService.currentUserId;
      final userRole = _authService.currentUserRole;

      print('Current user from auth service: $userData');
      print('User ID: $userId, Role: $userRole');

      if (userId == null || userData == null) {
        print('User is not logged in');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _userData = null;
          });
        }
        return;
      }

      // Load full profile data from database based on role
      if (userRole == 'admin' || userRole == 'ukm') {
        print('Loading admin profile for ID: $userId');
        final adminData = await _supabase
            .from('admin')
            .select(
              'id_admin, username_admin, email_admin, role, status, create_at',
            )
            .eq('id_admin', userId)
            .maybeSingle()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('Admin query timeout');
                return null;
              },
            );

        print('Admin data from DB: $adminData');

        print('Admin data: $adminData');

        print('Admin data from DB: $adminData');

        if (adminData != null) {
          print('Admin profile loaded from DB');
          setState(() {
            _userData = {
              'id': adminData['id_admin'],
              'username': adminData['username_admin'],
              'email': adminData['email_admin'],
              'role': adminData['role'],
              'status': adminData['status'],
              'created_at': adminData['create_at'],
            };
            _usernameController.text = _userData!['username'] ?? '';
            _emailController.text = _userData!['email'] ?? '';
            _isLoading = false;
          });
          print('Admin profile loaded successfully');
        } else {
          // Use auth service data as fallback
          print('Admin data not in DB, using auth service data');
          setState(() {
            _userData = {
              'id': userId,
              'username': userData['name'] ?? 'Admin',
              'email': userData['email'] ?? '',
              'role': userRole,
              'status': userData['status'] ?? 'aktif',
              'created_at': DateTime.now().toIso8601String(),
              'is_fallback': true,
            };
            _usernameController.text = _userData!['username'] ?? '';
            _emailController.text = _userData!['email'] ?? '';
            _isLoading = false;
          });
        }
      } else {
        // Load user profile
        print('Loading user profile for ID: $userId');
        final userDataFromDb = await _supabase
            .from('users')
            .select('id_user, username, email, nim, picture, create_at')
            .eq('id_user', userId)
            .maybeSingle()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('Users query timeout');
                return null;
              },
            );

        print('User data from DB: $userDataFromDb');

        print('User data: $userData');

        print('User data from DB: $userDataFromDb');

        if (userDataFromDb != null) {
          print('User profile loaded from DB');
          final data = userDataFromDb;
          setState(() {
            _userData = {
              'id': data['id_user'],
              'username': data['username'],
              'email': data['email'],
              'nim': data['nim'],
              'picture': data['picture'],
              'role': 'user',
              'created_at': data['create_at'],
            };
            _usernameController.text = _userData!['username'] ?? '';
            _emailController.text = _userData!['email'] ?? '';
            _isLoading = false;
          });
          print('User profile loaded successfully');
        } else {
          // Use auth service data as fallback
          print('User data not in DB, using auth service data');
          setState(() {
            _userData = {
              'id': userId,
              'username': userData['name'] ?? 'User',
              'email': userData['email'] ?? '',
              'nim': userData['nim'] ?? '',
              'role': 'user',
              'created_at': DateTime.now().toIso8601String(),
              'is_fallback': true,
            };
            _usernameController.text = _userData!['username'] ?? '';
            _emailController.text = _userData!['email'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    print('=== Profile Loading Complete ===');
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return null;
    if (password.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password harus mengandung huruf besar';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password harus mengandung huruf kecil';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password harus mengandung angka';
    }
    return null;
  }

  Future<void> _saveChanges() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password if changing
    if (_changePassword) {
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password tidak boleh kosong'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final passwordError = _validatePassword(_passwordController.text);
      if (passwordError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(passwordError), backgroundColor: Colors.red),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password dan konfirmasi password tidak sama'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      // Check if this is fallback data (not in database yet)
      if (_userData!['is_fallback'] == true) {
        // Insert new record instead of update
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase.from('users').insert({
            'id_user': user.id,
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'create_at': DateTime.now().toIso8601String(),
          });

          // Remove fallback flag
          _userData!.remove('is_fallback');
        }
      } else {
        // Normal update
        final updateData = {
          if (_userData!['role'] == 'admin' || _userData!['role'] == 'ukm')
            'username_admin': _usernameController.text.trim()
          else
            'username': _usernameController.text.trim(),
          if (_userData!['role'] == 'admin' || _userData!['role'] == 'ukm')
            'email_admin': _emailController.text.trim()
          else
            'email': _emailController.text.trim(),
        };

        // Update based on role
        if (_userData!['role'] == 'admin' || _userData!['role'] == 'ukm') {
          await _supabase
              .from('admin')
              .update(updateData)
              .eq('id_admin', _userData!['id']);
        } else {
          await _supabase
              .from('users')
              .update(updateData)
              .eq('id_user', _userData!['id']);
        }
      }

      // Update password if changed
      if (_changePassword && _passwordController.text.isNotEmpty) {
        // Update password in database (hashed)
        if (_userData!['role'] == 'admin' || _userData!['role'] == 'ukm') {
          await _supabase
              .from('admin')
              .update({
                'password_hash':
                    _passwordController.text, // Will be hashed by trigger
              })
              .eq('id_admin', _userData!['id']);
        } else {
          await _supabase
              .from('users')
              .update({
                'password_hash':
                    _passwordController.text, // Will be hashed by trigger
              })
              .eq('id_user', _userData!['id']);
        }
      }

      // Update local data
      _userData!['username'] = _usernameController.text.trim();
      _userData!['email'] = _emailController.text.trim();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _changePassword
                  ? 'Data dan password berhasil diperbarui'
                  : 'Data berhasil diperbarui',
            ),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isEditMode = false;
          _changePassword = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _changePassword = false;
      _usernameController.text = _userData!['username'] ?? '';
      _emailController.text = _userData!['email'] ?? '';
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat profil...',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_userData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Data profil tidak ditemukan',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning banner for fallback data
          if (_userData!['is_fallback'] == true)
            Container(
              margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Data profil belum tersimpan di database. Silakan edit dan simpan untuk melengkapi profil Anda.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profil Saya',
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (!_isEditMode && !_isSaving)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isEditMode = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 8 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.edit, size: isMobile ? 18 : 20),
                  label: Text(
                    'Edit Profil',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),

          // Profile Card
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: isMobile ? 50 : 60,
                  backgroundColor: const Color(0xFF4169E1).withOpacity(0.1),
                  child:
                      _userData!['picture'] != null &&
                          _userData!['picture'].toString().isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            _userData!['picture'],
                            width: isMobile ? 100 : 120,
                            height: isMobile ? 100 : 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: isMobile ? 50 : 60,
                                color: const Color(0xFF4169E1),
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: isMobile ? 50 : 60,
                          color: const Color(0xFF4169E1),
                        ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(_userData!['role']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getRoleColor(_userData!['role']),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getRoleLabel(_userData!['role']),
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(_userData!['role']),
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 24),

                // Form Fields
                _buildProfileField(
                  label: 'Username',
                  controller: _usernameController,
                  icon: Icons.person_outline,
                  enabled: _isEditMode,
                  isMobile: isMobile,
                ),
                SizedBox(height: isMobile ? 12 : 16),

                _buildProfileField(
                  label: 'Email',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  enabled: _isEditMode,
                  isMobile: isMobile,
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // NIM (only for users)
                if (_userData!['nim'] != null)
                  Column(
                    children: [
                      _buildInfoField(
                        label: 'NIM',
                        value: _userData!['nim'] ?? '-',
                        icon: Icons.badge_outlined,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                    ],
                  ),

                // Role
                _buildInfoField(
                  label: 'Role',
                  value: _getRoleLabel(_userData!['role']),
                  icon: Icons.admin_panel_settings_outlined,
                  isMobile: isMobile,
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Status (only for admin)
                if (_userData!['status'] != null)
                  Column(
                    children: [
                      _buildInfoField(
                        label: 'Status',
                        value: _userData!['status'] ?? '-',
                        icon: Icons.check_circle_outline,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                    ],
                  ),

                // Created At
                _buildInfoField(
                  label: 'Terdaftar Sejak',
                  value: _formatDate(_userData!['created_at']),
                  icon: Icons.calendar_today_outlined,
                  isMobile: isMobile,
                ),

                // Change Password Section (only in edit mode)
                if (_isEditMode) ...[
                  SizedBox(height: isMobile ? 16 : 20),
                  const Divider(),
                  SizedBox(height: isMobile ? 16 : 20),

                  CheckboxListTile(
                    title: Text(
                      'Ubah Password',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _changePassword,
                    onChanged: (value) {
                      setState(() {
                        _changePassword = value ?? false;
                        if (!_changePassword) {
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                        }
                      });
                    },
                    activeColor: const Color(0xFF4169E1),
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (_changePassword) ...[
                    SizedBox(height: isMobile ? 12 : 16),
                    _buildPasswordField(
                      label: 'Password Baru',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    _buildPasswordField(
                      label: 'Konfirmasi Password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                      isMobile: isMobile,
                    ),
                  ],
                ],

                // Action Buttons (in edit mode)
                if (_isEditMode) ...[
                  SizedBox(height: isMobile ? 20 : 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _cancelEdit,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12 : 14,
                            ),
                            side: BorderSide(
                              color: Colors.grey[400]!,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4169E1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  height: isMobile ? 16 : 20,
                                  width: isMobile ? 16 : 20,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Simpan',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 13 : 14,
            color: enabled ? Colors.black87 : Colors.grey[600],
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: isMobile ? 18 : 20,
              color: Colors.grey[600],
            ),
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
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
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 14,
              vertical: isMobile ? 12 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 14,
            vertical: isMobile ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, size: isMobile ? 18 : 20, color: Colors.grey[600]),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outline,
              size: isMobile ? 18 : 20,
              color: Colors.grey[600],
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: isMobile ? 18 : 20,
                color: Colors.grey[600],
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: Colors.grey[50],
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
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 14,
              vertical: isMobile ? 12 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return const Color(0xFFDC2626); // Red
      case 'ukm':
        return const Color(0xFF9333EA); // Purple
      case 'user':
        return const Color(0xFF4169E1); // Blue
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'ukm':
        return 'UKM Admin';
      case 'user':
        return 'Pengguna';
      default:
        return role ?? 'Unknown';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
