import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:unit_activity/services/event_service_new.dart';
import 'package:unit_activity/services/custom_auth_service.dart';
import 'package:unit_activity/services/file_upload_service.dart';
import 'package:unit_activity/ukm/detail_document_ukm_page.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailEventUkmPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic>? eventData;

  const DetailEventUkmPage({super.key, required this.eventId, this.eventData});

  @override
  State<DetailEventUkmPage> createState() => _DetailEventUkmPageState();
}

class _DetailEventUkmPageState extends State<DetailEventUkmPage>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final FileUploadService _fileUploadService = FileUploadService();

  // Use getter to always access the singleton instance
  CustomAuthService get _authService => CustomAuthService();

  Map<String, dynamic>? _event;
  List<Map<String, dynamic>> _dokumenProposal = [];
  List<Map<String, dynamic>> _dokumenLpj = [];
  List<Map<String, dynamic>> _pesertaList = [];
  List<Map<String, dynamic>> _filteredPesertaList = [];
  List<Map<String, dynamic>> _pendingParticipants = [];
  bool _isLoading = true;
  bool _isUploadingFile = false;
  int _jumlahPeserta = 0;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // QR Code state
  String? _currentQRCode;
  DateTime? _qrExpiresAt;
  bool _isQRActive = false;
  bool _autoRegenerateQR = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    // Check if user is authenticated
    if (!_authService.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus login terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    print(
      'User logged in: ${_authService.currentUserId} (${_authService.currentUserRole})',
    );
    await _loadEventDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEventDetails() async {
    setState(() => _isLoading = true);

    try {
      // Always fetch fresh data from database, especially after updates
      _event = await _eventService.getEventById(widget.eventId);

      // Load dokumen proposal dari event_documents
      final proposalData = await _supabase
          .from('event_documents')
          .select('*, users(username)')
          .eq('id_event', widget.eventId)
          .eq('document_type', 'proposal');
      _dokumenProposal = List<Map<String, dynamic>>.from(proposalData);

      // Load dokumen LPJ dari event_documents
      final lpjData = await _supabase
          .from('event_documents')
          .select('*, users(username)')
          .eq('id_event', widget.eventId)
          .eq('document_type', 'lpj');
      _dokumenLpj = List<Map<String, dynamic>>.from(lpjData);

      // Load peserta
      final pesertaData = await _supabase
          .from('absen_event')
          .select('*, users(username, email, nim)')
          .eq('id_event', widget.eventId)
          .neq('status', 'pending');
      _pesertaList = List<Map<String, dynamic>>.from(pesertaData);
      _filteredPesertaList = _pesertaList;
      _jumlahPeserta = _pesertaList.length;

      // Load pending participants
      final pendingData = await _eventService.getPendingParticipants(
        widget.eventId,
      );
      _pendingParticipants = pendingData;
    } catch (e) {
      print('Error loading event details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat detail event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadFile(String documentType) async {
    try {
      setState(() => _isUploadingFile = true);

      if (documentType == 'lpj') {
        // LPJ needs 2 files (laporan and keuangan)
        await _uploadLPJFiles();
      } else {
        // Proposal needs 1 file
        await _uploadProposalFile();
      }
    } catch (e) {
      print('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _uploadProposalFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final fileBytes = file.bytes!;
    final fileName = file.name;
    final fileSize = fileBytes.length;

    // Validate file size (max 10MB)
    if (fileSize > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran file maksimal 10 MB'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExtension = fileName.split('.').last;
    final storagePath = '${widget.eventId}/proposal_$timestamp.$fileExtension';

    // Upload to storage
    await _supabase.storage
        .from('event-proposals')
        .uploadBinary(storagePath, fileBytes);

    // Get current user/admin ID from custom auth
    // For UKM: this is id_admin (they login as admin with role 'ukm')
    // For regular users: this would be id_user
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated. Please login again.');
    }

    print('Current user ID: $userId');
    print('Current user role: ${_authService.currentUserRole}');

    // Insert to database (unified event_documents table)
    // IMPORTANT: UKM login as admin, so their ID is in admin table, not users table
    // Only include id_user if uploader is a regular user
    final insertData = {
      'document_type': 'proposal', // Unified table identifier
      'id_event': widget.eventId,
      'id_ukm': _event!['id_ukm'],
      'file_proposal': storagePath,
      'original_filename_proposal': fileName,
      'file_size_proposal': fileSize,
      'status': 'draft', // Draft status - requires manual submission
    };

    // Only add id_user for regular users (not for UKM/admin)
    // UKM are admins, their ID is in admin table, not users table
    if (_authService.isUser) {
      insertData['id_user'] = userId;
    }

    print('Inserting proposal with data: $insertData');
    await _supabase.from('event_documents').insert(insertData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Proposal berhasil diupload. Klik "Ajukan" untuk mengirim ke admin',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Reload data
    _loadEventDetails();
  }

  Future<void> _uploadLPJFiles() async {
    // Show dialog to inform user needs 2 files
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF4169E1),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Upload LPJ',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'LPJ memerlukan 2 dokumen:\n1. File Laporan\n2. File Keuangan\n\nAnda akan diminta untuk memilih kedua file.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Lanjutkan',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Pick laporan file
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih File Laporan',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF4169E1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final laporanResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
      allowMultiple: false,
    );

    if (laporanResult == null || laporanResult.files.isEmpty) return;

    // Pick keuangan file
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih File Keuangan',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF4169E1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final keuanganResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
      allowMultiple: false,
    );

    if (keuanganResult == null || keuanganResult.files.isEmpty) return;

    final laporanFile = laporanResult.files.first;
    final keuanganFile = keuanganResult.files.first;

    if (laporanFile.bytes == null || keuanganFile.bytes == null) return;

    final laporanBytes = laporanFile.bytes!;
    final keuanganBytes = keuanganFile.bytes!;
    final laporanSize = laporanBytes.length;
    final keuanganSize = keuanganBytes.length;

    // Validate file sizes
    if (laporanSize > 10 * 1024 * 1024 || keuanganSize > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran file maksimal 10 MB'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Generate unique filenames
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final laporanExt = laporanFile.name.split('.').last;
    final keuanganExt = keuanganFile.name.split('.').last;
    final laporanPath = '${widget.eventId}/lpj_laporan_$timestamp.$laporanExt';
    final keuanganPath =
        '${widget.eventId}/lpj_keuangan_$timestamp.$keuanganExt';

    // Upload files to storage
    await _supabase.storage
        .from('event-lpj')
        .uploadBinary(laporanPath, laporanBytes);
    await _supabase.storage
        .from('event-lpj')
        .uploadBinary(keuanganPath, keuanganBytes);

    // Get current user/admin ID from custom auth
    // For UKM: this is id_admin (they login as admin with role 'ukm')
    // For regular users: this would be id_user
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated. Please login again.');
    }

    print('Current user ID: $userId');
    print('Current user role: ${_authService.currentUserRole}');

    // Insert to database (unified event_documents table)
    // IMPORTANT: UKM login as admin, so their ID is in admin table, not users table
    // Only include id_user if uploader is a regular user
    final insertData = {
      'document_type': 'lpj', // Unified table identifier
      'id_event': widget.eventId,
      'id_ukm': _event!['id_ukm'],
      'file_laporan': laporanPath,
      'file_keuangan': keuanganPath,
      'original_filename_laporan': laporanFile.name,
      'original_filename_keuangan': keuanganFile.name,
      'file_size_laporan': laporanSize,
      'file_size_keuangan': keuanganSize,
      'status': 'draft', // Draft status - requires manual submission
    };

    // Only add id_user for regular users (not for UKM/admin)
    // UKM are admins, their ID is in admin table, not users table
    if (_authService.isUser) {
      insertData['id_user'] = userId;
    }

    print('Inserting LPJ with data: $insertData');
    await _supabase.from('event_documents').insert(insertData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'LPJ berhasil diupload. Klik "Ajukan" untuk mengirim ke admin',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Reload data
    _loadEventDetails();
  }

  Future<void> _deleteDocument(String documentId, String documentType) async {
    final confirmed = await showDialog<bool>(
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
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hapus Dokumen',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus dokumen ini?',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete from database (unified event_documents table)
      await _supabase
          .from('event_documents')
          .delete()
          .eq('id_document', documentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Dokumen berhasil dihapus',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      // Reload data
      _loadEventDetails();
    } catch (e) {
      print('Error deleting document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus dokumen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitDocument(String documentId, String documentType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Color(0xFF4169E1),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ajukan Dokumen',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin mengajukan dokumen ini ke admin? Setelah diajukan, dokumen tidak dapat dihapus atau diubah.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Ajukan',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Update status to 'menunggu' (unified event_documents table)
      await _supabase
          .from('event_documents')
          .update({
            'status': 'menunggu',
            'tanggal_pengajuan': DateTime.now().toIso8601String(),
          })
          .eq('id_document', documentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Dokumen berhasil diajukan ke admin',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      // Reload data
      _loadEventDetails();
    } catch (e) {
      print('Error submitting document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengajukan dokumen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterPeserta(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPesertaList = _pesertaList;
      } else {
        _filteredPesertaList = _pesertaList.where((peserta) {
          final user = peserta['users'] as Map<String, dynamic>?;
          final username = user?['username']?.toString().toLowerCase() ?? '';
          final nim = user?['nim']?.toString().toLowerCase() ?? '';
          final email = user?['email']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return username.contains(searchLower) ||
              nim.contains(searchLower) ||
              email.contains(searchLower);
        }).toList();
      }
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (e) {
      return '-';
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '-';
    }
  }

  Future<void> _showEditImageDialog() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        final file = result.files.first;
        
        setState(() => _isUploadingFile = true);

        try {
          // Upload image
          final imageUrl = await _fileUploadService.uploadImageFromBytes(
            fileBytes: file.bytes!,
            fileName: file.name,
            folder: 'events',
          );

          // Update event with new image
          await _eventService.updateEvent(
            eventId: widget.eventId,
            gambar: imageUrl,
          );

          // Force reload event details from database to get fresh data
          final freshEvent = await _eventService.getEventById(widget.eventId);
          
          // Update state with fresh data
          if (mounted) {
            setState(() {
              _event = freshEvent;
              _isUploadingFile = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gambar berhasil diupload!', style: GoogleFonts.inter()),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isUploadingFile = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal upload gambar: $e', style: GoogleFonts.inter()),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
          ? _buildErrorState()
          : CustomScrollView(
              slivers: [
                // Modern App Bar with Gradient
                _buildAppBar(isDesktop),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Header Card
                        _buildEventHeaderCard(isDesktop),
                        const SizedBox(height: 20),

                        // Stats Cards
                        _buildStatsCards(isDesktop),
                        const SizedBox(height: 20),

                        // Tab Bar
                        _buildTabBar(),
                      ],
                    ),
                  ),
                ),

                // Tab View Content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInfoTab(isDesktop),
                      _buildPesertaTab(isDesktop),
                      _buildQRAttendanceTab(isDesktop),
                      _buildDokumenTab(context, isDesktop),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar(bool isDesktop) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF4169E1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double collapseRatio =
              ((constraints.maxHeight - kToolbarHeight) /
                      (200 - kToolbarHeight))
                  .clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 56, bottom: 10),
            title: Opacity(
              opacity: 1 - collapseRatio,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _event!['nama_event'] ?? 'Detail Event',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Detail Event',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventHeaderCard(bool isDesktop) {
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
              // Event Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4169E1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.event_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),

              // Event Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _event!['nama_event'] ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 24 : 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          const Icon(
                            Icons.category_rounded,
                            size: 14,
                            color: Color(0xFF4169E1),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _event!['tipe_event'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4169E1),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDesktop) {
    final status = _event!['status_event'] ?? 'Aktif';
    final totalDokumen = _dokumenProposal.length + _dokumenLpj.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_outline,
            label: 'Peserta',
            value: _jumlahPeserta.toString(),
            gradient: const LinearGradient(
              colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
            ),
            isDesktop: isDesktop,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today_rounded,
            label: 'Status',
            value: status,
            gradient: LinearGradient(
              colors: status == 'Selesai'
                  ? [const Color(0xFF6B7280), const Color(0xFF9CA3AF)]
                  : [const Color(0xFF10B981), const Color(0xFF34D399)],
            ),
            isDesktop: isDesktop,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.bookmark_outline,
            label: 'Dokumen',
            value: totalDokumen.toString(),
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
            isDesktop: isDesktop,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
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
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF4169E1),
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(
            icon: Icon(Icons.info_outline_rounded, size: 20),
            text: 'Informasi',
          ),
          Tab(
            icon: Icon(Icons.people_outline_rounded, size: 20),
            text: 'Peserta',
          ),
          Tab(
            icon: Icon(Icons.qr_code_2_rounded, size: 20),
            text: 'QR Absensi',
          ),
          Tab(icon: Icon(Icons.folder_open_rounded, size: 20), text: 'Dokumen'),
        ],
      ),
    );
  }

  Widget _buildInfoTab(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildEventInfoCard(isDesktop),
    );
  }

  Widget _buildPesertaTab(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: Color(0xFF4169E1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Daftar Peserta',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_jumlahPeserta Peserta',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4169E1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _filterPeserta,
              decoration: InputDecoration(
                hintText: 'Cari peserta (nama, NIM, email)...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF4169E1),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _filterPeserta('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4169E1),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Peserta List
            if (_filteredPesertaList.isEmpty)
              Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        _searchController.text.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.people_outline_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'Tidak ada hasil'
                            : 'Belum ada peserta',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'Coba kata kunci lain'
                            : 'Peserta yang mendaftar akan muncul di sini',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_filteredPesertaList.length, (index) {
                final peserta = _filteredPesertaList[index];
                final user = peserta['users'] as Map<String, dynamic>?;
                return _buildPesertaItem(index + 1, user);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPesertaItem(int number, Map<String, dynamic>? user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4169E1).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4169E1).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Number Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['username'] ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (user?['nim'] != null)
                  Text(
                    'NIM: ${user!['nim']}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                if (user?['email'] != null)
                  Text(
                    user!['email'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),

          // Status Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDokumenTab(BuildContext context, bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildDocumentsCard(context, isDesktop),
    );
  }

  Widget _buildEventInfoCard(bool isDesktop) {
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF4169E1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Informasi Event',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gambar Event Section
          Text(
            'Gambar Event',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (_event!['gambar'] != null && _event!['gambar'].toString().isNotEmpty) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _event!['gambar'],
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        color: Colors.grey[100],
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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Gagal memuat gambar',
                                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingFile ? null : _showEditImageDialog,
                    icon: Icon(
                      _isUploadingFile ? Icons.hourglass_empty : Icons.edit,
                      size: 16,
                    ),
                    label: Text(_isUploadingFile ? 'Uploading...' : 'Ubah'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black.withOpacity(0.6),
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada gambar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isUploadingFile ? null : _showEditImageDialog,
                    icon: Icon(
                      _isUploadingFile ? Icons.hourglass_empty : Icons.add_photo_alternate,
                      size: 20,
                    ),
                    label: Text(_isUploadingFile ? 'Uploading...' : 'Tambah Gambar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4169E1),
                      side: const BorderSide(color: Color(0xFF4169E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 20),

          // Info Grid
          _buildInfoRow(
            Icons.location_on_rounded,
            'Lokasi',
            _event!['lokasi'] ?? '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Tanggal Mulai',
            _formatDate(_event!['tanggal_mulai']),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_month_rounded,
            'Tanggal Selesai',
            _formatDate(_event!['tanggal_selesai']),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.access_time_rounded,
            'Waktu',
            _formatTime(_event!['tanggal_mulai']),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.people_outline_rounded,
            'Max Peserta',
            _event!['max_participant']?.toString() ?? '-',
          ),

          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 20),

          // Deskripsi
          Text(
            'Deskripsi',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              _event!['deskripsi'] ?? 'Tidak ada deskripsi',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4169E1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF4169E1)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsCard(BuildContext context, bool isDesktop) {
    // Get status
    final statusProposal = _event!['status_proposal'] ?? 'belum_ajukan';
    final statusLpj = _event!['status_lpj'] ?? 'belum_ajukan';

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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: Color(0xFF4169E1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dokumen Event',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_dokumenProposal.length + _dokumenLpj.length} Dokumen',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4169E1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Proposal Section
          _buildDocumentSection(
            'Proposal',
            _dokumenProposal,
            statusProposal,
            'proposal',
          ),
          const SizedBox(height: 20),

          // LPJ Section
          _buildDocumentSection('LPJ', _dokumenLpj, statusLpj, 'lpj'),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(
    String title,
    List<Map<String, dynamic>> documents,
    String status,
    String documentType,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'disetujui':
        statusColor = const Color(0xFF10B981);
        statusText = 'Disetujui';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'menunggu':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Menunggu Review';
        statusIcon = Icons.schedule_rounded;
        break;
      case 'ditolak':
        statusColor = const Color(0xFFEF4444);
        statusText = 'Ditolak';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'revisi':
        statusColor = const Color(0xFFFF6B6B);
        statusText = 'Perlu Revisi';
        statusIcon = Icons.edit_rounded;
        break;
      case 'draft':
        statusColor = const Color(0xFF6B7280);
        statusText = 'Draft';
        statusIcon = Icons.description_outlined;
        break;
      default:
        statusColor = const Color(0xFF9CA3AF);
        statusText = 'Belum Diajukan';
        statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Upload Button
        if (status != 'disetujui')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploadingFile
                  ? null
                  : () => _pickAndUploadFile(documentType),
              icon: _isUploadingFile
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(
                _isUploadingFile ? 'Mengupload...' : 'Upload Dokumen',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),

        if (status != 'disetujui' && documents.isNotEmpty)
          const SizedBox(height: 12),

        // Document List
        if (documents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada dokumen',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...documents.map((doc) => _buildDocumentItem(doc, documentType)),
      ],
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc, String documentType) {
    final status = doc['status'] ?? 'menunggu';
    // Unified table uses id_document for all document types
    final docId = doc['id_document'];
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'disetujui':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Disetujui';
        break;
      case 'ditolak':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Ditolak';
        break;
      case 'draft':
        statusColor = const Color(0xFF9CA3AF);
        statusLabel = 'Draft';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Menunggu';
    }

    // Get filename (unified table uses specific field names)
    String filename = '';
    if (documentType == 'proposal') {
      filename = doc['original_filename_proposal'] ?? 'proposal.pdf';
    } else {
      filename = doc['original_filename_laporan'] ?? 'lpj_laporan.pdf';
    }

    // Check if document can be viewed (not draft)
    final canViewDetail = status != 'draft';

    return InkWell(
      onTap: canViewDetail ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailDocumentUKMPage(
              documentId: docId,
              documentType: documentType,
            ),
          ),
        ).then((_) => _loadEventDetails());
      } : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.description_rounded,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Diupload: ${_formatDate(doc['tanggal_pengajuan'])}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (documentType == 'lpj') ...[
                  const SizedBox(height: 4),
                  Text(
                    'File Keuangan: ${doc['original_filename_keuangan'] ?? 'keuangan.pdf'}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                if (doc['catatan_admin'] != null &&
                    doc['catatan_admin'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Colors.amber[900],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Catatan Admin: ${doc['catatan_admin']}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.amber[900],
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
          const SizedBox(width: 12),

          // Action buttons for draft status
          if (status == 'draft') ...[
            Column(
              children: [
                // Submit button
                SizedBox(
                  width: 100,
                  child: ElevatedButton.icon(
                    onPressed: () => _submitDocument(docId, documentType),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      'Ajukan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Delete button
                SizedBox(
                  width: 100,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteDocument(docId, documentType),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text(
                      'Hapus',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Lihat Detail button for non-draft documents
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailDocumentUKMPage(
                          documentId: docId,
                          documentType: documentType,
                        ),
                      ),
                    ).then((_) => _loadEventDetails());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4169E1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF4169E1)),
                        const SizedBox(width: 4),
                        Text(
                          'Detail',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4169E1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Event tidak ditemukan',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Kembali'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRAttendanceTab(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Pending Participants Section
          if (_pendingParticipants.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.pending_actions,
                          color: Colors.orange[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Peserta Menunggu Persetujuan (${_pendingParticipants.length})',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_pendingParticipants.length, (index) {
                    final participant = _pendingParticipants[index];
                    final user = participant['users'] as Map<String, dynamic>?;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(
                              0xFF4169E1,
                            ).withOpacity(0.1),
                            child: Text(
                              (user?['username'] ?? 'U')[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF4169E1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?['username'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  user?['email'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _acceptParticipant(
                              participant['id_absen_event'],
                            ),
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            tooltip: 'Terima',
                          ),
                          IconButton(
                            onPressed: () => _rejectParticipant(
                              participant['id_absen_event'],
                            ),
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            tooltip: 'Tolak',
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // QR Code Generator Section
          Container(
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
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4169E1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: Color(0xFF4169E1),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QR Code Absensi',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Generate QR code untuk absensi peserta (berlaku 10 detik)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isQRActive && _currentQRCode != null) ...[
                  // Show QR Code
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4169E1),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: QrImageView(
                            data: _currentQRCode!,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'QR Code Aktif',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (_qrExpiresAt != null)
                          TweenAnimationBuilder<int>(
                            key: ValueKey(_currentQRCode),
                            tween: IntTween(begin: 10, end: 0),
                            duration: const Duration(seconds: 10),
                            builder: (context, value, child) {
                              if (value == 0) {
                                Future.microtask(() async {
                                  if (mounted && _autoRegenerateQR) {
                                    // Auto regenerate QR code
                                    await _generateQRCode();
                                  } else {
                                    setState(() {
                                      _isQRActive = false;
                                      _currentQRCode = null;
                                      _qrExpiresAt = null;
                                    });
                                  }
                                });
                              }
                              return Column(
                                children: [
                                  // Circular countdown indicator
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: CircularProgressIndicator(
                                          value: value / 10,
                                          strokeWidth: 6,
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                value <= 3
                                                    ? Colors.red
                                                    : const Color(0xFF4169E1),
                                              ),
                                        ),
                                      ),
                                      Text(
                                        '$value',
                                        style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: value <= 3
                                              ? Colors.red
                                              : const Color(0xFF4169E1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    value <= 3
                                        ? (_autoRegenerateQR
                                              ? 'QR baru dalam $value detik'
                                              : 'Kadaluarsa dalam $value detik')
                                        : 'Berlaku $value detik lagi',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: value <= 3
                                          ? Colors.red
                                          : Colors.grey[600],
                                      fontWeight: value <= 3
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        // Auto regenerate toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Auto regenerate',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _autoRegenerateQR,
                              onChanged: (value) {
                                setState(() {
                                  _autoRegenerateQR = value;
                                });
                              },
                              activeThumbColor: const Color(0xFF4169E1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Stop button
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isQRActive = false;
                              _currentQRCode = null;
                              _qrExpiresAt = null;
                              _autoRegenerateQR = false;
                            });
                          },
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.red,
                          ),
                          label: Text(
                            'Hentikan QR',
                            style: GoogleFonts.inter(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _generateQRCode,
                    icon: const Icon(Icons.qr_code_scanner, size: 24),
                    label: Text(
                      'Generate QR Code',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQRCode() async {
    try {
      final result = await _eventService.generateAttendanceQR(widget.eventId);
      setState(() {
        _currentQRCode = result['qr_code'];
        _qrExpiresAt = DateTime.parse(result['expires_at']);
        _isQRActive = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR Code berhasil di-generate',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal generate QR: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptParticipant(String absenEventId) async {
    try {
      await _eventService.acceptParticipant(absenEventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Peserta diterima', style: GoogleFonts.inter()),
            backgroundColor: Colors.green,
          ),
        );
        _loadEventDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menerima peserta: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectParticipant(String absenEventId) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tolak Peserta',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Berikan alasan penolakan',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Alasan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Tolak', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await _eventService.rejectParticipant(
          absenEventId,
          reasonController.text.isEmpty
              ? 'Tidak memenuhi kriteria'
              : reasonController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Peserta ditolak', style: GoogleFonts.inter()),
              backgroundColor: Colors.green,
            ),
          );
          _loadEventDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menolak peserta: $e',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}
