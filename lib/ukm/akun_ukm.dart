import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:unit_activity/services/custom_auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AkunUKMPage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  
  const AkunUKMPage({super.key, this.onProfileUpdated});

  @override
  State<AkunUKMPage> createState() => _AkunUKMPageState();
}

class _AkunUKMPageState extends State<AkunUKMPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _changePassword = false;

  // User data
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _ukmData;

  // Controllers for edit mode
  final TextEditingController _namaUkmController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Image uploading
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _namaUkmController.dispose();
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
        if (mounted) {
          setState(() {
            _isLoading = false;
            _userData = null;
          });
        }
        return;
      }

      // Load admin profile data
      if (userRole == 'ukm') {
        final adminData = await _supabase
            .from('admin')
            .select(
              'id_admin, username_admin, email_admin, role, status, create_at',
            )
            .eq('id_admin', userId)
            .maybeSingle();

        if (adminData != null) {
          // Load UKM data
          final ukmData = await _supabase
              .from('ukm')
              .select('id_ukm, nama_ukm, id_admin, logo')
              .eq('id_admin', userId)
              .maybeSingle();

          if (mounted) {
            setState(() {
              _userData = adminData;
              _ukmData = ukmData;
              _namaUkmController.text = ukmData?['nama_ukm'] ?? '';
              _usernameController.text = adminData['username_admin'] ?? '';
              _emailController.text = adminData['email_admin'] ?? '';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
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

  Future<void> _saveProfile() async {
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

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password dan konfirmasi password tidak cocok'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final userId = _authService.currentUserId;

      // Update admin table
      await _supabase
          .from('admin')
          .update({
            'username_admin': _usernameController.text,
            'email_admin': _emailController.text,
          })
          .eq('id_admin', userId!);

      // Update UKM name if ukmData exists
      if (_ukmData != null) {
        await _supabase
            .from('ukm')
            .update({
              'nama_ukm': _namaUkmController.text,
            })
            .eq('id_ukm', _ukmData!['id_ukm']);
      }

      // Update password if changed
      if (_changePassword && _passwordController.text.isNotEmpty) {
        await _supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isEditMode = false;
          _changePassword = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });

        await _loadUserProfile();
        
        // Notify parent to refresh dashboard data
        widget.onProfileUpdated?.call();
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: $e'),
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
      _namaUkmController.text = _ukmData?['nama_ukm'] ?? '';
      _usernameController.text = _userData?['username_admin'] ?? '';
      _emailController.text = _userData?['email_admin'] ?? '';
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  String? _getUkmLogoUrl(String? logoPath) {
    if (logoPath == null || logoPath.isEmpty) return null;
    if (logoPath.startsWith('http')) return logoPath;
    return _supabase.storage.from('ukm-logos').getPublicUrl(logoPath);
  }

  Future<void> _pickAndUploadLogo() async {
    if (_ukmData == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      // Read image bytes
      final Uint8List bytes = await image.readAsBytes();
      final String ukmId = _ukmData!['id_ukm'];
      final String fileName = '${ukmId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      debugPrint('📤 UKM PROFILE: Uploading logo for UKM: $ukmId');
      debugPrint('📤 UKM PROFILE: File name: $fileName');
      debugPrint('📤 UKM PROFILE: File size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');

      // Upload to Supabase Storage
      await _supabase.storage.from('ukm-logos').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      debugPrint('✅ UKM PROFILE: Logo uploaded to storage');

      // Get public URL
      final String logoUrl = _supabase.storage.from('ukm-logos').getPublicUrl(fileName);

      debugPrint('📸 UKM PROFILE: Public URL: $logoUrl');

      // Update UKM table with new logo URL
      await _supabase.from('ukm').update({
        'logo': logoUrl,
      }).eq('id_ukm', ukmId);

      debugPrint('✅ UKM PROFILE: Database updated with new logo URL');

      // Update local state
      if (mounted) {
        setState(() {
          _ukmData!['logo'] = logoUrl;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Logo UKM berhasil diupload!',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Notify parent to refresh dashboard data
        widget.onProfileUpdated?.call();
      }
    } catch (e) {
      debugPrint('❌ UKM PROFILE: Error uploading logo: $e');
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal mengupload logo: ${e.toString()}',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                // Avatar with UKM Name and Edit Button
                Stack(
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 50 : 60,
                      backgroundColor: const Color(0xFF4169E1).withOpacity(0.1),
                      backgroundImage: _ukmData != null &&
                              _getUkmLogoUrl(_ukmData!['logo']) != null
                          ? NetworkImage(_getUkmLogoUrl(_ukmData!['logo'])!)
                          : null,
                      child: _isUploadingImage
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4169E1),
                              ),
                            )
                          : (_ukmData == null ||
                                  _ukmData!['logo'] == null ||
                                  _ukmData!['logo'] == '')
                              ? Icon(
                                  Icons.group,
                                  size: isMobile ? 50 : 60,
                                  color: const Color(0xFF4169E1),
                                )
                              : null,
                    ),
                    // Camera button overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4169E1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: _isUploadingImage ? null : _pickAndUploadLogo,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 6 : 8),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: isMobile ? 16 : 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // UKM Name (displays from controller for live update)
                if (_ukmData != null)
                  Text(
                    _namaUkmController.text.isNotEmpty 
                        ? _namaUkmController.text 
                        : 'UKM',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: isMobile ? 16 : 24),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4169E1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Admin UKM',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4169E1),
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 24),

                // Form Fields
                // UKM Name Field
                _buildProfileField(
                  label: 'Nama UKM',
                  controller: _namaUkmController,
                  icon: Icons.business,
                  enabled: _isEditMode,
                  isMobile: isMobile,
                ),
                SizedBox(height: isMobile ? 12 : 16),
                
                _buildProfileField(
                  label: 'Username Admin',
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

                _buildInfoField(
                  label: 'Role',
                  value: 'Admin UKM',
                  icon: Icons.admin_panel_settings_outlined,
                  isMobile: isMobile,
                ),
                SizedBox(height: isMobile ? 12 : 16),

                _buildInfoField(
                  label: 'Status',
                  value:
                      _userData!['status']?.toString() == 'aktif' ||
                          _userData!['status']?.toString() == 'active'
                      ? 'Aktif'
                      : 'Tidak Aktif',
                  icon: Icons.check_circle_outline,
                  isMobile: isMobile,
                ),
                SizedBox(height: isMobile ? 12 : 16),

                _buildInfoField(
                  label: 'Terdaftar Sejak',
                  value: _userData!['create_at'] != null
                      ? DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(DateTime.parse(_userData!['create_at']))
                      : '-',
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
                    // Password requirements hint
                    SizedBox(height: isMobile ? 8 : 12),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password harus memenuhi:',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildPasswordRequirement(
                            'Minimal 8 karakter',
                            isMobile,
                          ),
                          _buildPasswordRequirement(
                            'Mengandung huruf besar',
                            isMobile,
                          ),
                          _buildPasswordRequirement(
                            'Mengandung huruf kecil',
                            isMobile,
                          ),
                          _buildPasswordRequirement(
                            'Mengandung angka',
                            isMobile,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                // Action Buttons (only in edit mode)
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
                            side: BorderSide(color: Colors.grey[300]!),
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
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
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
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Simpan Perubahan',
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

  Widget _buildPasswordRequirement(String text, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: isMobile ? 12 : 14,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 10 : 11,
              color: Colors.blue[800],
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
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: isMobile ? 18 : 20),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[50],
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
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 14,
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: isMobile ? 13 : 14,
            color: Colors.grey[800],
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
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: isMobile ? 18 : 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey[800],
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
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: Color(0xFF4169E1)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 10 : 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: isMobile ? 18 : 20,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: isMobile ? 13 : 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
