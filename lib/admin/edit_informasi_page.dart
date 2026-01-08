import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class EditInformasiPage extends StatefulWidget {
  final Map<String, dynamic> informasi;
  final List<Map<String, dynamic>> ukmList;
  final List<Map<String, dynamic>> periodeList;

  const EditInformasiPage({
    super.key,
    required this.informasi,
    required this.ukmList,
    required this.periodeList,
  });

  @override
  State<EditInformasiPage> createState() => _EditInformasiPageState();
}

class _EditInformasiPageState extends State<EditInformasiPage> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  String? _uploadedImagePath;
  String? _oldImagePath;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  String _selectedStatus = 'Draft';
  String? _selectedUkmId;
  String? _selectedPeriodeId;

  @override
  void initState() {
    super.initState();
    // Load existing data
    _judulController.text = widget.informasi['judul'] ?? '';
    _deskripsiController.text = widget.informasi['deskripsi'] ?? '';
    _selectedStatus = widget.informasi['status'] ?? 'Draft';
    _selectedUkmId = widget.informasi['id_ukm']?.toString();
    _selectedPeriodeId = widget.informasi['id_periode']?.toString();
    _oldImagePath = widget.informasi['gambar'];
    _uploadedImagePath = widget.informasi['gambar'];
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploadingImage = true);

    try {
      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      Uint8List? imageBytes;

      if (kIsWeb) {
        // Web: Skip cropper, use original
        imageBytes = await pickedFile.readAsBytes();
      } else {
        // Mobile/Desktop: Use cropper
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressQuality: 85,
          maxWidth: 1080,
          maxHeight: 1080,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Gambar',
              toolbarColor: const Color(0xFF4169E1),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
                CropAspectRatioPreset.original,
              ],
            ),
            IOSUiSettings(
              title: 'Crop Gambar',
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
                CropAspectRatioPreset.original,
              ],
            ),
          ],
        );

        if (croppedFile == null) {
          setState(() => _isUploadingImage = false);
          return;
        }
        imageBytes = await File(croppedFile.path).readAsBytes();
      }

      // Upload to Supabase Storage
      final fileName = 'informasi_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('informasi-images')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      setState(() {
        _uploadedImagePath = fileName;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error upload gambar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateInformasi() async {
    if (_judulController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Judul harus diisi', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Delete old image if changed
      if (_oldImagePath != null &&
          _oldImagePath != _uploadedImagePath &&
          _uploadedImagePath != null) {
        try {
          await _supabase.storage.from('informasi-images').remove([
            _oldImagePath!,
          ]);
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      // Update informasi
      await _supabase
          .from('informasi')
          .update({
            'judul': _judulController.text.trim(),
            'deskripsi': _deskripsiController.text.trim(),
            'gambar': _uploadedImagePath,
            'status': _selectedStatus,
            'id_ukm': _selectedUkmId,
            'id_periode': _selectedPeriodeId,
            'update_at': DateTime.now().toIso8601String(),
          })
          .eq('id_informasi', widget.informasi['id_informasi']);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Informasi berhasil diperbarui!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black87,
              size: 20,
            ),
          ),
        ),
        title: Text(
          'Edit Informasi',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _updateInformasi,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  'Simpan',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF4169E1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            margin: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 20,
            ),
            child: Column(
              children: [
                // Image Section dengan design menarik
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                              color: const Color(0xFF4169E1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              color: Color(0xFF4169E1),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gambar Cover',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Tambahkan gambar menarik untuk informasi',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildImageSection(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                              color: const Color(0xFF4169E1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_note,
                              color: Color(0xFF4169E1),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Detail Informasi',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        'Judul Informasi',
                        _judulController,
                        'Masukkan judul yang menarik...',
                        maxLines: 1,
                        isRequired: true,
                        icon: Icons.title,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        'Deskripsi',
                        _deskripsiController,
                        'Tuliskan deskripsi lengkap tentang informasi ini...',
                        maxLines: 5,
                        icon: Icons.description,
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown(
                        'Status Publikasi',
                        _selectedStatus,
                        ['Draft', 'Aktif', 'Arsip'],
                        (val) => setState(() => _selectedStatus = val!),
                        icon: Icons.publish,
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownFromList(
                        'UKM Terkait',
                        _selectedUkmId,
                        widget.ukmList,
                        'id_ukm',
                        'nama_ukm',
                        (val) => setState(() => _selectedUkmId = val),
                        icon: Icons.groups,
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownFromList(
                        'Periode',
                        _selectedPeriodeId,
                        widget.periodeList,
                        'id_periode',
                        'nama_periode',
                        (val) => setState(() => _selectedPeriodeId = val),
                        icon: Icons.calendar_today,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_isUploadingImage) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4169E1).withOpacity(0.1),
              const Color(0xFF4169E1).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Mengupload gambar...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4169E1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mohon tunggu sebentar',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_uploadedImagePath != null) {
      return Stack(
        children: [
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _supabase.storage
                    .from('informasi-images')
                    .getPublicUrl(_uploadedImagePath!),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat gambar',
                          style: GoogleFonts.inter(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Overlay gradient untuk button
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Action buttons
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _buildImageActionButton(
                  icon: Icons.edit,
                  label: 'Ganti',
                  onTap: _pickAndUploadImage,
                  color: const Color(0xFF4169E1),
                ),
                const SizedBox(width: 8),
                _buildImageActionButton(
                  icon: Icons.delete_outline,
                  label: 'Hapus',
                  onTap: () {
                    setState(() {
                      _uploadedImagePath = null;
                    });
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Empty state
    return InkWell(
      onTap: _pickAndUploadImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4169E1).withOpacity(0.08),
              const Color(0xFF4169E1).withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4169E1).withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4169E1).withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_photo_alternate,
                  size: 50,
                  color: Color(0xFF4169E1),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Upload Gambar Cover',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4169E1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Klik untuk memilih gambar dari galeri',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Maksimal 5MB • JPG, PNG',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool isRequired = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: const Color(0xFF4169E1)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
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
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: const Color(0xFF4169E1)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
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
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items.map((item) {
            IconData? statusIcon;
            Color? statusColor;

            if (label.contains('Status')) {
              switch (item) {
                case 'Aktif':
                  statusIcon = Icons.check_circle;
                  statusColor = Colors.green;
                  break;
                case 'Draft':
                  statusIcon = Icons.edit_note;
                  statusColor = Colors.orange;
                  break;
                case 'Arsip':
                  statusIcon = Icons.archive;
                  statusColor = Colors.grey;
                  break;
              }
            }

            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  if (statusIcon != null) ...[
                    Icon(statusIcon, size: 18, color: statusColor),
                    const SizedBox(width: 10),
                  ],
                  Text(item, style: GoogleFonts.inter(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4169E1)),
        ),
      ],
    );
  }

  Widget _buildDropdownFromList(
    String label,
    String? value,
    List<Map<String, dynamic>> items,
    String idKey,
    String nameKey,
    Function(String?) onChanged, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: const Color(0xFF4169E1)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(Optional)',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: 'Pilih $label',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
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
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item[idKey].toString(),
              child: Text(
                item[nameKey] ?? '',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4169E1)),
        ),
      ],
    );
  }
}
