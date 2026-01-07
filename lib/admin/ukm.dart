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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Modern Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 255, 255, 255),
                const Color(0xFF4169E1).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Manajemen UKM',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),

        // Stats Cards
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: _buildStatsCards(isDesktop),
        ),
        SizedBox(height: isMobile ? 16 : 24),

        // Search and Actions Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: _buildSearchAndFilterBar(isDesktop),
        ),
        const SizedBox(height: 20),

        // Content
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: _isLoading
              ? _buildLoadingState()
              : _allUkm.isEmpty
              ? _buildEmptyState()
              : isDesktop || isTablet
              ? _buildDesktopTable(isDesktop)
              : _buildMobileList(),
        ),

        if (!_isLoading && _allUkm.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: _buildPagination(),
          ),
        ],
        SizedBox(height: isMobile ? 16 : 24),
      ],
    );
  }

  Widget _buildStatsCards(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total UKM',
            value: '$_totalUkm',
            icon: Icons.groups_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
            ),
            isDesktop: isDesktop,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'UKM Aktif',
            value: '$_totalUkm',
            icon: Icons.check_circle_outline,
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
            ),
            isDesktop: isDesktop,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required bool isDesktop,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : (isDesktop ? 20 : 16)),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: isMobile ? 20 : 24),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 18 : (isDesktop ? 24 : 20),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
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
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF4169E1)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 64,
                color: const Color(0xFF4169E1).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum ada UKM'
                  : 'Tidak ada hasil pencarian',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Tambahkan UKM baru untuk memulai'
                  : 'Coba kata kunci lain',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isDesktop) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
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
      child: isMobile
          ? Column(
              children: [
                // Search Bar - Full Width
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      _searchQuery = value;
                      _currentPage = 1;
                      _loadUkm();
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari UKM...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[600],
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[600]),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _currentPage = 1;
                                });
                                _loadUkm();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Buttons Row - Below Search
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loadUkm,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4169E1),
                          side: const BorderSide(color: Color(0xFF4169E1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          'Refresh',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddUkmPage(),
                            ),
                          );
                          if (result == true) {
                            _loadUkm();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4169E1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(
                          'Tambah',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                // Search Bar
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        _searchQuery = value;
                        _currentPage = 1;
                        _loadUkm();
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama UKM, email atau deskripsi...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _currentPage = 1;
                                  });
                                  _loadUkm();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Refresh Button
                _buildIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh Data',
                  onPressed: _loadUkm,
                ),

                const SizedBox(width: 8),

                // Add Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddUkmPage(),
                      ),
                    );
                    if (result == true) {
                      _loadUkm();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 20 : 16,
                      vertical: isDesktop ? 16 : 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    isDesktop ? 'Tambah UKM' : 'Tambah',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: Colors.grey[700],
        tooltip: tooltip,
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildDesktopTable(bool isDesktop) {
    return Container(
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
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4169E1).withOpacity(0.05),
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
                Expanded(
                  flex: 3,
                  child: Text(
                    'NAMA UKM',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4169E1),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'EMAIL',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4169E1),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'DESKRIPSI',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4169E1),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text(
                      'AKSI',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4169E1),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Body
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allUkm.length,
            itemBuilder: (context, index) {
              final ukm = _allUkm[index];
              final ukmId = ukm['id_ukm'].toString();

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: index == _allUkm.length - 1
                          ? Colors.transparent
                          : Colors.grey[100]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Name & Picture Column
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4169E1).withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 22,
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
                                  ? const Icon(
                                      Icons.groups_rounded,
                                      color: Color(0xFF4169E1),
                                      size: 24,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
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
                    Expanded(
                      flex: 3,
                      child: Text(
                        ukm['email'] ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Description Column
                    Expanded(
                      flex: 4,
                      child: Text(
                        ukm['description'] ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    // Actions Column
                    SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF4169E1).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () => _viewUkmDetail(ukm),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 18,
                              ),
                              color: const Color(0xFF4169E1),
                              tooltip: 'Lihat Detail',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () => _deleteUkm(ukmId),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              color: Colors.red[700],
                              tooltip: 'Hapus',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allUkm.length,
      itemBuilder: (context, index) {
        final ukm = _allUkm[index];
        final ukmId = ukm['id_ukm'].toString();

        return Container(
          margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4169E1).withOpacity(0.05),
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
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4169E1).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: isMobile ? 24 : 28,
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
                                Icons.groups_rounded,
                                color: const Color(0xFF4169E1),
                                size: isMobile ? 24 : 28,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ukm['nama_ukm'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 15 : 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: isMobile ? 13 : 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: isMobile ? 4 : 6),
                              Expanded(
                                child: Text(
                                  ukm['email'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.grey[600],
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

              // Description
              if (ukm['description'] != null &&
                  ukm['description'].toString().isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 20,
                    vertical: isMobile ? 12 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Text(
                    ukm['description'],
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Actions
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewUkmDetail(ukm),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4169E1),
                          side: const BorderSide(color: Color(0xFF4169E1)),
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          Icons.visibility_outlined,
                          size: isMobile ? 16 : 18,
                        ),
                        label: Text(
                          'Lihat',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteUkm(ukmId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          Icons.delete_outline,
                          size: isMobile ? 16 : 18,
                        ),
                        label: Text(
                          'Hapus',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _buildPagination() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
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
      child: isMobile
          ? Column(
              children: [
                // Results Info - mobile
                Text(
                  'Halaman $_currentPage dari $_totalPages',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                // Page Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    _buildPageButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                        _loadUkm();
                      },
                    ),
                    const SizedBox(width: 12),
                    // Page Numbers
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4169E1).withOpacity(0.1),
                            const Color(0xFF4169E1).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4169E1).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4169E1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next Button
                    _buildPageButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                        });
                        _loadUkm();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Total UKM info
                Text(
                  '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage) > _totalUkm ? _totalUkm : (_currentPage * _itemsPerPage)} dari $_totalUkm',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Results Info
                Text(
                  'Menampilkan ${(_currentPage - 1) * _itemsPerPage + 1} - ${(_currentPage * _itemsPerPage) > _totalUkm ? _totalUkm : (_currentPage * _itemsPerPage)} dari $_totalUkm UKM',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),

                // Page Navigation
                Row(
                  children: [
                    // Previous Button
                    _buildPageButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                        _loadUkm();
                      },
                    ),

                    const SizedBox(width: 12),

                    // Page Numbers
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4169E1).withOpacity(0.1),
                            const Color(0xFF4169E1).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4169E1).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4169E1),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Next Button
                    _buildPageButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                        });
                        _loadUkm();
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFF4169E1).withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? const Color(0xFF4169E1).withOpacity(0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        color: enabled ? const Color(0xFF4169E1) : Colors.grey[400],
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  void _viewUkmDetail(Map<String, dynamic> ukm) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailUkmPage(ukm: ukm)),
    );
    if (result == true) {
      _loadUkm();
    }
  }

  void _deleteUkm(String ukmId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Konfirmasi Hapus',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus UKM ini? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
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
      // 1. Get id_admin from ukm table first
      final ukmData = await _supabase
          .from('ukm')
          .select('id_admin')
          .eq('id_ukm', ukmId)
          .single();

      final adminId = ukmData['id_admin'] as String?;

      // 2. Delete from ukm table
      await _supabase.from('ukm').delete().eq('id_ukm', ukmId);

      // 3. Delete from admin table if id_admin exists
      if (adminId != null) {
        await _supabase.from('admin').delete().eq('id_admin', adminId);
        print('✅ Deleted admin with ID: $adminId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UKM dan admin terkait berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUkm();
      }
    } catch (e) {
      print('❌ Error deleting UKM: $e');
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
