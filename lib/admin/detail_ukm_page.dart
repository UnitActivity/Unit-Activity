import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:typed_data';

class DetailUkmPage extends StatefulWidget {
  final Map<String, dynamic> ukm;

  const DetailUkmPage({super.key, required this.ukm});

  @override
  State<DetailUkmPage> createState() => _DetailUkmPageState();
}

class _DetailUkmPageState extends State<DetailUkmPage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isEditMode = false;
  bool _isSaving = false;

  // Controllers for edit mode
  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _deskripsiController;
  late TextEditingController _passwordController;

  String? _newLogoUrl;
  late TabController _tabController;

  // Password states
  bool _obscurePassword = true;
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  // Data states from database
  List<Map<String, dynamic>> _periodeList = [];
  List<Map<String, dynamic>> _anggotaList = [];
  List<Map<String, dynamic>> _pertemuanList = [];
  List<Map<String, dynamic>> _eventList = [];
  List<Map<String, dynamic>> _dokumenProposalList = [];
  List<Map<String, dynamic>> _dokumenLpjList = [];
  bool _isLoadingData = false;
  Map<String, dynamic>? _currentPeriode;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.ukm['nama_ukm']);
    _emailController = TextEditingController(text: widget.ukm['email']);
    _deskripsiController = TextEditingController(
      text: widget.ukm['description'],
    );
    _passwordController = TextEditingController();
    _tabController = TabController(length: 5, vsync: this);
    _loadUkmData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _deskripsiController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_namaController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama UKM dan Email harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password if changed
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password minimal 8 karakter'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!_hasUppercase) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password harus mengandung minimal 1 huruf kapital'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!_hasNumber) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password harus mengandung minimal 1 angka'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!_hasSymbol) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password harus mengandung minimal 1 simbol (!@#\$%^&*)',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final updateData = {
        'nama_ukm': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'description': _deskripsiController.text.trim(),
      };

      if (_newLogoUrl != null) {
        updateData['logo'] = _newLogoUrl!;
      }

      // Update password in Supabase Auth if changed
      if (_passwordController.text.isNotEmpty) {
        try {
          await _supabase.auth.admin.updateUserById(
            widget.ukm['user_id'],
            attributes: AdminUserAttributes(password: _passwordController.text),
          );
        } catch (e) {
          // If admin API not available, show message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Password tidak dapat diubah. Hubungi super admin.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      await _supabase
          .from('ukm')
          .update(updateData)
          .eq('id_ukm', widget.ukm['id_ukm']);

      if (mounted) {
        // Update local data
        widget.ukm['nama_ukm'] = _namaController.text.trim();
        widget.ukm['email'] = _emailController.text.trim();
        widget.ukm['description'] = _deskripsiController.text.trim();
        if (_newLogoUrl != null) {
          widget.ukm['logo'] = _newLogoUrl;
        }

        setState(() {
          _isEditMode = false;
          _isSaving = false;
          _newLogoUrl = null;
          _passwordController.clear();
          _hasMinLength = false;
          _hasUppercase = false;
          _hasNumber = false;
          _hasSymbol = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _passwordController.text.isNotEmpty
                  ? 'Data UKM dan password berhasil diperbarui'
                  : 'Data UKM berhasil diperbarui',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile == null) return;

      Uint8List fileBytes;
      String? extension;

      if (!kIsWeb) {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
          compressFormat: ImageCompressFormat.jpg,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Logo UKM',
              toolbarColor: const Color(0xFF4169E1),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Crop Logo UKM', aspectRatioLockEnabled: true),
          ],
        );

        if (croppedFile == null) return;

        fileBytes = await croppedFile.readAsBytes();
        extension = croppedFile.path.split('.').last.toLowerCase();
      } else {
        fileBytes = await pickedFile.readAsBytes();
        extension = pickedFile.name.split('.').last.toLowerCase();
      }

      if (fileBytes.length > 10 * 1024 * 1024) {
        throw 'Ukuran file terlalu besar. Maksimal 10MB';
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ukm_$timestamp.$extension';

      String contentType;
      switch (extension) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      await _supabase.storage
          .from('ukm-logos')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final imageUrl = _supabase.storage
          .from('ukm-logos')
          .getPublicUrl(fileName);

      setState(() {
        _newLogoUrl = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Logo berhasil diupload. Klik Simpan untuk menyimpan perubahan.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUkmData() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);

    try {
      final idUkm = widget.ukm['id_ukm'];

      // Load current periode
      final currentPeriodeId = widget.ukm['id_current_periode'];
      if (currentPeriodeId != null) {
        final periodeData = await _supabase
            .from('periode_ukm')
            .select()
            .eq('id_periode', currentPeriodeId)
            .maybeSingle();
        if (periodeData != null) {
          _currentPeriode = periodeData;
        }
      }

      // Load all periode
      final periodeData = await _supabase
          .from('periode_ukm')
          .select()
          .eq('id_ukm', idUkm)
          .order('create_at', ascending: false);
      _periodeList = List<Map<String, dynamic>>.from(periodeData);

      // Load anggota (followers) with user details
      final anggotaData = await _supabase
          .from('user_halaman_ukm')
          .select('*, users(*)')
          .eq('id_ukm', idUkm)
          .eq('status', 'active')
          .order('follow', ascending: false);
      _anggotaList = List<Map<String, dynamic>>.from(anggotaData);

      // Load pertemuan
      final pertemuanData = await _supabase
          .from('pertemuan')
          .select('*, periode_ukm(nama_periode)')
          .eq('id_ukm', idUkm)
          .order('tanggal_pertemuan', ascending: false);
      _pertemuanList = List<Map<String, dynamic>>.from(pertemuanData);

      // Load events
      final eventData = await _supabase
          .from('events')
          .select('*, periode_ukm(nama_periode), users(username)')
          .eq('id_ukm', idUkm)
          .order('tanggal_mulai', ascending: false);
      _eventList = List<Map<String, dynamic>>.from(eventData);

      // Load dokumen proposal
      final proposalData = await _supabase
          .from('event_proposal')
          .select('*, events(nama_event), users(username)')
          .eq('id_ukm', idUkm)
          .order('tanggal_pengajuan', ascending: false);
      _dokumenProposalList = List<Map<String, dynamic>>.from(proposalData);

      // Load dokumen LPJ
      final lpjData = await _supabase
          .from('event_lpj')
          .select('*, events(nama_event), users(username)')
          .eq('id_ukm', idUkm)
          .order('tanggal_pengajuan', ascending: false);
      _dokumenLpjList = List<Map<String, dynamic>>.from(lpjData);

      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data UKM: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Detail UKM',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () => setState(() => _isEditMode = true),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit UKM',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: Column(
              children: [
                isDesktop
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildModernTabButton(
                                icon: Icons.info_outline,
                                label: 'Info UKM',
                                index: 0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernTabButton(
                                icon: Icons.people_outline,
                                label: 'Peserta',
                                index: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernTabButton(
                                icon: Icons.event_note_outlined,
                                label: 'Pertemuan',
                                index: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernTabButton(
                                icon: Icons.celebration_outlined,
                                label: 'Event',
                                index: 3,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernTabButton(
                                icon: Icons.folder_outlined,
                                label: 'Dokumen',
                                index: 4,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            _buildModernTabButton(
                              icon: Icons.info_outline,
                              label: 'Info UKM',
                              index: 0,
                            ),
                            const SizedBox(width: 8),
                            _buildModernTabButton(
                              icon: Icons.people_outline,
                              label: 'Peserta',
                              index: 1,
                            ),
                            const SizedBox(width: 8),
                            _buildModernTabButton(
                              icon: Icons.event_note_outlined,
                              label: 'Pertemuan',
                              index: 2,
                            ),
                            const SizedBox(width: 8),
                            _buildModernTabButton(
                              icon: Icons.celebration_outlined,
                              label: 'Event',
                              index: 3,
                            ),
                            const SizedBox(width: 8),
                            _buildModernTabButton(
                              icon: Icons.folder_outlined,
                              label: 'Dokumen',
                              index: 4,
                            ),
                          ],
                        ),
                      ),
                Divider(height: 1, color: Colors.grey[200]),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildModernInfoUkmTab(isDesktop),
                _buildPesertaTab(),
                _buildPertemuanTab(),
                _buildEventTab(),
                _buildDokumenTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _tabController.index == index;

    return InkWell(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4169E1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoUkmTab(bool isDesktop) {
    final logoUrl = _newLogoUrl ?? widget.ukm['logo'];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 24,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card with Logo and Basic Info
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4169E1).withOpacity(0.1),
                  const Color(0xFF5B7FE8).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4169E1).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                // Logo with Upload Button
                Stack(
                  children: [
                    Container(
                      width: isDesktop ? 140 : 120,
                      height: isDesktop ? 140 : 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4169E1).withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: logoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(logoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: logoUrl == null
                          ? Icon(
                              Icons.groups_rounded,
                              size: isDesktop ? 70 : 60,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                    if (_isEditMode)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _uploadLogo,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4169E1,
                                  ).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // UKM Name
                Text(
                  widget.ukm['nama_ukm'] ?? 'Nama UKM',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1a1a1a),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Email with Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.ukm['email'] ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Detailed Information Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Informasi Detail',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nama UKM Field
                _buildModernInfoField(
                  icon: Icons.groups_outlined,
                  label: 'Nama UKM',
                  value: widget.ukm['nama_ukm'],
                  controller: _isEditMode ? _namaController : null,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 20),

                // Email Field
                _buildModernInfoField(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: widget.ukm['email'],
                  controller: _isEditMode ? _emailController : null,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 20),

                // Deskripsi Field
                _buildModernInfoField(
                  icon: Icons.description_outlined,
                  label: 'Deskripsi',
                  value: widget.ukm['description'] ?? '-',
                  controller: _isEditMode ? _deskripsiController : null,
                  maxLines: 4,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 20),

                // Created Date Field
                _buildModernInfoField(
                  icon: Icons.calendar_today_outlined,
                  label: 'Dibuat Pada',
                  value: _formatDate(widget.ukm['create_at']),
                  controller: null,
                  isDesktop: isDesktop,
                ),

                // Password Field (only in edit mode)
                if (_isEditMode) ...[
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 24),

                  // Password Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ubah Password',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kosongkan jika tidak ingin mengubah password',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Input Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: const Color(0xFF4169E1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Password Baru',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: (value) {
                          setState(() {
                            _hasMinLength = value.length >= 8;
                            _hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
                            _hasNumber = RegExp(r'[0-9]').hasMatch(value);
                            _hasSymbol = RegExp(r'[!@#\$%^&*]').hasMatch(value);
                          });
                        },
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Minimal 8 karakter',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4169E1),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Password Requirements
                  if (_passwordController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password harus mengandung:',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPasswordRequirement(
                            'Minimal 8 karakter',
                            _hasMinLength,
                          ),
                          _buildPasswordRequirement(
                            '1 huruf kapital',
                            _hasUppercase,
                          ),
                          _buildPasswordRequirement('1 angka', _hasNumber),
                          _buildPasswordRequirement(
                            '1 simbol (!@#\$%^&*)',
                            _hasSymbol,
                          ),
                        ],
                      ),
                    ),
                ],

                // Action Buttons (if edit mode)
                if (_isEditMode) ...[
                  const SizedBox(height: 32),
                  _buildModernActionButtons(isDesktop),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoField({
    required IconData icon,
    required String label,
    required String? value,
    required bool isDesktop,
    TextEditingController? controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF4169E1)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        controller != null
            ? TextFormField(
                controller: controller,
                maxLines: maxLines,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: maxLines > 1 ? 16 : 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4169E1),
                      width: 2,
                    ),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: maxLines > 1 ? 16 : 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  value ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ],
    );
  }

  Widget _buildModernActionButtons(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSaving
                ? null
                : () {
                    setState(() {
                      _isEditMode = false;
                      _namaController.text = widget.ukm['nama_ukm'];
                      _emailController.text = widget.ukm['email'];
                      _deskripsiController.text =
                          widget.ukm['description'] ?? '';
                      _newLogoUrl = null;
                      _passwordController.clear();
                      _hasMinLength = false;
                      _hasUppercase = false;
                      _hasNumber = false;
                      _hasSymbol = false;
                      _obscurePassword = true;
                    });
                  },
            icon: const Icon(Icons.close, size: 18),
            label: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 14),
              side: BorderSide(color: Colors.grey[300]!),
              foregroundColor: Colors.grey[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 14),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isMet ? Colors.green.withOpacity(0.1) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isMet ? Colors.green : Colors.grey[400]!,
                width: 1.5,
              ),
            ),
            child: isMet
                ? const Icon(Icons.check, size: 12, color: Colors.green)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isMet ? Colors.green[700] : Colors.grey[600],
                fontWeight: isMet ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedProfileCard(bool isDesktop) {
    final logoUrl = _newLogoUrl ?? widget.ukm['logo'];

    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo/Photo - Centered
          Center(
            child: Stack(
              children: [
                Container(
                  width: isDesktop ? 120 : 100,
                  height: isDesktop ? 120 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    image: logoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(logoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: logoUrl == null
                      ? Icon(
                          Icons.groups,
                          size: isDesktop ? 60 : 50,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
                if (_isEditMode)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadLogo,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4169E1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Informasi UKM Title
          Text(
            'Informasi UKM',
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Info Rows
          _buildInfoRow(
            icon: Icons.groups_outlined,
            label: 'Nama UKM',
            value: widget.ukm['nama_ukm'],
            isDesktop: isDesktop,
            controller: _isEditMode ? _namaController : null,
          ),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: widget.ukm['email'],
            isDesktop: isDesktop,
            controller: _isEditMode ? _emailController : null,
          ),
          _buildInfoRow(
            icon: Icons.description_outlined,
            label: 'Deskripsi',
            value: widget.ukm['description'] ?? '-',
            isDesktop: isDesktop,
            controller: _isEditMode ? _deskripsiController : null,
            maxLines: 3,
          ),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Dibuat Pada',
            value: _formatDate(widget.ukm['create_at']),
            isDesktop: isDesktop,
            controller: null,
          ),

          // Action Buttons (if edit mode)
          if (_isEditMode) ...[
            const SizedBox(height: 24),
            _buildActionButtons(isDesktop),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String? value,
    required bool isDesktop,
    TextEditingController? controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4169E1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF4169E1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                controller != null
                    ? TextField(
                        controller: controller,
                        maxLines: maxLines,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
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
                            borderSide: const BorderSide(
                              color: Color(0xFF4169E1),
                              width: 2,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        value ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving
                ? null
                : () {
                    setState(() {
                      _isEditMode = false;
                      _namaController.text = widget.ukm['nama_ukm'];
                      _emailController.text = widget.ukm['email'];
                      _deskripsiController.text =
                          widget.ukm['description'] ?? '';
                      _newLogoUrl = null;
                    });
                  },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 14),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Simpan',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Tab Content Methods
  Widget _buildPesertaTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_anggotaList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Anggota',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada mahasiswa yang bergabung dengan UKM ini',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _anggotaList.length,
      itemBuilder: (context, index) {
        final anggota = _anggotaList[index];
        final user = anggota['users'] as Map<String, dynamic>?;
        final followDate = anggota['follow'] != null
            ? DateFormat(
                'dd MMM yyyy',
              ).format(DateTime.parse(anggota['follow']))
            : '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF4169E1),
              backgroundImage: user?['picture'] != null
                  ? NetworkImage(user!['picture'])
                  : null,
              child: user?['picture'] == null
                  ? Text(
                      (user?['username'] ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            title: Text(
              user?['username'] ?? 'Unknown',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'NIM: ${user?['nim'] ?? '-'}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Bergabung: $followDate',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                'Aktif',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPertemuanTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pertemuanList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Pertemuan',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada jadwal pertemuan untuk UKM ini',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pertemuanList.length,
      itemBuilder: (context, index) {
        final pertemuan = _pertemuanList[index];
        final tanggal = pertemuan['tanggal_pertemuan'] != null
            ? DateFormat(
                'EEEE, dd MMM yyyy',
                'id_ID',
              ).format(DateTime.parse(pertemuan['tanggal_pertemuan']))
            : '-';
        final waktu =
            pertemuan['jam_mulai'] != null && pertemuan['jam_akhir'] != null
            ? '${pertemuan['jam_mulai']} - ${pertemuan['jam_akhir']}'
            : '-';
        final periode = pertemuan['periode_ukm'] as Map<String, dynamic>?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4169E1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_note_rounded,
                        color: Color(0xFF4169E1),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pertemuan['topik'] ?? 'Pertemuan',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          if (periode != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              periode['nama_periode'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSimpleInfoRow(Icons.calendar_today, tanggal),
                const SizedBox(height: 6),
                _buildSimpleInfoRow(Icons.access_time, waktu),
                const SizedBox(height: 6),
                _buildSimpleInfoRow(
                  Icons.location_on,
                  pertemuan['lokasi'] ?? '-',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_eventList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.celebration, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Event',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada event yang dibuat oleh UKM ini',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventList.length,
      itemBuilder: (context, index) {
        final event = _eventList[index];
        final tanggalMulai = event['tanggal_mulai'] != null
            ? DateFormat(
                'dd MMM yyyy',
              ).format(DateTime.parse(event['tanggal_mulai']))
            : '-';
        final periode = event['periode_ukm'] as Map<String, dynamic>?;
        final status = event['status'] == true ? 'Aktif' : 'Selesai';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['nama_event'] ?? 'Event',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          if (periode != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              periode['nama_periode'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: event['status'] == true
                            ? Colors.green[50]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: event['status'] == true
                              ? Colors.green[200]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: event['status'] == true
                              ? Colors.green[700]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSimpleInfoRow(Icons.calendar_today, tanggalMulai),
                const SizedBox(height: 6),
                _buildSimpleInfoRow(Icons.location_on, event['lokasi'] ?? '-'),
                if (event['max_participant'] != null) ...[
                  const SizedBox(height: 6),
                  _buildSimpleInfoRow(
                    Icons.people,
                    'Maks ${event['max_participant']} peserta',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDokumenTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    final allDokumen = [
      ..._dokumenProposalList.map((d) => {...d, 'type': 'proposal'}),
      ..._dokumenLpjList.map((d) => {...d, 'type': 'lpj'}),
    ];

    if (allDokumen.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Dokumen',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada proposal atau LPJ yang diajukan',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allDokumen.length,
      itemBuilder: (context, index) {
        final dokumen = allDokumen[index];
        final isProposal = dokumen['type'] == 'proposal';
        final eventName =
            (dokumen['events'] as Map<String, dynamic>?)?['nama_event'] ??
            'Event';
        final tanggal = dokumen['tanggal_pengajuan'] != null
            ? DateFormat(
                'dd MMM yyyy HH:mm',
              ).format(DateTime.parse(dokumen['tanggal_pengajuan']))
            : '-';
        final status = dokumen['status'] ?? 'menunggu';

        Color statusColor;
        String statusLabel;
        switch (status) {
          case 'disetujui':
            statusColor = Colors.green;
            statusLabel = 'Disetujui';
            break;
          case 'ditolak':
            statusColor = Colors.red;
            statusLabel = 'Ditolak';
            break;
          case 'revisi':
            statusColor = Colors.orange;
            statusLabel = 'Revisi';
            break;
          default:
            statusColor = Colors.blue;
            statusLabel = 'Menunggu';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isProposal
                              ? [
                                  const Color(0xFF4169E1),
                                  const Color(0xFF5B7FE8),
                                ]
                              : [
                                  const Color(0xFF10B981),
                                  const Color(0xFF059669),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isProposal
                            ? Icons.description_rounded
                            : Icons.assignment_turned_in_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isProposal ? 'Proposal' : 'LPJ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            eventName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSimpleInfoRow(Icons.calendar_today, 'Diajukan: $tanggal'),
                if (dokumen['catatan_admin'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dokumen['catatan_admin'],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
