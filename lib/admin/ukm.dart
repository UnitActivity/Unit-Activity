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

class UkmPage extends StatefulWidget {
  const UkmPage({super.key});

  @override
  State<UkmPage> createState() => _UkmPageState();
}

class _UkmPageState extends State<UkmPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _sortBy = 'Urutkan';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  List<Map<String, dynamic>> _allUkm = [];
  bool _isLoading = true;
  int _totalUkm = 0;
  Set<String> _selectedUkm = {};

  // Column visibility settings
  Map<String, bool> _columnVisibility = {
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

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedUkm = _allUkm.map((u) => u['id_ukm'].toString()).toSet();
      } else {
        _selectedUkm.clear();
      }
    });
  }

  void _toggleUkmSelection(String ukmId) {
    setState(() {
      if (_selectedUkm.contains(ukmId)) {
        _selectedUkm.remove(ukmId);
      } else {
        _selectedUkm.add(ukmId);
      }
    });
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
            if (_selectedUkm.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: const Color(0xFF4169E1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedUkm.length} dipilih',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4169E1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _showDeleteConfirmation,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red,
                      tooltip: 'Hapus UKM',
                    ),
                  ],
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
            onPressed: _showAddUkmDialog,
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
                SizedBox(
                  width: 50,
                  child: Checkbox(
                    value:
                        _selectedUkm.length == _allUkm.length &&
                        _allUkm.isNotEmpty,
                    onChanged: _toggleSelectAll,
                    activeColor: const Color(0xFF4169E1),
                  ),
                ),
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
              final isSelected = _selectedUkm.contains(ukmId);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                color: isSelected
                    ? const Color(0xFF4169E1).withOpacity(0.05)
                    : null,
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleUkmSelection(ukmId),
                        activeColor: const Color(0xFF4169E1),
                      ),
                    ),
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
                              onPressed: () => _editUkm(ukm),
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              color: Colors.blue[700],
                              tooltip: 'Edit',
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
        final isSelected = _selectedUkm.contains(ukmId);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      const Color(0xFF4169E1).withOpacity(0.05),
                      const Color(0xFF4169E1).withOpacity(0.02),
                    ]
                  : [Colors.white, Colors.grey[50]!],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF4169E1) : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF4169E1).withOpacity(0.1)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 12 : 8,
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
                    // Checkbox with custom styling
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleUkmSelection(ukmId),
                        activeColor: const Color(0xFF4169E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            color: const Color(0xFF3B82F6),
                            onPressed: () => _editUkm(ukm),
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

  void _viewUkmDetail(Map<String, dynamic> ukm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detail UKM',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ukm['logo'] != null && ukm['logo'].toString().isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(ukm['logo']),
                      backgroundColor: const Color(0xFF4169E1).withOpacity(0.1),
                    ),
                  ),
                ),
              _buildDetailRow('Nama UKM', ukm['nama_ukm'] ?? '-'),
              _buildDetailRow('Email', ukm['email'] ?? '-'),
              _buildDetailRow('Deskripsi', ukm['description'] ?? '-'),
              _buildDetailRow('Dibuat', _formatDate(ukm['create_at'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.inter(
                color: const Color(0xFF4169E1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void _editUkm(Map<String, dynamic> ukm) {
    final nameController = TextEditingController(text: ukm['nama_ukm']);
    final emailController = TextEditingController(text: ukm['email']);
    final passwordController = TextEditingController();
    final descriptionController = TextEditingController(
      text: ukm['description'],
    );
    String? selectedImageUrl = ukm['logo'];
    bool obscurePassword = true;
    bool hasMinLength = false;
    bool hasUppercase = false;
    bool hasNumber = false;
    bool hasSymbol = false;
    bool isUploading = false;
    bool changePassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validatePassword(String password) {
            setDialogState(() {
              hasMinLength = password.length >= 8;
              hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
              hasNumber = RegExp(r'[0-9]').hasMatch(password);
              hasSymbol = RegExp(r'[!@#\$%^&*]').hasMatch(password);
            });
          }

          return AlertDialog(
            title: Text(
              'Edit UKM',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama UKM
                    Text(
                      'Nama UKM *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama UKM',
                        hintStyle: GoogleFonts.inter(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    Text(
                      'Email *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Masukkan email UKM',
                        hintStyle: GoogleFonts.inter(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Change Password Checkbox
                    CheckboxListTile(
                      title: Text(
                        'Ubah Password',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: changePassword,
                      onChanged: (value) {
                        setDialogState(() {
                          changePassword = value ?? false;
                          if (!changePassword) {
                            passwordController.clear();
                            hasMinLength = false;
                            hasUppercase = false;
                            hasNumber = false;
                            hasSymbol = false;
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    // Password (conditional)
                    if (changePassword) ...[
                      Text(
                        'Password Baru *',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        onChanged: validatePassword,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password baru',
                          hintStyle: GoogleFonts.inter(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPasswordRequirement(
                            'Minimal 8 karakter',
                            hasMinLength,
                          ),
                          _buildPasswordRequirement(
                            'Mengandung huruf kapital',
                            hasUppercase,
                          ),
                          _buildPasswordRequirement(
                            'Mengandung angka',
                            hasNumber,
                          ),
                          _buildPasswordRequirement(
                            'Mengandung simbol (!@#\$%^&*)',
                            hasSymbol,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Deskripsi
                    Text(
                      'Deskripsi',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Masukkan deskripsi UKM',
                        hintStyle: GoogleFonts.inter(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Logo Upload
                    Text(
                      'Logo UKM',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (selectedImageUrl != null &&
                              selectedImageUrl!.isNotEmpty)
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    selectedImageUrl!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 100,
                                        width: 100,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        setDialogState(() {
                                          isUploading = true;
                                        });
                                        try {
                                          final imageUrl =
                                              await _uploadImageFromPath('');
                                          if (imageUrl != null) {
                                            setDialogState(() {
                                              selectedImageUrl = imageUrl;
                                            });
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } finally {
                                          setDialogState(() {
                                            isUploading = false;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: Text(
                                        'Ganti',
                                        style: GoogleFonts.inter(fontSize: 12),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        setDialogState(() {
                                          selectedImageUrl = null;
                                        });
                                      },
                                      icon: const Icon(Icons.close, size: 16),
                                      label: Text(
                                        'Hapus',
                                        style: GoogleFonts.inter(fontSize: 12),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isUploading = true;
                                      });
                                      try {
                                        final imageUrl =
                                            await _uploadImageFromPath('');
                                        if (imageUrl != null) {
                                          setDialogState(() {
                                            selectedImageUrl = imageUrl;
                                          });
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } finally {
                                        setDialogState(() {
                                          isUploading = false;
                                        });
                                      }
                                    },
                              icon: isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_file, size: 18),
                              label: Text(
                                isUploading ? 'Mengupload...' : 'Pilih Gambar',
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4169E1),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Format: JPG, PNG, JPEG, WEBP',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                  if (nameController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nama UKM dan Email harus diisi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Validate email format
                  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                  if (!emailRegex.hasMatch(emailController.text.trim())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Format email tidak valid'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (changePassword) {
                    if (passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password harus diisi jika ingin diubah',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (!_isPasswordValid(passwordController.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password harus memenuhi semua persyaratan',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }

                  try {
                    Map<String, dynamic> updateData = {
                      'nama_ukm': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'description': descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      'logo': selectedImageUrl,
                    };

                    if (changePassword && passwordController.text.isNotEmpty) {
                      updateData['password'] = _hashPassword(
                        passwordController.text,
                      );
                    }

                    await _supabase
                        .from('ukm')
                        .update(updateData)
                        .eq('id_ukm', ukm['id_ukm']);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('UKM berhasil diupdate'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadUkm();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal mengupdate UKM: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Simpan',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Hapus',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${_selectedUkm.length} UKM yang dipilih?',
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
              await _performBulkDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Hapus Semua',
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
          SnackBar(
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

  Future<void> _performBulkDelete() async {
    try {
      for (String ukmId in _selectedUkm) {
        await _supabase.from('ukm').delete().eq('id_ukm', ukmId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedUkm.length} UKM berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedUkm.clear();
        });
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

  void _showAddUkmDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedImageUrl;
    bool obscurePassword = true;
    bool hasMinLength = false;
    bool hasUppercase = false;
    bool hasNumber = false;
    bool hasSymbol = false;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validatePassword(String password) {
            setDialogState(() {
              hasMinLength = password.length >= 8;
              hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
              hasNumber = RegExp(r'[0-9]').hasMatch(password);
              hasSymbol = RegExp(r'[!@#\$%^&*]').hasMatch(password);
            });
          }

          return AlertDialog(
            title: Text(
              'Tambah UKM',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama UKM
                    Text(
                      'Nama UKM *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama UKM',
                        hintStyle: GoogleFonts.inter(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    Text(
                      'Email *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Masukkan email UKM',
                        hintStyle: GoogleFonts.inter(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Text(
                      'Password *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      onChanged: validatePassword,
                      decoration: InputDecoration(
                        hintText: 'Masukkan password',
                        hintStyle: GoogleFonts.inter(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Password requirements
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPasswordRequirement(
                          'Minimal 8 karakter',
                          hasMinLength,
                        ),
                        _buildPasswordRequirement(
                          'Mengandung huruf kapital',
                          hasUppercase,
                        ),
                        _buildPasswordRequirement(
                          'Mengandung angka',
                          hasNumber,
                        ),
                        _buildPasswordRequirement(
                          'Mengandung simbol (!@#\$%^&*)',
                          hasSymbol,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi
                    Text(
                      'Deskripsi',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Masukkan deskripsi UKM',
                        hintStyle: GoogleFonts.inter(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Logo Upload
                    Text(
                      'Logo UKM',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (selectedImageUrl != null)
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    selectedImageUrl!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedImageUrl = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close, size: 16),
                                  label: Text(
                                    'Hapus gambar',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isUploading = true;
                                      });
                                      try {
                                        final imageUrl =
                                            await _uploadImageFromPath('');
                                        if (imageUrl != null) {
                                          setDialogState(() {
                                            selectedImageUrl = imageUrl;
                                          });
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } finally {
                                        setDialogState(() {
                                          isUploading = false;
                                        });
                                      }
                                    },
                              icon: isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_file, size: 18),
                              label: Text(
                                isUploading ? 'Mengupload...' : 'Pilih Gambar',
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4169E1),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Format: JPG, PNG, JPEG, WEBP',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                  if (nameController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty ||
                      passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Nama UKM, Email, dan Password harus diisi',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Validate email format
                  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                  if (!emailRegex.hasMatch(emailController.text.trim())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Format email tidak valid'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (!_isPasswordValid(passwordController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password harus memenuhi semua persyaratan',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    await _supabase.from('ukm').insert({
                      'nama_ukm': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'password': _hashPassword(passwordController.text),
                      'description': descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      'logo': selectedImageUrl,
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('UKM berhasil ditambahkan'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadUkm();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menambahkan UKM: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Tambah',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? Colors.green : Colors.grey[400],
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
