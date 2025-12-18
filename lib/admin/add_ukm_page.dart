import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart' as mobile_cropper;
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:typed_data';

class AddUkmPage extends StatefulWidget {
  const AddUkmPage({super.key});

  @override
  State<AddUkmPage> createState() => _AddUkmPageState();
}

class _AddUkmPageState extends State<AddUkmPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isUploading = false;
  String? _selectedImageUrl;

  // Password validation states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage() async {
    try {
      setState(() => _isUploading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile == null) {
        setState(() => _isUploading = false);
        return null;
      }

      Uint8List fileBytes;
      String? extension;

      if (!kIsWeb) {
        final mobile_cropper.CroppedFile?
        croppedFile = await mobile_cropper.ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
          compressFormat: mobile_cropper.ImageCompressFormat.jpg,
          uiSettings: [
            mobile_cropper.AndroidUiSettings(
              toolbarTitle: 'Crop Logo UKM',
              toolbarColor: const Color(0xFF4169E1),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: mobile_cropper.CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [mobile_cropper.CropAspectRatioPreset.square],
            ),
            mobile_cropper.IOSUiSettings(
              title: 'Crop Logo UKM',
              doneButtonTitle: 'Selesai',
              cancelButtonTitle: 'Batal',
              aspectRatioLockEnabled: true,
              aspectRatioPresets: [mobile_cropper.CropAspectRatioPreset.square],
            ),
          ],
        );

        if (croppedFile == null) {
          setState(() => _isUploading = false);
          return null;
        }

        fileBytes = await croppedFile.readAsBytes();
        extension = croppedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
          extension = 'jpg';
        }
      } else {
        // Web: Upload directly without crop
        fileBytes = await pickedFile.readAsBytes();
        if (pickedFile.mimeType != null) {
          final mimeType = pickedFile.mimeType!.toLowerCase();
          if (mimeType.contains('png')) {
            extension = 'png';
          } else if (mimeType.contains('webp')) {
            extension = 'webp';
          } else {
            extension = 'jpg';
          }
        } else {
          extension = 'jpg';
        }
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

      setState(() => _isUploading = false);
      return imageUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _addUkm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate password requirements
    final password = _passwordController.text;
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 8 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password harus mengandung minimal 1 huruf kapital'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password harus mengandung minimal 1 angka'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!RegExp(r'[!@#\$%^&*]').hasMatch(password)) {
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

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final description = _descriptionController.text.trim();

      // Check if email already exists
      final existingEmail = await _supabase
          .from('ukm')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (existingEmail != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email sudah terdaftar'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Create UKM in Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nama_ukm': name},
      );

      if (authResponse.user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membuat UKM'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Insert UKM data into ukm table
      await _supabase.from('ukm').insert({
        'id_ukm': authResponse.user!.id,
        'nama_ukm': name,
        'email': email,
        'password': authResponse.user!.id,
        'description': description.isEmpty ? null : description,
        'logo': _selectedImageUrl,
        'create_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UKM berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          'Tambah UKM',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 600 : double.infinity,
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Informasi UKM',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Isi formulir di bawah untuk menambahkan UKM baru',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logo Upload
                  _buildImageUpload(),
                  const SizedBox(height: 16),

                  // Nama UKM Field
                  _buildTextField(
                    label: 'Nama UKM',
                    controller: _nameController,
                    hint: 'Masukkan nama UKM',
                    icon: Icons.groups_outlined,
                    required: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama UKM wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'Masukkan email UKM',
                    icon: Icons.email_outlined,
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  _buildTextField(
                    label: 'Password',
                    controller: _passwordController,
                    hint: 'Minimal 8 karakter',
                    icon: Icons.lock_outline,
                    required: true,
                    obscureText: _obscurePassword,
                    onChanged: (value) {
                      setState(() {
                        _hasMinLength = value.length >= 8;
                        _hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
                        _hasNumber = RegExp(r'[0-9]').hasMatch(value);
                        _hasSymbol = RegExp(r'[!@#\$%^&*]').hasMatch(value);
                      });
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (value.length < 8) {
                        return 'Password minimal 8 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Password Requirements
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
                  _buildPasswordRequirement('1 huruf kapital', _hasUppercase),
                  _buildPasswordRequirement('1 angka', _hasNumber),
                  _buildPasswordRequirement('1 simbol (!@#\$%^&*)', _hasSymbol),
                  const SizedBox(height: 16),

                  // Description Field
                  _buildTextField(
                    label: 'Deskripsi',
                    controller: _descriptionController,
                    hint: 'Masukkan deskripsi UKM (opsional)',
                    icon: Icons.description_outlined,
                    required: false,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addUkm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4169E1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
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
                                  'Simpan',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Logo UKM',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              ' (Opsional)',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isUploading
              ? null
              : () async {
                  final url = await _uploadImage();
                  if (url != null) {
                    setState(() => _selectedImageUrl = url);
                  }
                },
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isUploading
                ? const Center(child: CircularProgressIndicator())
                : _selectedImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _selectedImageUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: 150,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Klik untuk upload logo',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool required,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            if (required)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            suffixIcon: suffixIcon,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: isMet ? Colors.green : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isMet ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Web Crop Dialog Widget
class _WebCropDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const _WebCropDialog({required this.imageBytes});

  @override
  State<_WebCropDialog> createState() => _WebCropDialogState();
}

class _WebCropDialogState extends State<_WebCropDialog> {
  final _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.crop, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Crop Logo UKM',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Crop Area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: _isCropping
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Memproses gambar...'),
                          ],
                        ),
                      )
                    : Crop(
                        image: widget.imageBytes,
                        controller: _cropController,
                        onCropped: (croppedData) {
                          Navigator.of(context).pop(croppedData);
                        },
                        aspectRatio: 1.0, // 1:1 square ratio
                        withCircleUi: false,
                        baseColor: Colors.grey.shade300,
                        maskColor: Colors.black.withOpacity(0.5),
                        radius: 8,
                        onMoved: (newRect, oldRect) {},
                        onStatusChanged: (status) {},
                        willUpdateScale: (newScale) => true,
                        cornerDotBuilder: (size, edgeAlignment) => Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4169E1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
              ),
            ),

            // Instructions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Geser dan zoom untuk menyesuaikan area crop',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCropping
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCropping
                          ? null
                          : () {
                              setState(() => _isCropping = true);
                              _cropController.crop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4169E1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isCropping
                          ? const SizedBox(
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
                              'Crop',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
}
