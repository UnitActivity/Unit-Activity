import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unit_activity/services/custom_auth_service.dart';
import 'package:unit_activity/services/profile_image_service.dart';

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
  bool _isUploadingPhoto = false;
  bool _changePassword = false;

  Map<String, dynamic>? _userData;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
    setState(() => _isLoading = true);

    try {
      final userData = _authService.currentUser;
      final userId = _authService.currentUserId;
      final userRole = _authService.currentUserRole;

      if (userId == null || userData == null) {
        await _authService.initialize();
        final restoredUserId = _authService.currentUserId;
        final restoredUserData = _authService.currentUser;
        final restoredRole = _authService.currentUserRole;

        if (restoredUserId == null || restoredUserData == null) {
          if (mounted)
            setState(() {
              _isLoading = false;
              _userData = null;
            });
          return;
        }
        await _loadProfileFromDatabase(
          restoredUserId,
          restoredRole ?? 'admin',
          restoredUserData,
        );
        return;
      }

      await _loadProfileFromDatabase(userId, userRole ?? 'admin', userData);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProfileFromDatabase(
    String userId,
    String userRole,
    Map<String, dynamic> authData,
  ) async {
    try {
      if (userRole == 'admin' || userRole == 'ukm') {
        final adminData = await _supabase
            .from('admin')
            .select(
              'id_admin, username_admin, email_admin, role, status, create_at',
            )
            .eq('id_admin', userId)
            .maybeSingle();

        if (adminData != null) {
          await _loadProfileImage(userId, userRole);
          if (mounted) {
            setState(() {
              _userData = {
                'id': adminData['id_admin'],
                'username': adminData['username_admin'],
                'email': adminData['email_admin'],
                'role': adminData['role'] ?? 'admin',
                'status': adminData['status'] ?? 'aktif',
                'created_at': adminData['create_at'],
              };
              _usernameController.text = _userData!['username'] ?? '';
              _emailController.text = _userData!['email'] ?? '';
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userData = {
                'id': userId,
                'username': authData['name'] ?? 'Admin',
                'email': authData['email'] ?? '',
                'role': userRole,
                'status': 'aktif',
                'created_at': DateTime.now().toIso8601String(),
              };
              _usernameController.text = _userData!['username'] ?? '';
              _emailController.text = _userData!['email'] ?? '';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfileImage(String userId, String role) async {
    try {
      final username = _userData?['username'] ?? 'admin';
      for (final format in ['jpg', 'jpeg', 'png', 'webp']) {
        try {
          final fileName = '$role-$username.$format';

          final List<FileObject> objects = await _supabase.storage
              .from('profile')
              .list(searchOptions: SearchOptions(limit: 1, search: fileName));

          if (objects.isNotEmpty) {
            final publicUrl = _supabase.storage
                .from('profile')
                .getPublicUrl(fileName);

            ProfileImageService.instance.updateProfileImage(publicUrl);
            return;
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      /* ignore */
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_userData == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final String role = _userData!['role'] ?? 'admin';
      final String username = _userData!['username'] ?? 'admin';

      // Hapus foto lama dengan format apapun untuk menghindari duplikasi/konflik
      for (final format in ['jpg', 'jpeg', 'png', 'webp']) {
        try {
          await _supabase.storage.from('profile').remove([
            '$role-$username.$format',
          ]);
        } catch (_) {}
      }

      final String extension = image.path.split('.').last.toLowerCase();
      final String fileName = '$role-$username.$extension';
      final bytes = await image.readAsBytes();

      await _supabase.storage
          .from('profile')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/$extension',
            ),
          );

      final publicUrl = _supabase.storage
          .from('profile')
          .getPublicUrl(fileName);

      setState(() => _isUploadingPhoto = false);

      ProfileImageService.instance.updateProfileImage(publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diupload!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      if (_passwordController.text.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password minimal 8 karakter'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password tidak sama'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      if (_userData!['role'] == 'admin' || _userData!['role'] == 'ukm') {
        await _supabase
            .from('admin')
            .update({
              'username_admin': _usernameController.text.trim(),
              'email_admin': _emailController.text.trim(),
            })
            .eq('id_admin', _userData!['id']);

        if (_changePassword && _passwordController.text.isNotEmpty) {
          await _supabase
              .from('admin')
              .update({'password': _passwordController.text})
              .eq('id_admin', _userData!['id']);
        }
      }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF4169E1);
      case 'ukm':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'ukm':
        return 'UKM Manager';
      default:
        return role ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4169E1)),
      );
    }

    if (_userData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Data profil tidak ditemukan',
              style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
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
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left - Profile Card
        SizedBox(width: 320, child: _buildProfileCard()),
        const SizedBox(width: 24),
        // Right - Details
        Expanded(
          child: Column(
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildSecurityCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildProfileCard(),
        const SizedBox(height: 16),
        _buildInfoCard(),
        const SizedBox(height: 16),
        _buildSecurityCard(),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickAndUploadImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4169E1),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _isUploadingPhoto
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : ValueListenableBuilder<String?>(
                            valueListenable:
                                ProfileImageService.instance.profileImageUrl,
                            builder: (context, imageUrl, _) {
                              return imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildDefaultAvatar(),
                                    )
                                  : _buildDefaultAvatar();
                            },
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4169E1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Name
          Text(
            _userData!['username'] ?? 'Admin',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _userData!['email'] ?? '',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getRoleColor(_userData!['role']).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleLabel(_userData!['role']),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _getRoleColor(_userData!['role']),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Stats
          _buildStat(
            Icons.verified_user,
            'Status',
            _userData!['status'] ?? 'Aktif',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStat(
            Icons.calendar_today,
            'Bergabung',
            _formatDate(_userData!['created_at']),
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Image.asset(
      'assets/ua.webp',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF4169E1).withValues(alpha: 0.1),
        child: const Icon(Icons.person, size: 50, color: Color(0xFF4169E1)),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                'Informasi Akun',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!_isEditMode)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditMode = true),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            'Username',
            _usernameController,
            Icons.person_outline,
            _isEditMode,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Email',
            _emailController,
            Icons.email_outlined,
            _isEditMode,
          ),
          if (_isEditMode) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _isEditMode = false;
                      _usernameController.text = _userData!['username'] ?? '';
                      _emailController.text = _userData!['email'] ?? '';
                    }),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool enabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keamanan',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => setState(() {
              _changePassword = !_changePassword;
              if (!_changePassword) {
                _passwordController.clear();
                _confirmPasswordController.clear();
              }
            }),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _changePassword
                    ? const Color(0xFF4169E1).withValues(alpha: 0.05)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _changePassword
                      ? const Color(0xFF4169E1).withValues(alpha: 0.3)
                      : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: _changePassword
                        ? const Color(0xFF4169E1)
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ubah Password',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _changePassword
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_changePassword) ...[
            const SizedBox(height: 20),
            _buildPasswordField(
              'Password Baru',
              _passwordController,
              _obscurePassword,
              () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              'Konfirmasi Password',
              _confirmPasswordController,
              _obscureConfirmPassword,
              () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Password'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility : Icons.visibility_off,
                size: 20,
              ),
              onPressed: toggle,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
