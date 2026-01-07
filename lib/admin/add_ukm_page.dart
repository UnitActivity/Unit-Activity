import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart' as mobile_cropper;
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
  Uint8List? _imageBytes;
  String? _imageExtension;

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

      // Store image bytes and extension for later upload
      setState(() {
        _imageBytes = fileBytes;
        _imageExtension = extension;
        _selectedImageUrl = 'selected'; // Temporary marker
        _isUploading = false;
      });

      return 'selected'; // Indicate image is selected
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<String?> _uploadLogoWithName(
    String namaUkm,
    Uint8List fileBytes,
    String extension,
  ) async {
    try {
      // Format: ukm_namaUKM.extension (lowercase, no spaces)
      final sanitizedName = namaUkm.toLowerCase().replaceAll(' ', '_');
      final fileName = 'ukm_$sanitizedName.$extension';

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

      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error upload logo: $e'),
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

      // Check if email already exists in admin table
      final existingAdmin = await _supabase
          .from('admin')
          .select('email_admin')
          .eq('email_admin', email)
          .maybeSingle();

      if (existingAdmin != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email sudah terdaftar sebagai admin'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Hash password using SHA-256
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      print('🔐 Creating admin with role UKM...');

      // 1. Create entry in admin table with role "UKM"
      final adminResponse = await _supabase
          .from('admin')
          .insert({
            'username_admin': name,
            'email_admin': email,
            'password': hashedPassword,
            'role': 'UKM',
            'status': 'active',
            'create_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final adminId = adminResponse['id_admin'] as String;
      print('✅ Admin created with ID: $adminId');

      // 2. Upload logo if selected
      String? logoUrl;
      if (_imageBytes != null && _imageExtension != null) {
        print('📤 Uploading logo...');
        logoUrl = await _uploadLogoWithName(
          name,
          _imageBytes!,
          _imageExtension!,
        );
        if (logoUrl != null) {
          print('✅ Logo uploaded: $logoUrl');
        }
      }

      // 3. Create entry in ukm table linked to admin
      print('🏫 Creating UKM entry...');
      await _supabase.from('ukm').insert({
        'nama_ukm': name,
        'email': email,
        'description': description.isEmpty ? null : description,
        'logo': logoUrl,
        'id_admin': adminId,
        'create_at': DateTime.now().toIso8601String(),
      });

      print('✅ UKM created successfully!');

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('UKM "$name" berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating UKM: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan UKM: $e'),
            backgroundColor: Colors.red,
          ),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Tambah UKM',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : (isDesktop ? 48 : 24),
          vertical: isMobile ? 16 : 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: isMobile ? 18 : 20,
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Lengkapi form di bawah untuk menambahkan UKM baru',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Logo UKM Section
              _buildSectionCard(
                title: 'Logo UKM',
                icon: Icons.image_outlined,
                children: [_buildImageUpload()],
              ),
              const SizedBox(height: 20),

              // Informasi Dasar Section
              _buildSectionCard(
                title: 'Informasi Dasar',
                icon: Icons.info_outline,
                children: [
                  _buildTextField(
                    label: 'Nama UKM',
                    controller: _nameController,
                    hint: 'Contoh: BEM Fakultas Teknik',
                    icon: Icons.groups_outlined,
                    required: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama UKM wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Deskripsi',
                    controller: _descriptionController,
                    hint: 'Jelaskan tentang UKM ini (opsional)',
                    icon: Icons.description_outlined,
                    required: false,
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Informasi Akun Section
              _buildSectionCard(
                title: 'Informasi Akun',
                icon: Icons.account_circle_outlined,
                children: [
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'email@example.com',
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
                  const SizedBox(height: 20),
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
                        size: 20,
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
                  SizedBox(height: isMobile ? 12 : 16),

                  // Password Requirements
                  Container(
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password harus mengandung:',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 11 : 12,
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
              ),
              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return Center(
      child: GestureDetector(
        onTap: _isUploading
            ? null
            : () async {
                final url = await _uploadImage();
                if (url != null) {
                  setState(() => _selectedImageUrl = url);
                }
              },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _imageBytes != null
                  ? const Color(0xFF4169E1)
                  : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isUploading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Uploading...'),
                    ],
                  ),
                )
              : _imageBytes != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _imageBytes!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4169E1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload Logo',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG (Max 5MB)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18),
            label: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
            onPressed: _isLoading ? null : _addUkm,
            icon: _isLoading
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
              _isLoading ? 'Menyimpan...' : 'Simpan UKM',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (required)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 13,
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
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, color: Colors.grey[600], size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
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
