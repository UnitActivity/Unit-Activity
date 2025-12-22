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

  String? _newLogoUrl;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.ukm['nama_ukm']);
    _emailController = TextEditingController(text: widget.ukm['email']);
    _deskripsiController = TextEditingController(
      text: widget.ukm['description'],
    );
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _deskripsiController.dispose();
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
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data UKM berhasil diperbarui'),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail UKM',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isEditMode)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: () => setState(() => _isEditMode = true),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: Text(
                  'Edit',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4169E1),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Container(
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
            children: [
              // Button-style Tab Selector
              Container(
                padding: EdgeInsets.all(isDesktop ? 20 : 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              icon: Icons.info_outline,
                              label: 'Info UKM',
                              index: 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTabButton(
                              icon: Icons.people_outline,
                              label: 'Peserta',
                              index: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTabButton(
                              icon: Icons.event_note_outlined,
                              label: 'Pertemuan',
                              index: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTabButton(
                              icon: Icons.celebration_outlined,
                              label: 'Event',
                              index: 3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTabButton(
                              icon: Icons.folder_outlined,
                              label: 'Dokumen',
                              index: 4,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTabButton(
                              icon: Icons.info_outline,
                              label: 'Info UKM',
                              index: 0,
                            ),
                            const SizedBox(width: 8),
                            _buildTabButton(
                              icon: Icons.people_outline,
                              label: 'Peserta',
                              index: 1,
                            ),
                            const SizedBox(width: 8),
                            _buildTabButton(
                              icon: Icons.event_note_outlined,
                              label: 'Pertemuan',
                              index: 2,
                            ),
                            const SizedBox(width: 8),
                            _buildTabButton(
                              icon: Icons.celebration_outlined,
                              label: 'Event',
                              index: 3,
                            ),
                            const SizedBox(width: 8),
                            _buildTabButton(
                              icon: Icons.folder_outlined,
                              label: 'Dokumen',
                              index: 4,
                            ),
                          ],
                        ),
                      ),
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoUkmTab(isDesktop),
                    _buildPesertaTab(),
                    _buildPertemuanTab(),
                    _buildEventTab(),
                    _buildDokumenTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4169E1).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4169E1) : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF4169E1) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoUkmTab(bool isDesktop) {
    final logoUrl = _newLogoUrl ?? widget.ukm['logo'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
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
              const SizedBox(height: 32),

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
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Daftar Peserta UKM',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini menampilkan daftar anggota UKM (view-only)',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPertemuanTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Daftar Pertemuan',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini menampilkan daftar pertemuan UKM (view-only)',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Daftar Event',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini menampilkan daftar event UKM (view-only)',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDokumenTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Dokumen UKM',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini menampilkan dokumen UKM dengan preview dan komentar',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
