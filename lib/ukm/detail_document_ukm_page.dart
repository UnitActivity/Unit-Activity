import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/document_service.dart';
import '../services/document_storage_service.dart';
import '../services/custom_auth_service.dart';
import '../models/document_model.dart';

class DetailDocumentUKMPage extends StatefulWidget {
  final String documentId;
  final String documentType; // 'proposal' or 'lpj'

  const DetailDocumentUKMPage({
    super.key,
    required this.documentId,
    required this.documentType,
  });

  @override
  State<DetailDocumentUKMPage> createState() => _DetailDocumentUKMPageState();
}

class _DetailDocumentUKMPageState extends State<DetailDocumentUKMPage> {
  final DocumentService _documentService = DocumentService();
  final DocumentStorageService _storageService = DocumentStorageService();
  final TextEditingController _commentController = TextEditingController();
  final CustomAuthService _authService = CustomAuthService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isDownloading = false;
  String? _error;

  // Document data
  DocumentProposal? _proposal;
  DocumentLPJ? _lpj;
  List<DocumentComment> _comments = [];
  List<DocumentRevision> _revisions = [];

  // For LPJ - which file to preview
  String _selectedLpjFile = 'laporan'; // 'laporan' or 'keuangan'

  @override
  void initState() {
    super.initState();
    _loadDocumentData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.documentType == 'proposal') {
        _proposal = await _documentService.getProposalDetails(
          widget.documentId,
        );
      } else {
        _lpj = await _documentService.getLPJDetails(widget.documentId);
      }

      // Load revision history
      _revisions = await _documentService.getRevisionHistory(
        widget.documentId,
        widget.documentType,
      );

