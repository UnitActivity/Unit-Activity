import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class AddInformasiPage extends StatefulWidget {
  final List<Map<String, dynamic>> ukmList;
  final List<Map<String, dynamic>> periodeList;

  const AddInformasiPage({
    super.key,
    required this.ukmList,
    required this.periodeList,
  });

  @override
  State<AddInformasiPage> createState() => _AddInformasiPageState();
}

class _AddInformasiPageState extends State<AddInformasiPage> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  int _currentStep = 0; // 0 = pilih gambar, 1 = isi detail
  String? _uploadedImagePath;
  bool _isUploadingImage = false;

  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  String _selectedStatus = 'Draft';
  String? _selectedUkmId;
  String? _selectedPeriodeId;

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
          ),
        );
      }
    }
  }

  Future<void> _saveInformasi() async {
    if (_judulController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Insert informasi
      final response = await _supabase
          .from('informasi')
          .insert({
            'judul': _judulController.text.trim(),
            'deskripsi': _deskripsiController.text.trim(),
            'gambar': _uploadedImagePath,
            'status': _selectedStatus,
            'id_ukm': _selectedUkmId != null ? _selectedUkmId : null,
            'id_periode': _selectedPeriodeId != null
                ? _selectedPeriodeId
                : null,
            'status_aktif': true,
          })
          .select()
          .single();

      // Create broadcast notification for all users
      final String title = _judulController.text.trim();
      final String desc = _deskripsiController.text.trim();
      final notifMessage = desc.isNotEmpty && desc.length > 100
          ? '${desc.substring(0, 100)}...'
          : desc.isNotEmpty
          ? desc
          : 'Informasi baru telah ditambahkan';

      await _supabase.from('notifikasi_broadcast').insert({
        'judul': '📢 Informasi Baru: $title',
        'pesan': notifMessage,
        'tipe': 'announcement',
        'id_informasi': response['id_informasi'],
        'pengirim': 'Admin',
      });

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Informasi berhasil ditambahkan dan notifikasi terkirim!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
          icon: Icon(
            _currentStep == 0 ? Icons.close : Icons.arrow_back,
            color: Colors.black87,
            size: isMobile ? 20 : 24,
          ),
        ),
        title: Text(
          _currentStep == 0 ? 'Postingan baru' : 'Tambahkan keterangan',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                (_currentStep == 0 &&
                    _uploadedImagePath != null &&
                    !_isUploadingImage)
                ? () => setState(() => _currentStep = 1)
                : (_currentStep == 1)
                ? _saveInformasi
                : null,
            child: Text(
              _currentStep == 0 ? 'Selanjutnya' : 'Bagikan',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color:
                    ((_currentStep == 0 &&
                            _uploadedImagePath != null &&
                            !_isUploadingImage) ||
                        _currentStep == 1)
                    ? const Color(0xFF4169E1)
                    : Colors.grey,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 4 : 8),
        ],
      ),
      body: _currentStep == 0 ? _buildImagePickerStep() : _buildDetailStep(),
    );
  }

  Widget _buildImagePickerStep() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_isUploadingImage) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              'Mengupload gambar...',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_uploadedImagePath != null) {
      return Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Center(
                child: Image.network(
                  _supabase.storage
                      .from('informasi-images')
                      .getPublicUrl(_uploadedImagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickAndUploadImage,
                    icon: Icon(Icons.refresh, size: isMobile ? 18 : 20),
                    label: Text(
                      'Ganti Gambar',
                      style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _pickAndUploadImage,
      child: Container(
        color: Colors.grey[50],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: isMobile ? 60 : 80,
                color: Colors.grey[400],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'Pilih foto dari galeri',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 16 : 18,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'Tap untuk memilih gambar',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStep() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Preview gambar
          if (_uploadedImagePath != null)
            Container(
              height: isMobile ? 150 : 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.network(
                _supabase.storage
                    .from('informasi-images')
                    .getPublicUrl(_uploadedImagePath!),
                fit: BoxFit.cover,
              ),
            ),

          // Form
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  'Judul *',
                  _judulController,
                  'Masukkan judul postingan...',
                  maxLines: 1,
                  isMobile: isMobile,
                ),
                SizedBox(height: isMobile ? 12 : 16),
                _buildTextField(
                  'Deskripsi',
                  _deskripsiController,
                  'Tambahkan deskripsi...',
                  maxLines: 4,
                  isMobile: isMobile,
                ),
                SizedBox(height: isMobile ? 12 : 16),
                _buildDropdown(
                  'Status *',
                  _selectedStatus,
                  ['Draft', 'Aktif', 'Arsip'],
                  (val) => setState(() => _selectedStatus = val!),
                  isMobile,
                ),
                SizedBox(height: isMobile ? 12 : 16),
                _buildDropdownFromList(
                  'UKM',
                  _selectedUkmId,
                  widget.ukmList,
                  'id_ukm',
                  'nama_ukm',
                  (val) => setState(() => _selectedUkmId = val),
                  isMobile,
                ),
                SizedBox(height: isMobile ? 12 : 16),
                _buildDropdownFromList(
                  'Periode',
                  _selectedPeriodeId,
                  widget.periodeList,
                  'id_periode',
                  'nama_periode',
                  (val) => setState(() => _selectedPeriodeId = val),
                  isMobile,
                ),
                SizedBox(height: isMobile ? 16 : 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool isMobile = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[400],
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
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
            contentPadding: EdgeInsets.all(isMobile ? 10 : 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
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
            contentPadding: EdgeInsets.all(isMobile ? 10 : 12),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
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
    Function(String?) onChanged,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: 'Pilih $label (optional)',
            hintStyle: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: isMobile ? 12 : 14,
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
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
            contentPadding: EdgeInsets.all(isMobile ? 10 : 12),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item[idKey].toString(),
              child: Text(
                item[nameKey] ?? '',
                style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
