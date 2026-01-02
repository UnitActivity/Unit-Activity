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
      await _supabase.from('informasi').insert({
        'judul': _judulController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'gambar': _uploadedImagePath,
        'status': _selectedStatus,
        'id_ukm': _selectedUkmId != null ? _selectedUkmId : null,
        'id_periode': _selectedPeriodeId != null ? _selectedPeriodeId : null,
        'status_aktif': true,
      });

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informasi berhasil ditambahkan!'),
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
          ),
        ),
        title: Text(
          _currentStep == 0 ? 'Postingan baru' : 'Tambahkan keterangan',
          style: GoogleFonts.inter(
            fontSize: 18,
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
                fontSize: 16,
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
          const SizedBox(width: 8),
        ],
      ),
      body: _currentStep == 0 ? _buildImagePickerStep() : _buildDetailStep(),
    );
  }

  Widget _buildImagePickerStep() {
    if (_isUploadingImage) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
            ),
            const SizedBox(height: 24),
            Text(
              'Mengupload gambar...',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickAndUploadImage,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Ganti Gambar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih foto dari galeri',
                style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap untuk memilih gambar',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Preview gambar
          if (_uploadedImagePath != null)
            Container(
              height: 200,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  'Judul *',
                  _judulController,
                  'Masukkan judul postingan...',
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Deskripsi',
                  _deskripsiController,
                  'Tambahkan deskripsi...',
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  'Status *',
                  _selectedStatus,
                  ['Draft', 'Aktif', 'Arsip'],
                  (val) => setState(() => _selectedStatus = val!),
                ),
                const SizedBox(height: 16),
                _buildDropdownFromList(
                  'UKM',
                  _selectedUkmId,
                  widget.ukmList,
                  'id_ukm',
                  'nama_ukm',
                  (val) => setState(() => _selectedUkmId = val),
                ),
                const SizedBox(height: 16),
                _buildDropdownFromList(
                  'Periode',
                  _selectedPeriodeId,
                  widget.periodeList,
                  'id_periode',
                  'nama_periode',
                  (val) => setState(() => _selectedPeriodeId = val),
                ),
                const SizedBox(height: 24),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
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
            contentPadding: const EdgeInsets.all(12),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
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
            contentPadding: const EdgeInsets.all(12),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.inter(fontSize: 14)),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: 'Pilih $label (optional)',
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
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
            contentPadding: const EdgeInsets.all(12),
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
        ),
      ],
    );
  }
}
