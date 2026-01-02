import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'edit_informasi_page.dart';

class DetailInformasiPage extends StatefulWidget {
  final Map<String, dynamic> informasi;

  const DetailInformasiPage({super.key, required this.informasi});

  @override
  State<DetailInformasiPage> createState() => _DetailInformasiPageState();
}

class _DetailInformasiPageState extends State<DetailInformasiPage> {
  final _supabase = Supabase.instance.client;
  bool _isDeleting = false;

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateShort(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _shareInformasi(BuildContext context) {
    final text =
        '''
📢 ${widget.informasi['judul']}

${widget.informasi['deskripsi'] ?? ''}

📌 Status: ${widget.informasi['status']}
${widget.informasi['ukm'] != null ? '🏢 UKM: ${widget.informasi['ukm']['nama_ukm']}\n' : ''}
📅 Dipublikasikan: ${_formatDateShort(widget.informasi['create_at'])}
    '''
            .trim();

    Share.share(text);
  }

  Future<void> _deleteInformasi() async {
    final confirm = await showDialog<bool>(
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
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Hapus Informasi?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus informasi ini? Tindakan ini tidak dapat dibatalkan.',
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

    if (confirm == true) {
      setState(() => _isDeleting = true);

      try {
        // Delete image from storage if exists
        if (widget.informasi['gambar'] != null) {
          await _supabase.storage.from('informasi-images').remove([
            widget.informasi['gambar'],
          ]);
        }

        // Delete informasi from database
        await _supabase
            .from('informasi')
            .delete()
            .eq('id_informasi', widget.informasi['id_informasi']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Informasi berhasil dihapus',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isDeleting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e', style: GoogleFonts.inter()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Simple App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                title: Text(
                  'Detail Informasi',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => _shareInformasi(context),
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Colors.black87,
                    ),
                    tooltip: 'Bagikan',
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1200 : double.infinity,
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 0,
                    vertical: isDesktop ? 24 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Content Card
                      Container(
                        margin: EdgeInsets.all(isDesktop ? 0 : 16),
                        padding: EdgeInsets.all(isDesktop ? 32 : 20),
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
                        child: isDesktop && widget.informasi['gambar'] != null
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image on Left for Desktop
                                  _buildDesktopImage(),
                                  const SizedBox(width: 32),
                                  // Content on Right for Desktop
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildHeaderSection(),
                                        const SizedBox(height: 20),
                                        Text(
                                          widget.informasi['judul'] ??
                                              'Tanpa Judul',
                                          style: GoogleFonts.inter(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _buildMetadataCards(),
                                        const SizedBox(height: 24),
                                        Divider(
                                          color: Colors.grey[200],
                                          thickness: 1,
                                        ),
                                        const SizedBox(height: 24),
                                        _buildDescriptionSection(),
                                        _buildAdditionalInfo(),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mobile Layout
                                  if (widget.informasi['gambar'] != null) ...[
                                    _buildMobileImage(),
                                    const SizedBox(height: 20),
                                  ],
                                  _buildHeaderSection(),
                                  const SizedBox(height: 20),
                                  Text(
                                    widget.informasi['judul'] ?? 'Tanpa Judul',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildMetadataCards(),
                                  const SizedBox(height: 24),
                                  Divider(
                                    color: Colors.grey[200],
                                    thickness: 1,
                                  ),
                                  const SizedBox(height: 24),

                                  const SizedBox(height: 24),
                                  _buildDescriptionSection(),
                                  _buildAdditionalInfo(),
                                ],
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      if (!_isDeleting)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 0 : 16,
                          ),
                          child: _buildActionButtons(isDesktop),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Loading Overlay
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4169E1),
                        ),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Menghapus informasi...',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopImage() {
    return Container(
      width: 400,
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _supabase.storage
              .from('informasi-images')
              .getPublicUrl(widget.informasi['gambar']),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF4169E1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat gambar...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gambar tidak dapat dimuat',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileImage() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _supabase.storage
              .from('informasi-images')
              .getPublicUrl(widget.informasi['gambar']),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF4169E1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat gambar...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gambar tidak dapat dimuat',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    if (widget.informasi['deskripsi'] == null ||
        widget.informasi['deskripsi'].toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 20,
                color: Color(0xFF4169E1),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Deskripsi',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            widget.informasi['deskripsi'],
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.7,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeaderSection() {
    final ukmName =
        (widget.informasi['ukm'] as Map<String, dynamic>?)?['nama_ukm'] ??
        'Unit Activity';
    final status = widget.informasi['status'] ?? 'Draft';

    return Row(
      children: [
        // UKM Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
          child: Center(
            child: Text(
              ukmName.substring(0, 1).toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ukmName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(status).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataCards() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMetadataCard(
          Icons.access_time_outlined,
          'Dipublikasikan',
          _formatDateShort(widget.informasi['create_at']),
          const Color(0xFF4169E1),
        ),
        if (widget.informasi['periode_ukm'] != null)
          _buildMetadataCard(
            Icons.calendar_today_outlined,
            'Periode',
            widget.informasi['periode_ukm']['nama_periode'],
            Colors.orange,
          ),
        if (widget.informasi['users'] != null)
          _buildMetadataCard(
            Icons.person_outline,
            'Penulis',
            widget.informasi['users']['username'],
            Colors.green,
          ),
      ],
    );
  }

  Widget _buildMetadataCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Informasi Tambahan',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildInfoDetailRow(
                'ID Informasi',
                widget.informasi['id_informasi']?.toString() ?? '-',
                Icons.tag,
              ),
              const SizedBox(height: 16),
              _buildInfoDetailRow(
                'Kategori',
                widget.informasi['kategori']?.toString() ?? 'Umum',
                Icons.category_outlined,
              ),
              const SizedBox(height: 16),
              _buildInfoDetailRow(
                'Terakhir Diperbarui',
                _formatDate(widget.informasi['update_at']),
                Icons.update,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF4169E1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF4169E1)),
        ),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
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

  Widget _buildActionButtons(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.settings_outlined, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Kelola Informasi',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleteInformasi,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade400, width: 1.5),
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 18 : 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hapus',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      // Load UKM and Periode data
                      final ukmData = await _supabase
                          .from('ukm')
                          .select()
                          .order('nama_ukm', ascending: true);
                      final periodeData = await _supabase
                          .from('periode_ukm')
                          .select()
                          .order('nama_periode', ascending: true);

                      if (mounted) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditInformasiPage(
                              informasi: widget.informasi,
                              ukmList: List<Map<String, dynamic>>.from(ukmData),
                              periodeList: List<Map<String, dynamic>>.from(
                                periodeData,
                              ),
                            ),
                          ),
                        );

                        // If edit was successful, navigate back
                        if (result == true && mounted) {
                          Navigator.pop(context, true);
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error membuka halaman edit: $e',
                              style: GoogleFonts.inter(),
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 18 : 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: const Color(0xFF4169E1).withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Edit',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Aktif':
        return Colors.green;
      case 'Draft':
        return Colors.orange;
      case 'Arsip':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
