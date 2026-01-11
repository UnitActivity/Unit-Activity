import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../models/document_model.dart';
import '../services/document_service_admin.dart'; // CHANGED: Use admin service
import '../services/document_storage_service.dart';
import '../services/custom_auth_service.dart';
import '../utils/pdf_viewer.dart' as pdf_viewer;

class DetailDocumentPage extends StatefulWidget {
  final String documentId;
  final String documentType; // 'proposal' or 'lpj'

  const DetailDocumentPage({
    super.key,
    required this.documentId,
    required this.documentType,
  });

  @override
  State<DetailDocumentPage> createState() => _DetailDocumentPageState();
}

class _DetailDocumentPageState extends State<DetailDocumentPage> {
  final DocumentService _documentService = DocumentService();
  final DocumentStorageService _storageService = DocumentStorageService();
  final TextEditingController _commentController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isDownloading = false;
  // ignore: unused_field
  double _downloadProgress = 0.0;
  String? _error;

  // Document data
  DocumentProposal? _proposal;
  DocumentLPJ? _lpj;
  List<DocumentRevision> _revisions = [];
  List<DocumentComment> _comments = [];

  // Status management
  String? _selectedStatus;

  // For LPJ - which file to preview
  String _selectedLpjFile = 'laporan'; // 'laporan' or 'keuangan'

