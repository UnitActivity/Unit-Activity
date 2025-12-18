import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class DetailInformasiPage extends StatelessWidget {
  final Map<String, dynamic> informasi;

  const DetailInformasiPage({super.key, required this.informasi});

  String _formatDate(String? dateStr) {
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
${informasi['judul']}

${informasi['deskripsi'] ?? ''}

Status: ${informasi['status']}
${informasi['ukm'] != null ? 'UKM: ${informasi['ukm']['nama_ukm']}\n' : ''}
Tanggal: ${_formatDate(informasi['create_at'])}
    '''
            .trim();

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF4169E1),
                  child: Text(
                    informasi['ukm'] != null
                        ? (informasi['ukm']['nama_ukm'] as String)
                              .substring(0, 1)
                              .toUpperCase()
                        : 'U',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
                        informasi['ukm'] != null
                            ? informasi['ukm']['nama_ukm']
                            : 'Unit Activity',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatDate(informasi['create_at']),
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
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (informasi['gambar'] != null)
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      supabase.storage
                          .from('informasi-images')
                          .getPublicUrl(informasi['gambar']),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4169E1),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Actions (hanya Share)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () => _shareInformasi(context),
                        icon: const Icon(Icons.share_outlined),
                        iconSize: 26,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(informasi['status']),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      informasi['status'] ?? 'Draft',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    informasi['judul'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Description
                if (informasi['deskripsi'] != null &&
                    informasi['deskripsi'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      informasi['deskripsi'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Additional Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (informasi['periode_ukm'] != null)
                        _buildInfoRow(
                          Icons.calendar_today_outlined,
                          'Periode',
                          informasi['periode_ukm']['nama_periode'],
                        ),
                      if (informasi['users'] != null)
                        _buildInfoRow(
                          Icons.person_outline,
                          'Dipublikasikan oleh',
                          informasi['users']['username'],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
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
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
