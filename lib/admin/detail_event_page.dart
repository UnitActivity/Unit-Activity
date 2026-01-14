import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_document_page.dart';

class DetailEventPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const DetailEventPage({super.key, required this.event});

  @override
  State<DetailEventPage> createState() => _DetailEventPageState();
}

class _DetailEventPageState extends State<DetailEventPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _dokumenProposal = [];
  List<Map<String, dynamic>> _dokumenLpj = [];
  int _jumlahPeserta = 0;
  List<Map<String, dynamic>> _pesertaList =
      []; // List of participants with attendance status

  // Realtime subscription
  RealtimeChannel? _documentsChannel;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
    _subscribeToRealtimeUpdates();
  }

  @override
  void dispose() {
    _documentsChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToRealtimeUpdates() {
    final idEvent = widget.event['id_events'];
    _documentsChannel = _supabase
        .channel('detail_documents_$idEvent')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_documents',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_event',
            value: idEvent,
          ),
          callback: (payload) {
            print(
              '📄 Document change detected for event: ${payload.eventType}',
            );
            _loadEventDetails();
          },
        )
        .subscribe();
  }

  Future<void> _loadEventDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final idEvent = widget.event['id_events'];

      // Load dokumen proposal dari event_documents
      final proposalData = await _supabase
          .from('event_documents')
          .select('*, users(username)')
          .eq('id_event', idEvent)
          .eq('document_type', 'proposal');
      _dokumenProposal = List<Map<String, dynamic>>.from(proposalData);

      // Load dokumen LPJ dari event_documents
      final lpjData = await _supabase
          .from('event_documents')
          .select('*, users(username)')
          .eq('id_event', idEvent)
          .eq('document_type', 'lpj');
      _dokumenLpj = List<Map<String, dynamic>>.from(lpjData);

      // Load peserta dengan status absensi dari absen_event
      final pesertaData = await _supabase
          .from('absen_event')
          .select('*, users(username, nim, email)')
          .eq('id_event', idEvent);
      _pesertaList = List<Map<String, dynamic>>.from(pesertaData);
      _jumlahPeserta = _pesertaList.length;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat detail event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return '-';
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '00:00';
    try {
      // Check if it's a time string (HH:mm:ss format)
      if (timeStr.contains(':') && !timeStr.contains('T')) {
        // It's already a time string, just format it
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return '${parts[0]}:${parts[1]}';
        }
        return timeStr;
      }
      // Otherwise try to parse as datetime
      final date = DateTime.parse(timeStr);
      return DateFormat('HH:mm', 'id_ID').format(date);
    } catch (e) {
      return '00:00';
    }
  }

  String _formatDocumentStatus(String? status) {
    if (status == null) return 'Belum Diajukan';
    switch (status.toLowerCase()) {
      case 'belum_ajukan':
        return 'Belum Diajukan';
      case 'menunggu':
        return 'Menunggu Review';
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'revisi':
        return 'Perlu Revisi';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
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
                // Calculate the collapse ratio
                final double collapseRatio =
                    ((constraints.maxHeight - kToolbarHeight) /
                            (200 - kToolbarHeight))
                        .clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 10),
                  title: Opacity(
                    opacity: 1 - collapseRatio, // Fade in when collapsed
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
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
                            widget.event['nama_event'] ?? 'Detail Event',
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
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
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Header Card
                  _buildEventHeaderCard(isDesktop, isMobile),
                  const SizedBox(height: 20),

                  // Stats Cards
                  _buildStatsCards(isDesktop, isMobile),
                  const SizedBox(height: 20),

                  // Event Information
                  _buildEventInfoCard(isDesktop, isMobile),
                  const SizedBox(height: 20),

                  // Documents
                  _buildDocumentsCard(context, isDesktop, isMobile),
                  const SizedBox(height: 20),

                  // Participants List
                  _buildParticipantsCard(isDesktop, isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventHeaderCard(bool isDesktop, bool isMobile) {
    // Get event image
    final String? imageUrl = widget.event['gambar'];

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
          // Event Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                          child: const Center(
                            child: Icon(
                              Icons.event_rounded,
                              size: 48,
                              color: Color(0xFF4169E1),
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(
                          Icons.event_rounded,
                          size: 48,
                          color: Color(0xFF4169E1),
                        ),
                      ),
                    ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Row(
              children: [
                // Event Icon
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4169E1).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.event_rounded,
                    size: isMobile ? 24 : 32,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),

                // Event Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event['nama_event'] ?? '-',
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
                          color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 14,
                              color: const Color(0xFF4169E1),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.event['tipevent'] ?? '-',
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDesktop, bool isMobile) {
    // Get status as boolean from database and convert to text
    final statusBool = widget.event['status'] ?? true;
    final status = statusBool == true ? 'Aktif' : 'Tidak Aktif';
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
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today_rounded,
            label: 'Status',
            value: status,
            gradient: LinearGradient(
              colors: statusBool == false
                  ? [const Color(0xFF6B7280), const Color(0xFF9CA3AF)]
                  : [const Color(0xFF10B981), const Color(0xFF34D399)],
            ),
            isDesktop: isDesktop,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.bookmark_outline,
            label: 'Dokumen',
            value: totalDokumen.toString(),
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
            isDesktop: isDesktop,
            isMobile: isMobile,
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
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : (isDesktop ? 20 : 16)),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: isMobile ? 20 : 24),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 16 : (isDesktop ? 24 : 20),
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoCard(bool isDesktop, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFF4169E1),
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Informasi Event',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Info Grid
          _buildInfoRow(
            Icons.business_rounded,
            'UKM',
            (widget.event['ukm'] as Map<String, dynamic>?)?['nama_ukm'] ?? '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.people_rounded,
            'Periode',
            (widget.event['periode_ukm']
                    as Map<String, dynamic>?)?['nama_periode'] ??
                '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.location_on_rounded,
            'Lokasi',
            widget.event['lokasi'] ?? '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Tanggal Mulai',
            _formatDate(widget.event['tanggal_mulai']),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_month_rounded,
            'Tanggal Akhir',
            _formatDate(widget.event['tanggal_akhir']),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.access_time_rounded,
            'Waktu Mulai',
            _formatTime(widget.event['jam_mulai']),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.access_time_filled_rounded,
            'Waktu Akhir',
            _formatTime(widget.event['jam_akhir']),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.people_outline_rounded,
            'Max Peserta',
            widget.event['max_participant']?.toString() ?? '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.event_available_rounded,
            'Tanggal Pendaftaran',
            _formatDate(widget.event['tanggal_pendaftaran']),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.business_rounded,
            'Dibuat Oleh',
            (widget.event['ukm'] as Map<String, dynamic>?)?['nama_ukm'] ?? '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.description_outlined,
            'Status Proposal',
            _formatDocumentStatus(widget.event['status_proposal']),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.assignment_outlined,
            'Status LPJ',
            _formatDocumentStatus(widget.event['status_lpj']),
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
              widget.event['deskripsi'] ?? 'Tidak ada deskripsi',
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
            color: const Color(0xFF4169E1).withValues(alpha: 0.1),
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

  Widget _buildDocumentsCard(
    BuildContext context,
    bool isDesktop,
    bool isMobile,
  ) {
    // Combine proposal and LPJ documents
    final documents = [
      ..._dokumenProposal.map(
        (doc) => {
          'id': doc['id_document'], // Unified table uses id_document
          'name': 'Proposal - ${widget.event['nama_event']}',
          'type': 'proposal',
          'status': doc['status'] ?? 'Menunggu',
          'uploadedAt': doc['tanggal_pengajuan'],
          'uploadedBy':
              (doc['users'] as Map<String, dynamic>?)?['username'] ?? 'Unknown',
          'icon': Icons.description_rounded,
          'color': Colors.red,
          'catatan_admin': doc['catatan_admin'],
        },
      ),
      ..._dokumenLpj.map(
        (doc) => {
          'id': doc['id_document'], // Unified table uses id_document
          'name': 'LPJ - ${widget.event['nama_event']}',
          'type': 'lpj',
          'status': doc['status'] ?? 'Menunggu',
          'uploadedAt': doc['tanggal_pengajuan'],
          'uploadedBy':
              (doc['users'] as Map<String, dynamic>?)?['username'] ?? 'Unknown',
          'icon': Icons.assignment_rounded,
          'color': Colors.blue,
          'catatan_admin': doc['catatan_admin'],
        },
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  color: const Color(0xFF4169E1),
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Dokumen Event',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 16 : 18,
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
                  color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${documents.length} Dokumen',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4169E1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...documents.map((doc) => _buildDocumentItem(context, doc, isMobile)),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
    BuildContext context,
    Map<String, dynamic> doc,
    bool isMobile,
  ) {
    final status = (doc['status'] as String?)?.toLowerCase() ?? 'menunggu';
    Color statusColor;
    String statusText;
    switch (status) {
      case 'disetujui':
        statusColor = Colors.green;
        statusText = 'Disetujui';
        break;
      case 'ditolak':
        statusColor = Colors.red;
        statusText = 'Ditolak';
        break;
      case 'revisi':
        statusColor = Colors.orange;
        statusText = 'Perlu Revisi';
        break;
      case 'menunggu':
      default:
        statusColor = Colors.blue;
        statusText = 'Menunggu';
    }

    // Store formatted status for display
    doc['displayStatus'] = statusText;

    return InkWell(
      onTap: () {
        // Navigate to Detail Document Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailDocumentPage(
              documentId: doc['id'],
              documentType: doc['type'],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
        padding: EdgeInsets.all(isMobile ? 12 : 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (doc['color'] as Color).withValues(alpha: 0.2),
                        (doc['color'] as Color).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    doc['icon'] as IconData,
                    color: doc['color'] as Color,
                    size: isMobile ? 22 : 28,
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['name'],
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (doc['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              doc['type'],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: doc['color'] as Color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doc['uploadedBy'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.circle, size: 4, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(doc['uploadedAt']),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (doc['catatan_admin'] != null &&
                doc['catatan_admin'].toString().isNotEmpty)
              const SizedBox(height: 12),
            if (doc['catatan_admin'] != null &&
                doc['catatan_admin'].toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catatan Admin:',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doc['catatan_admin'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
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
        ),
      ),
    );
  }

  /// Build participants card with attendance status
  Widget _buildParticipantsCard(bool isDesktop, bool isMobile) {
    // Count participants who have attended (status = 'hadir')
    final attendedCount = _pesertaList.where((p) {
      final status = p['status']?.toString().toLowerCase() ?? '';
      return status == 'hadir';
    }).length;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.people_rounded,
                  color: const Color(0xFF4169E1),
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Peserta',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$attendedCount dari $_jumlahPeserta peserta hadir',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Stats badges
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$attendedCount Hadir',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Participant List
          if (_pesertaList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada peserta terdaftar',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pesertaList.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey[200], height: 1),
              itemBuilder: (context, index) {
                final peserta = _pesertaList[index];
                final userData = peserta['users'] as Map<String, dynamic>?;
                final username = userData?['username'] ?? 'Unknown';
                final nim = userData?['nim'] ?? '-';
                final status =
                    peserta['status']?.toString().toLowerCase() ?? '';
                final isHadir = status == 'hadir';
                final jamAbsen = peserta['jam']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4169E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'NIM: $nim',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Attendance Status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isHadir
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isHadir ? Icons.check_circle : Icons.schedule,
                                  size: 14,
                                  color: isHadir
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isHadir ? 'Hadir' : 'Belum Hadir',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isHadir
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isHadir && jamAbsen.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Jam: $jamAbsen',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
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