  // Inline edit state
  String? _editingCommentId;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDocumentData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentData() async {
    print(
      '\n🚀 [DETAIL_DOC_PAGE] ========== START LOADING DOCUMENT ==========',
    );
    print('📋 [DETAIL_DOC_PAGE] Document ID: ${widget.documentId}');
    print('📋 [DETAIL_DOC_PAGE] Document Type: ${widget.documentType}');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('\n📥 [DETAIL_DOC_PAGE] Step 1: Loading document details...');

      if (widget.documentType == 'proposal') {
        print('📄 [DETAIL_DOC_PAGE] Loading PROPOSAL details...');
        _proposal = await _documentService.getProposalDetails(
          widget.documentId,
        );
        print('✅ [DETAIL_DOC_PAGE] Proposal loaded successfully');
        print('📊 [DETAIL_DOC_PAGE] Proposal data: ${_proposal?.toJson()}');
        _selectedStatus = _proposal!.status;
      } else {
        print('📄 [DETAIL_DOC_PAGE] Loading LPJ details...');
        _lpj = await _documentService.getLPJDetails(widget.documentId);
        print('✅ [DETAIL_DOC_PAGE] LPJ loaded successfully');
        print('📊 [DETAIL_DOC_PAGE] LPJ data: ${_lpj?.toJson()}');
        _selectedStatus = _lpj!.status;
      }

      print('\n📥 [DETAIL_DOC_PAGE] Step 2: Loading revision history...');
      _revisions = await _documentService.getRevisionHistory(
        widget.documentId,
        widget.documentType,
      );
      print('✅ [DETAIL_DOC_PAGE] Loaded ${_revisions.length} revisions');

      print('\n📥 [DETAIL_DOC_PAGE] Step 3: Loading comments...');
      _comments = await _documentService.getDocumentComments(
        widget.documentId,
        widget.documentType,
      );
      print('✅ [DETAIL_DOC_PAGE] Loaded ${_comments.length} comments');

      print(
        '\n✅ [DETAIL_DOC_PAGE] ========== DOCUMENT LOADED SUCCESSFULLY ==========\n',
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      print(
        '\n❌ [DETAIL_DOC_PAGE] ========== ERROR LOADING DOCUMENT ==========',
      );
      print('❌ [DETAIL_DOC_PAGE] Error: $e');
      print('❌ [DETAIL_DOC_PAGE] Stack trace: $stackTrace');
      print('❌ [DETAIL_DOC_PAGE] ========================================\n');

      if (mounted) {
        setState(() {
          _error = 'Gagal memuat dokumen: ${e.toString()}';
          _isLoading = false;
        });

        // Show error dialog on Windows desktop
        if (MediaQuery.of(context).size.width >= 768) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    const Text('Error Memuat Dokumen'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Terjadi kesalahan saat memuat dokumen:'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.toString(),
                        style: TextStyle(color: Colors.red[900], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Document ID: ${widget.documentId}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'Type: ${widget.documentType}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadDocumentData();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          });
        }
      }
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih status terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentStatus = widget.documentType == 'proposal'
        ? _proposal?.status
        : _lpj?.status;

    if (_selectedStatus == currentStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status tidak berubah'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Text(
              'Konfirmasi Perubahan Status',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin mengubah status dokumen dari "$currentStatus" ke "$_selectedStatus"?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.grey[600]),
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
            ),
            child: Text('Ya, Ubah', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      // Get admin ID from CustomAuthService (admin table, not auth.users)
      final authService = CustomAuthService();
      final currentUser = authService.currentUser;

      print('🔄 [Status Update] Current user: $currentUser');

      if (currentUser == null) {
        throw Exception('Admin tidak terautentikasi');
      }

      final adminId = currentUser['id'] as String?;
      if (adminId == null) {
        throw Exception('Admin ID tidak ditemukan');
      }

      print('🔄 [Status Update] Admin ID: $adminId');

      if (widget.documentType == 'proposal') {
        await _documentService.updateProposalStatus(
          proposalId: widget.documentId,
          newStatus: _selectedStatus!,
          catatan: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
          adminId: adminId,
        );
      } else {
        await _documentService.updateLPJStatus(
          lpjId: widget.documentId,
          newStatus: _selectedStatus!,
          catatan: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
          adminId: adminId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );

        _commentController.clear();
        await _loadDocumentData(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tulis komentar terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get admin ID from CustomAuthService (admin table, not auth.users)
      final authService = CustomAuthService();
      final currentUser = authService.currentUser;

      print('💬 [Comment] Current user: $currentUser');

      if (currentUser == null) {
        throw Exception('Admin tidak terautentikasi');
      }

      final adminId = currentUser['id'] as String?;
      if (adminId == null) {
        throw Exception('Admin ID tidak ditemukan');
      }

      print('💬 [Comment] Admin ID: $adminId');

      if (widget.documentType == 'proposal') {
        await _documentService.addProposalComment(
          proposalId: widget.documentId,
          comment: _commentController.text.trim(),
          adminId: adminId,
        );
      } else {
        await _documentService.addLPJComment(
          lpjId: widget.documentId,
          comment: _commentController.text.trim(),
          adminId: adminId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );

        _commentController.clear();
        await _loadDocumentData(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan komentar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _editComment(DocumentComment comment) {
    setState(() {
      _editingCommentId = comment.idComment;
      _editController.text = comment.comment;
    });
  }

  Future<void> _saveEditComment(DocumentComment comment) async {
    final newComment = _editController.text.trim();
    if (newComment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komentar tidak boleh kosong'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = CustomAuthService();
      final currentUser = authService.currentUser;
      final adminId = currentUser?['id'] as String?;

      if (adminId == null) {
        throw Exception('Admin ID tidak ditemukan');
      }

      print('🔍 Updating comment: ${comment.idComment}');
      print('👤 Admin ID: $adminId');
      print('📝 New comment: $newComment');

      await _documentService.updateComment(
        commentId: comment.idComment,
        newComment: newComment,
        adminId: adminId,
      );

      if (mounted) {
        setState(() {
          _editingCommentId = null;
          _editController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadDocumentData();
      }
    } catch (e) {
      print('❌ Error updating comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update komentar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteComment(DocumentComment comment) async {
    // Konfirmasi yang berbeda untuk status change comment
    String confirmMessage =
        'Apakah Anda yakin ingin menghapus komentar ini? Tindakan ini tidak dapat dibatalkan.';

    if (comment.isStatusChange && comment.statusFrom != null) {
      confirmMessage =
          'Apakah Anda yakin ingin menghapus komentar perubahan status ini?\n\nStatus dokumen akan dikembalikan dari "${comment.statusTo}" ke "${comment.statusFrom}".';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text('Hapus Komentar', style: GoogleFonts.inter()),
          ],
        ),
        content: Text(confirmMessage, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Hapus', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final authService = CustomAuthService();
      final currentUser = authService.currentUser;
      final adminId = currentUser?['id'] as String?;

      if (adminId == null) {
        throw Exception('Admin ID tidak ditemukan');
      }

      print('🔍 Deleting comment: ${comment.idComment}');
      print('👤 Admin ID: $adminId');
      print('🔄 Is Status Change: ${comment.isStatusChange}');

      // Jika ini adalah status change comment, rollback status terlebih dahulu
      if (comment.isStatusChange && comment.statusFrom != null) {
        print(
          '⏪ Rolling back status from ${comment.statusTo} to ${comment.statusFrom}',
        );

        await _documentService.rollbackStatus(
          documentId: widget.documentId,
          rollbackToStatus: comment.statusFrom!,
          adminId: adminId,
        );
      }

      // Hapus comment
      await _documentService.deleteComment(
        commentId: comment.idComment,
        adminId: adminId,
      );

      if (mounted) {
        final message = comment.isStatusChange
            ? 'Komentar berhasil dihapus dan status dikembalikan ke "${comment.statusFrom}"'
            : 'Komentar berhasil dihapus';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        await _loadDocumentData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal hapus komentar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _downloadDocument(String fileUrl) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final fileName = _storageService.getFileNameFromUrl(fileUrl);

      if (kIsWeb) {
        // For web, open in new tab - browser will handle download
        final uri = Uri.parse(fileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File dibuka di tab baru'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw 'Tidak dapat membuka URL';
        }
      } else {
        // For mobile, download and open
        await _storageService.downloadAndOpenFile(
          fileUrl: fileUrl,
          fileName: fileName,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _downloadProgress = progress;
              });
            }
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File berhasil diunduh: $fileName'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  // Helper function to download PDF data from network
  Future<Uint8List> _downloadPdfData(String fileUrl) async {
    try {
      print('📥 [_downloadPdfData] Downloading PDF from: $fileUrl');
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        print(
          '✅ [_downloadPdfData] PDF downloaded successfully, size: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [_downloadPdfData] Error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Dokumen',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadDocumentData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4169E1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 32 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDocumentInfoCard(),
                        const SizedBox(height: 24),
                        _buildDocumentPreview(),
                        const SizedBox(height: 24),
                        _buildStatusManagement(),
                        const SizedBox(height: 24),
                        _buildCommentsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    final documentName = widget.documentType == 'proposal'
        ? _proposal?.getEventName() ?? 'Proposal'
        : _lpj?.getEventName() ?? 'LPJ';

    final statusStyle = DocumentService.getStatusStyle(
      widget.documentType == 'proposal'
          ? _proposal?.status ?? 'menunggu'
          : _lpj?.status ?? 'menunggu',
    );

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF4169E1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.documentType == 'proposal' ? 'Proposal' : 'LPJ',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.1),
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
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          statusStyle['icon'] as IconData,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        documentName,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentInfoCard() {
    final isProposal = widget.documentType == 'proposal';
    final eventName = isProposal
        ? _proposal?.getEventName() ?? '-'
        : _lpj?.getEventName() ?? '-';
    final ukmName = isProposal
        ? _proposal?.getUkmName() ?? '-'
        : _lpj?.getUkmName() ?? '-';
    final userName = isProposal
        ? _proposal?.getUserName() ?? '-'
        : _lpj?.getUserName() ?? '-';
    final tanggalPengajuan = isProposal
        ? _proposal?.tanggalPengajuan
        : _lpj?.tanggalPengajuan;
    final tanggalDitinjau = isProposal
        ? _proposal?.tanggalDitinjau
        : _lpj?.tanggalDitinjau;
    final status = isProposal ? _proposal?.status ?? '-' : _lpj?.status ?? '-';
    final statusStyle = DocumentService.getStatusStyle(status);

    final fileSize = isProposal
        ? _proposal?.fileSize
        : _selectedLpjFile == 'laporan'
        ? _lpj?.fileSizeLaporan
        : _lpj?.fileSizeKeuangan;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isProposal
                        ? [const Color(0xFF4169E1), const Color(0xFF5B7FE8)]
                        : [const Color(0xFF10B981), const Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isProposal
                      ? Icons.description_rounded
                      : Icons.assignment_turned_in_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProposal
                          ? 'Proposal Event'
                          : 'Laporan Pertanggungjawaban',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      eventName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (statusStyle['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (statusStyle['color'] as Color).withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusStyle['icon'] as IconData,
                      size: 16,
                      color: statusStyle['color'] as Color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusStyle['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusStyle['color'] as Color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.business, 'UKM', ukmName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person, 'Diajukan oleh', userName),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today,
            'Tanggal Pengajuan',
            tanggalPengajuan != null
                ? DateFormat(
                    'dd MMMM yyyy, HH:mm',
                    'id_ID',
                  ).format(tanggalPengajuan)
                : '-',
          ),
          if (tanggalDitinjau != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.check_circle,
              'Tanggal Ditinjau',
              DateFormat(
                'dd MMMM yyyy, HH:mm',
                'id_ID',
              ).format(tanggalDitinjau),
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.storage,
            'Ukuran File',
            DocumentService.formatFileSize(fileSize),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4169E1)),
        const SizedBox(width: 12),
        Expanded(
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
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentPreview() {
    final isProposal = widget.documentType == 'proposal';
    String? fileUrl;

    if (isProposal) {
      fileUrl = _proposal?.fileProposal;
      print('📄 [PREVIEW] Proposal file path from DB: $fileUrl');
    } else {
      fileUrl = _selectedLpjFile == 'laporan'
          ? _lpj?.fileLaporan
          : _lpj?.fileKeuangan;
      print('📄 [PREVIEW] LPJ file path from DB ($_selectedLpjFile): $fileUrl');
    }

    if (fileUrl != null) {
      print('📄 [PREVIEW] Will construct URL from path: $fileUrl');
    } else {
      print('❌ [PREVIEW] File URL is NULL!');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4169E1).withValues(alpha: 0.1),
                  const Color(0xFF5B7FE8).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Preview Dokumen',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (!isProposal)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'laporan',
                        label: Text('Laporan'),
                        icon: Icon(Icons.description, size: 16),
                      ),
                      ButtonSegment(
                        value: 'keuangan',
                        label: Text('Keuangan'),
                        icon: Icon(Icons.attach_money, size: 16),
                      ),
                    ],
                    selected: {_selectedLpjFile},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedLpjFile = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      textStyle: WidgetStateProperty.all(
                        GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 500,
            padding: const EdgeInsets.all(16),
            child: fileUrl != null
                ? _buildFilePreview(fileUrl)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'File tidak tersedia',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusManagement() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Kelola Status Dokumen',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Status Dokumen',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatusChip('menunggu', 'Menunggu Review', Icons.schedule),
              _buildStatusChip('disetujui', 'Disetujui', Icons.check_circle),
              _buildStatusChip('ditolak', 'Ditolak', Icons.cancel),
              _buildStatusChip('revisi', 'Perlu Revisi', Icons.edit),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Tambah Komentar',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tulis komentar untuk dokumen ini...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
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
                borderSide: const BorderSide(color: Color(0xFF4169E1)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _addComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.comment, size: 18),
                  label: Text(
                    'Tambah Komentar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _updateStatus,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(
                    'Update Status',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, IconData icon) {
    final isSelected = _selectedStatus == value;
    final statusStyle = DocumentService.getStatusStyle(value);
    final color = statusStyle['color'] as Color;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : color,
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.1),
                  const Color(0xFF10B981).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Riwayat & Komentar (${_comments.length})',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display all comments
                if (_comments.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada komentar atau riwayat',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Display all comments in timeline
                  ...List.generate(
                    _comments.length,
                    (index) => _buildCommentItem(_comments[index], index),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(DocumentComment comment, int index) {
    // Get current admin ID to check if this comment belongs to them
    final authService = CustomAuthService();
    final currentUser = authService.currentUser;
    final currentAdminId = currentUser?['id'] as String?;

    // Check ownership - must have valid admin ID and match current user
    final hasValidAdminId =
        comment.idAdmin != null && comment.idAdmin!.isNotEmpty;
    final isOwnComment = hasValidAdminId && currentAdminId == comment.idAdmin;

    // Debug info
    print('🔍 Comment ID: ${comment.idComment}');
    print('👤 Comment Admin ID: ${comment.idAdmin}');
    print('👤 Comment UKM ID: ${comment.idUkm}');
    print('👤 Comment User ID: ${comment.idUser}');
    print('👤 Current Admin ID: $currentAdminId');
    print('✅ Has Valid Admin ID: $hasValidAdminId');
    print('✅ Is Own Comment: $isOwnComment');

    // Get commenter name and avatar based on who commented
    String commenterName;
    String initials;
    Color avatarColor;

    if (comment.isAdminComment()) {
      commenterName = comment.getAdminName();
      avatarColor = comment.isStatusChange
          ? const Color(0xFF4169E1)
          : const Color(0xFF10B981);
    } else if (comment.isUkmComment()) {
      commenterName = comment.getUkmName();
      avatarColor = const Color(0xFFFF6B35); // Orange for UKM
    } else if (comment.isUserComment()) {
      commenterName = comment.getUserName();
      avatarColor = const Color(0xFF9333EA); // Purple for User
    } else {
      commenterName = 'Unknown';
      avatarColor = Colors.grey;
    }

    initials = commenterName.isNotEmpty
        ? commenterName.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: comment.isStatusChange
              ? [Colors.blue[50]!, Colors.blue[100]!.withValues(alpha: 0.3)]
              : [Colors.grey[50]!, Colors.grey[100]!.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: comment.isStatusChange ? Colors.blue[200]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar dengan initial nama commenter
              CircleAvatar(
                backgroundColor: avatarColor,
                radius: 20,
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          commenterName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge untuk tipe commenter
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: avatarColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            comment.isAdminComment()
                                ? (isOwnComment ? 'Anda (Admin)' : 'Admin')
                                : comment.isUkmComment()
                                ? 'UKM'
                                : 'User',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: avatarColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, HH:mm',
                        'id_ID',
                      ).format(comment.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Badge untuk perubahan status
              if (comment.isStatusChange)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync_alt, size: 12, color: Colors.blue[800]),
                      const SizedBox(width: 4),
                      Text(
                        'Status',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // Tombol Edit & Hapus - tampil untuk komentar sendiri (termasuk status change)
              if (hasValidAdminId) ...[
                const SizedBox(width: 4),
                // Tombol Edit
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: isOwnComment
                        ? const Color(0xFF4169E1)
                        : Colors.grey[400],
                  ),
                  onPressed: isOwnComment ? () => _editComment(comment) : null,
                  tooltip: isOwnComment
                      ? 'Edit komentar'
                      : 'Hanya bisa edit komentar sendiri',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                // Tombol Hapus
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: isOwnComment ? Colors.red : Colors.grey[400],
                  ),
                  onPressed: isOwnComment
                      ? () => _deleteComment(comment)
                      : null,
                  tooltip: isOwnComment
                      ? 'Hapus komentar'
                      : 'Hanya bisa hapus komentar sendiri',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          if (comment.isStatusChange &&
              comment.statusFrom != null &&
              comment.statusTo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusBadge(comment.statusFrom!),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  _buildStatusBadge(comment.statusTo!),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Inline editing or display comment
          _editingCommentId == comment.idComment
              ? _buildInlineEditForm(comment)
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    comment.comment,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildInlineEditForm(DocumentComment comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4169E1), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _editController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Edit komentar...',
              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _editingCommentId = null;
                    _editController.clear();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  'Batal',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _saveEditComment(comment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Simpan',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusStyle = DocumentService.getStatusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (statusStyle['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (statusStyle['color'] as Color).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusStyle['icon'] as IconData,
            size: 14,
            color: statusStyle['color'] as Color,
          ),
          const SizedBox(width: 6),
          Text(
            statusStyle['label'] as String,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusStyle['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildRevisionItem(DocumentRevision revision, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.grey[100]!.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF4169E1),
                radius: 18,
                child: Text(
                  revision.getAuthorName()[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      revision.getAuthorName(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, HH:mm',
                        'id_ID',
                      ).format(revision.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (revision.statusSebelumnya != null &&
              revision.statusSetelahnya != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text(
                    revision.getStatusChangeText(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (revision.catatan != null && revision.catatan!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              revision.catatan!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilePreview(String filePath) {
    print('🔧 [_buildFilePreview] Input filePath: $filePath');

    // Construct proper URL
    String fileUrl;
    try {
      print('🔧 [_buildFilePreview] Calling getProperFileUrl...');
      fileUrl = _storageService.getProperFileUrl(filePath);
      print('✅ [_buildFilePreview] Constructed URL: $fileUrl');
    } catch (e) {
      print('❌ [_buildFilePreview] URL construction failed: $e');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'URL file tidak valid',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Path: $filePath\n\nError: ${e.toString()}',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Detect file extension
    final String extension = _storageService.getFileExtension(fileUrl);
    print('🔧 [_buildFilePreview] File extension: $extension');

    // Check if it's a PDF
    if (extension == 'pdf') {
      print('📄 [_buildFilePreview] Rendering PDF viewer for: $fileUrl');

      if (kIsWeb) {
        print('🌐 [_buildFilePreview] Using iframe for web platform');
        return _buildWebPdfViewer(fileUrl);
      }

      print('📱 [_buildFilePreview] Using PdfView for mobile/desktop');
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder<PdfDocument>(
          future: PdfDocument.openData(
            // Download PDF data from network
            _downloadPdfData(fileUrl),
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('❌ [PDF] Load failed: ${snapshot.error}');
              print('❌ [PDF] URL was: $fileUrl');
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal memuat PDF: ${snapshot.error}\n\nURL: $fileUrl',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'Download',
                        textColor: Colors.white,
                        onPressed: () => _downloadDocument(fileUrl),
                      ),
                    ),
                  );
                });
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat PDF',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _downloadDocument(fileUrl),
                      icon: const Icon(Icons.download),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4169E1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final document = snapshot.data!;
            print(
              '✅ [PDF] Document loaded successfully! Pages: ${document.pagesCount}',
            );

            return PdfView(
              controller: PdfController(document: Future.value(document)),
              scrollDirection: Axis.vertical,
              onDocumentError: (error) {
                print('❌ [PDF] Document error: $error');
              },
            );
          },
        ),
      );
    }

    // For Word, Excel, PowerPoint, and other files - show download option
    IconData fileIcon;
    String fileType;
    Color iconColor;

    switch (extension) {
      case 'doc':
      case 'docx':
        fileIcon = Icons.description;
        fileType = 'Microsoft Word';
        iconColor = const Color(0xFF2B579A);
        break;
      case 'xls':
      case 'xlsx':
        fileIcon = Icons.table_chart;
        fileType = 'Microsoft Excel';
        iconColor = const Color(0xFF217346);
        break;
      case 'ppt':
      case 'pptx':
        fileIcon = Icons.slideshow;
        fileType = 'Microsoft PowerPoint';
        iconColor = const Color(0xFFD24726);
        break;
      case 'txt':
        fileIcon = Icons.text_snippet;
        fileType = 'Text File';
        iconColor = Colors.grey[700]!;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        // For images, show the image
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            fileUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat gambar',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      default:
        fileIcon = Icons.insert_drive_file;
        fileType = 'File';
        iconColor = Colors.grey[700]!;
    }

    // Show download card for non-previewable files
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(fileIcon, size: 64, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              fileType,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preview tidak tersedia untuk tipe file ini',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _downloadDocument(fileUrl),
              icon: const Icon(Icons.download_rounded),
              label: Text(
                'Download File',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                try {
                  final uri = Uri.parse(fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal membuka file: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(
                'Buka di Browser',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Web-specific PDF viewer using iframe
  Widget _buildWebPdfViewer(String fileUrl) {
    if (!kIsWeb) {
      return const SizedBox();
    }

    return pdf_viewer.buildWebPdfViewer(fileUrl);
  }
}