      // Load all comments
      _comments = await _documentService.getDocumentComments(
        widget.documentId,
        widget.documentType,
      );

      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      print('Error loading document: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = 'Gagal memuat dokumen: ${e.toString()}';
        _isLoading = false;
      });
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
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User tidak terautentikasi');
      }

      final adminId = currentUser['id'] as String?;
      if (adminId == null) {
        throw Exception('Admin ID tidak ditemukan');
      }

      print('🔍 Getting UKM ID for admin: $adminId');

      // Get UKM ID from ukm table using admin ID
      final ukmResponse = await _documentService.supabase
          .from('ukm')
          .select('id_ukm')
          .eq('id_admin', adminId)
          .maybeSingle();

      if (ukmResponse == null) {
        throw Exception('UKM tidak ditemukan untuk admin ini');
      }

      final ukmId = ukmResponse['id_ukm'] as String;
      print('✅ Found UKM ID: $ukmId');

      // Add comment using UKM ID
      if (widget.documentType == 'proposal') {
        await _documentService.addProposalCommentByUkm(
          proposalId: widget.documentId,
          comment: _commentController.text.trim(),
          ukmId: ukmId,
        );
      } else {
        await _documentService.addLPJCommentByUkm(
          lpjId: widget.documentId,
          comment: _commentController.text.trim(),
          ukmId: ukmId,
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
        await _loadDocumentData();
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

  Future<void> _downloadDocument(String fileUrl) async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final fileName = _storageService.getFileNameFromUrl(fileUrl);

      if (kIsWeb) {
        final uri = Uri.parse(fileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File dibuka di tab baru'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        await _storageService.downloadAndOpenFile(
          fileUrl: fileUrl,
          fileName: fileName,
          onProgress: (progress) {},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File berhasil diunduh: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  String _getTimeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : CustomScrollView(
              slivers: [
                _buildAppBar(isMobile),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDocumentInfoCard(isMobile),
                        const SizedBox(height: 24),
                        _buildStatusCard(isMobile),
                        const SizedBox(height: 24),
                        _buildDocumentPreview(isMobile),
                        const SizedBox(height: 24),
                        _buildCommentsSection(isMobile),
                        const SizedBox(height: 24),
                        _buildRevisionHistory(isMobile),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
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
    );
  }

  Widget _buildAppBar(bool isMobile) {
    final documentName = widget.documentType == 'proposal'
        ? _proposal?.getEventName() ?? 'Proposal'
        : _lpj?.getEventName() ?? 'LPJ';

    final status = widget.documentType == 'proposal'
        ? _proposal?.status ?? 'menunggu'
        : _lpj?.status ?? 'menunggu';
    final statusStyle = DocumentService.getStatusStyle(status);

    return SliverAppBar(
      expandedHeight: isMobile ? 150 : 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF4169E1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.documentType == 'proposal' ? 'Detail Proposal' : 'Detail LPJ',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 14 : 16,
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
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        statusStyle['icon'] as IconData,
                        size: isMobile ? 32 : 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        documentName,
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentInfoCard(bool isMobile) {
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

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Color(0xFF4169E1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Informasi Dokumen',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Event', eventName, Icons.event_rounded, isMobile),
          _buildInfoRow('UKM', ukmName, Icons.groups_rounded, isMobile),
          _buildInfoRow(
            'Diupload oleh',
            userName,
            Icons.person_rounded,
            isMobile,
          ),
          _buildInfoRow(
            'Tanggal Pengajuan',
            _formatDate(tanggalPengajuan),
            Icons.calendar_today_rounded,
            isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    bool isMobile,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isMobile ? 16 : 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isMobile) {
    final status = widget.documentType == 'proposal'
        ? _proposal?.status ?? 'menunggu'
        : _lpj?.status ?? 'menunggu';
    final statusStyle = DocumentService.getStatusStyle(status);
    final catatan = widget.documentType == 'proposal'
        ? _proposal?.catatanAdmin
        : _lpj?.catatanAdmin;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (statusStyle['color'] as Color).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: (statusStyle['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusStyle['icon'] as IconData,
                  color: statusStyle['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Dokumen',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusStyle['color'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusStyle['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (catatan != null && catatan.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, size: 18, color: Colors.amber[800]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Admin',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          catatan,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(bool isMobile) {
    final isProposal = widget.documentType == 'proposal';
    String? fileUrl;

    if (isProposal) {
      fileUrl = _proposal?.fileProposal;
    } else {
      fileUrl = _selectedLpjFile == 'laporan'
          ? _lpj?.fileLaporan
          : _lpj?.fileKeuangan;
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.file_present_rounded,
                  color: Color(0xFF4169E1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'File Dokumen',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (!isProposal) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFileTab('Laporan', 'laporan', isMobile),
                const SizedBox(width: 8),
                _buildFileTab('Keuangan', 'keuangan', isMobile),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (fileUrl != null && fileUrl.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDownloading
                    ? null
                    : () => _downloadDocument(fileUrl!),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(_isDownloading ? 'Mengunduh...' : 'Download File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'File tidak tersedia',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileTab(String label, String value, bool isMobile) {
    final isSelected = _selectedLpjFile == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedLpjFile = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4169E1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Komentar (${_comments.length})',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Add Comment
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Komentar',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar Anda...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[400],
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
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _addComment,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'Mengirim...' : 'Kirim Komentar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Comments List
          if (_comments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada komentar',
                      style: GoogleFonts.inter(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              itemBuilder: (context, index) =>
                  _buildCommentItem(_comments[index], isMobile),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(DocumentComment comment, bool isMobile) {
    final isStatusChange = comment.isStatusChange;
    final isAdminComment = comment.isAdminComment();
    final isUkmComment = comment.isUkmComment();
    final isUserComment = comment.isUserComment();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isStatusChange
            ? Colors.blue.withOpacity(0.05)
            : isAdminComment
            ? Colors.red.withOpacity(0.05)
            : isUkmComment
            ? Colors.orange.withOpacity(0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isStatusChange
              ? Colors.blue.withOpacity(0.2)
              : isAdminComment
              ? Colors.red.withOpacity(0.2)
              : isUkmComment
              ? Colors.orange.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 14 : 16,
                backgroundColor: isAdminComment
                    ? Colors.red.withOpacity(0.1)
                    : isUkmComment
                    ? Colors.orange.withOpacity(0.1)
                    : const Color(0xFF4169E1).withOpacity(0.1),
                backgroundImage:
                    (isUserComment && comment.getUserPicture().isNotEmpty)
                    ? NetworkImage(comment.getUserPicture())
                    : (isUkmComment && comment.getUkmLogo().isNotEmpty)
                    ? NetworkImage(comment.getUkmLogo())
                    : null,
                child:
                    ((isUserComment && comment.getUserPicture().isNotEmpty) ||
                        (isUkmComment && comment.getUkmLogo().isNotEmpty))
                    ? null
                    : Icon(
                        isAdminComment
                            ? Icons.admin_panel_settings
                            : isUkmComment
                            ? Icons.groups
                            : Icons.person,
                        size: isMobile ? 14 : 16,
                        color: isAdminComment
                            ? Colors.red
                            : isUkmComment
                            ? Colors.orange
                            : const Color(0xFF4169E1),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.getCommenterName(),
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdminComment) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Admin',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        if (isUkmComment) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'UKM',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _getTimeAgo(comment.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isStatusChange &&
              comment.statusFrom != null &&
              comment.statusTo != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status diubah: ${comment.statusFrom} → ${comment.statusTo}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            comment.comment,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 13 : 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionHistory(bool isMobile) {
    if (_revisions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Riwayat Revisi',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _revisions.length,
            itemBuilder: (context, index) {
              final revision = _revisions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.update, size: 18, color: Colors.purple[400]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            revision.getStatusChangeText(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(revision.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[500],
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
}
