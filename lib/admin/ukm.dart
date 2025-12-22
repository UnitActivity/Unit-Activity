import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'add_ukm_page.dart';
import 'detail_ukm_page.dart';

class UkmPage extends StatefulWidget {
  const UkmPage({super.key});

  @override
  State<UkmPage> createState() => _UkmPageState();
}

class _UkmPageState extends State<UkmPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final String _sortBy = 'Urutkan';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  List<Map<String, dynamic>> _allUkm = [];
  bool _isLoading = true;
  int _totalUkm = 0;

  // Column visibility settings
  final Map<String, bool> _columnVisibility = {
    'picture': true,
    'name': true,
    'email': true,
    'description': false,
    'createAt': false,
    'actions': true,
  };

  @override
  void initState() {
    super.initState();
    _loadUkm();
  }

  Future<void> _loadUkm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var queryBuilder = _supabase
          .from('ukm')
          .select('id_ukm, nama_ukm, email, description, logo, create_at');

      if (_searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'nama_ukm.ilike.%$_searchQuery%,email.ilike.%$_searchQuery%,description.ilike.%$_searchQuery%',
        );
      }

      final List<dynamic> allResponse = await queryBuilder;

      var sortedUkm = List<Map<String, dynamic>>.from(allResponse);
      if (_sortBy == 'Nama UKM') {
        sortedUkm.sort(
          (a, b) => (a['nama_ukm'] ?? '').toString().compareTo(
            (b['nama_ukm'] ?? '').toString(),
          ),
        );
      } else if (_sortBy == 'Email') {
        sortedUkm.sort(
          (a, b) => (a['email'] ?? '').toString().compareTo(
            (b['email'] ?? '').toString(),
          ),
        );
      } else if (_sortBy == 'Deskripsi') {
        sortedUkm.sort(
          (a, b) => (a['description'] ?? '').toString().compareTo(
            (b['description'] ?? '').toString(),
          ),
        );
      } else {
        sortedUkm.sort((a, b) {
          final dateA =
              DateTime.tryParse(a['create_at'] ?? '') ?? DateTime.now();
          final dateB =
              DateTime.tryParse(b['create_at'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
      }

      _totalUkm = sortedUkm.length;

      final startIndex = (_currentPage - 1) * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;
      final paginatedData = sortedUkm.sublist(
        startIndex,
        endIndex > sortedUkm.length ? sortedUkm.length : endIndex,
      );

      setState(() {
        _allUkm = paginatedData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading UKM: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get _totalPages =>
      _totalUkm == 0 ? 1 : (_totalUkm / _itemsPerPage).ceil();

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Helper function to hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Helper function to validate password
  bool _isPasswordValid(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    if (!RegExp(r'[!@#\$%^&*]').hasMatch(password)) return false;
    return true;
  }

  // Helper function to pick, crop, and upload image
  Future<String?> _uploadImageFromPath(String imagePath) async {
    try {
      // Step 1: Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Max quality, will compress after crop
      );

      if (pickedFile == null) return null;

      print('Original file: ${pickedFile.path}');
      print('Original name: ${pickedFile.name}');
      print('Original mimeType: ${pickedFile.mimeType}');

      // Step 2: Crop the image (skip on web, use cropper on mobile/desktop)
      Uint8List fileBytes;
      String? extension;

      if (!kIsWeb) {
        // Mobile/Desktop: Use image cropper
        try {
          final CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: pickedFile.path,
            compressQuality: 85,
            maxWidth: 1024,
            maxHeight: 1024,
            compressFormat: ImageCompressFormat.jpg,
            uiSettings: [
              // Android settings
              AndroidUiSettings(
                toolbarTitle: 'Crop Logo UKM',
                toolbarColor: const Color(0xFF4169E1),
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
                aspectRatioPresets: [
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9,
                ],
                hideBottomControls: false,
                showCropGrid: true,
                cropGridColor: Colors.white,
                cropFrameColor: const Color(0xFF4169E1),
                cropGridColumnCount: 3,
                cropGridRowCount: 3,
                backgroundColor: Colors.black,
              ),
              // iOS settings
              IOSUiSettings(
                title: 'Crop Logo UKM',
                doneButtonTitle: 'Selesai',
                cancelButtonTitle: 'Batal',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false,
                aspectRatioPickerButtonHidden: false,
                rotateButtonsHidden: false,
                aspectRatioPresets: [
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9,
                ],
              ),
            ],
          );

          if (croppedFile == null) {
            print('Cropping cancelled by user');
            return null;
          }

          print('Cropped file: ${croppedFile.path}');

          // Read cropped file bytes
          fileBytes = await croppedFile.readAsBytes();
          print('Cropped file size: ${fileBytes.length} bytes');

          // Detect extension from cropped file
          final pathExtension = croppedFile.path.split('.').last.toLowerCase();
          if (['jpg', 'jpeg', 'png', 'webp'].contains(pathExtension)) {
            extension = pathExtension;
          } else {
            extension = 'jpg';
          }
        } catch (e) {
          print('Cropping error: $e');
          throw 'Gagal melakukan crop gambar. Error: $e';
        }
      } else {
        // Web: Skip cropper, use original image
        print('Web platform: Using original image without crop');
        fileBytes = await pickedFile.readAsBytes();

        // Detect extension from original file
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
          final nameExt = pickedFile.name.split('.').last.toLowerCase();
          if (['jpg', 'jpeg', 'png', 'webp'].contains(nameExt)) {
            extension = nameExt;
          } else {
            extension = 'jpg';
          }
        }
      }

      print('Detected extension: $extension');

      // Validate file size (max 10MB)
      if (fileBytes.length > 10 * 1024 * 1024) {
        throw 'Ukuran file terlalu besar. Maksimal 10MB';
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ukm_$timestamp.$extension';

      print('Uploading to bucket: ukm-logos with filename: $fileName');

      // Determine content type
      String contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      try {
        // Upload to Supabase Storage
        final uploadPath = await _supabase.storage
            .from('ukm-logos')
            .uploadBinary(
              fileName,
              fileBytes,
              fileOptions: FileOptions(contentType: contentType, upsert: true),
            );

        print('Upload successful! Path: $uploadPath');

        // Get public URL
        final imageUrl = _supabase.storage
            .from('ukm-logos')
            .getPublicUrl(fileName);

        print('Public URL: $imageUrl');

        return imageUrl;
      } on StorageException catch (e) {
        print('StorageException: ${e.message}');
        print('StatusCode: ${e.statusCode}');

        if (e.statusCode == '403' || e.statusCode == '401') {
          throw 'Tidak memiliki izin untuk upload. Silakan login ulang atau hubungi administrator.';
        } else if (e.statusCode == '413') {
          throw 'File terlalu besar. Maksimal 10MB';
        } else {
          throw 'Gagal upload gambar: ${e.message}';
        }
      }
    } catch (e) {
      print('Error in _uploadImageFromPath: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '',
              style: GoogleFonts.inter(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildSearchAndFilterBar(isDesktop),
        const SizedBox(height: 20),

        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: CircularProgressIndicator(color: Color(0xFF4169E1)),
            ),
          )
        else if (_allUkm.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Belum ada UKM'
                        : 'Tidak ada hasil pencarian',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (isDesktop || isTablet)
          _buildDesktopTable(isDesktop)
        else
          _buildMobileList(),

        if (!_isLoading && _allUkm.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildPagination(),
        ],
      ],
    );
  }

  Widget _buildSearchAndFilterBar(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 400 : double.infinity,
            ),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _currentPage = 1;
                _loadUkm();
              },
              decoration: InputDecoration(
                hintText: 'Cari Nama UKM, Email atau Deskripsi...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 20,
                ),
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
                  borderSide: const BorderSide(
                    color: Color(0xFF4169E1),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),

        // Column Visibility Dropdown - only show on desktop
        if (isDesktop) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_column, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Kolom',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                ],
              ),
              tooltip: 'Pilih kolom yang ditampilkan',
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'Tampilkan Kolom',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'picture',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['picture'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('Nama UKM', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'email',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['email'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('Email', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'description',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['description'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('Deskripsi', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'createAt',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['createAt'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('Create At', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'actions',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['actions'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('Actions', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                setState(() {
                  _columnVisibility[value] = !_columnVisibility[value]!;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddUkmPage()),
              );
              // Refresh list if UKM was added
              if (result == true) {
                _loadUkm();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'Tambah UKM',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopTable(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                if (_columnVisibility['picture']!)
                  Expanded(
                    flex: 3,
                    child: Text(
                      'NAMA UKM',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                if (_columnVisibility['email']!)
                  Expanded(
                    flex: 3,
                    child: Text(
                      'EMAIL',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                if (_columnVisibility['description']!)
                  Expanded(
                    flex: 3,
                    child: Text(
                      'DESKRIPSI',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                if (_columnVisibility['createAt']!)
                  Expanded(
                    flex: 2,
                    child: Text(
                      'CREATE AT',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                if (_columnVisibility['actions']!)
                  SizedBox(
                    width: 120,
                    child: Text(
                      'ACTIONS',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allUkm.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final ukm = _allUkm[index];
              final ukmId = ukm['id_ukm'].toString();

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Name & Picture Column
                    if (_columnVisibility['picture']!)
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(
                                0xFF4169E1,
                              ).withOpacity(0.1),
                              backgroundImage:
                                  ukm['logo'] != null &&
                                      ukm['logo'].toString().isNotEmpty
                                  ? NetworkImage(ukm['logo'])
                                  : null,
                              child:
                                  ukm['logo'] == null ||
                                      ukm['logo'].toString().isEmpty
                                  ? Icon(
                                      Icons.groups,
                                      color: const Color(0xFF4169E1),
                                      size: 24,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ukm['nama_ukm'] ?? '-',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Email Column
                    if (_columnVisibility['email']!)
                      Expanded(
                        flex: 3,
                        child: Text(
                          ukm['email'] ?? '-',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Description Column
                    if (_columnVisibility['description']!)
                      Expanded(
                        flex: 3,
                        child: Text(
                          ukm['description'] ?? '-',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    // Create At Column
                    if (_columnVisibility['createAt']!)
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(ukm['create_at']),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    // Actions Column
                    if (_columnVisibility['actions']!)
                      SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _viewUkmDetail(ukm),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 20,
                              ),
                              color: Colors.grey[700],
                              tooltip: 'View',
                            ),
                            IconButton(
                              onPressed: () => _deleteUkm(ukmId),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: Colors.red[700],
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allUkm.length,
      itemBuilder: (context, index) {
        final ukm = _allUkm[index];
        final ukmId = ukm['id_ukm'].toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Section with Gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4169E1).withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar with border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4169E1).withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4169E1).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(
                          0xFF4169E1,
                        ).withOpacity(0.1),
                        backgroundImage:
                            ukm['logo'] != null &&
                                ukm['logo'].toString().isNotEmpty
                            ? NetworkImage(ukm['logo'])
                            : null,
                        child:
                            ukm['logo'] == null ||
                                ukm['logo'].toString().isEmpty
                            ? Icon(
                                Icons.groups,
                                color: const Color(0xFF4169E1),
                                size: 32,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ukm['nama_ukm'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (ukm['description'] != null &&
                              ukm['description'].toString().isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    ukm['description'],
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Divider with gradient
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey[300]!,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Info Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMobileInfoRow(
                      Icons.email_rounded,
                      ukm['email'] ?? '-',
                    ),
                    const SizedBox(height: 12),
                    _buildMobileInfoRow(
                      Icons.access_time_rounded,
                      'Dibuat: ${_formatDate(ukm['create_at'])}',
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons with modern design
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.visibility_rounded,
                            label: 'View',
                            color: const Color(0xFF6B7280),
                            onPressed: () => _viewUkmDetail(ukm),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey[300],
                          ),
                          _buildActionButton(
                            icon: Icons.delete_rounded,
                            label: 'Hapus',
                            color: const Color(0xFFEF4444),
                            onPressed: () => _deleteUkm(ukmId),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF4169E1).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF4169E1)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                  _loadUkm();
                }
              : null,
          icon: const Icon(Icons.chevron_left),
          color: const Color(0xFF4169E1),
          disabledColor: Colors.grey[400],
        ),

        const SizedBox(width: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Halaman $_currentPage dari $_totalPages',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),

        const SizedBox(width: 16),

        IconButton(
          onPressed: _currentPage < _totalPages
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                  _loadUkm();
                }
              : null,
          icon: const Icon(Icons.chevron_right),
          color: const Color(0xFF4169E1),
          disabledColor: Colors.grey[400],
        ),
      ],
    );
  }

  void _viewUkmDetail(Map<String, dynamic> ukm) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailUkmPage(ukm: ukm)),
    );
    // Refresh list if UKM was updated
    if (result == true) {
      _loadUkm();
    }
  }

  void _deleteUkm(String ukmId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Hapus',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus UKM ini?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(ukmId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String ukmId) async {
    try {
      await _supabase.from('ukm').delete().eq('id_ukm', ukmId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UKM berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUkm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus UKM: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
