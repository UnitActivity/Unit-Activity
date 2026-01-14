import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/models/informasi_model.dart';
import 'package:unit_activity/services/informasi_service.dart';
import 'package:unit_activity/ukm/edit_informasi_ukm_page.dart';
import 'package:intl/intl.dart';

class DetailInformasiUKMPage extends StatefulWidget {
  final InformasiModel informasi;

  const DetailInformasiUKMPage({super.key, required this.informasi});

  @override
  State<DetailInformasiUKMPage> createState() => _DetailInformasiUKMPageState();
}

class _DetailInformasiUKMPageState extends State<DetailInformasiUKMPage> {
  late InformasiModel _informasi;
  final InformasiService _informasiService = InformasiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _informasi = widget.informasi;
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return Supabase.instance.client.storage
        .from('informasi-images')
        .getPublicUrl(imagePath);
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInformasiUKMPage(informasi: _informasi),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informasi berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    try {
      if (_informasi.idInformasi == null) return;
      final updated =
          await _informasiService.getInformasiById(_informasi.idInformasi!);
      if (updated != null && mounted) {
        setState(() {
          _informasi = updated;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error refreshing data: $e');
      }
    }
  }

  Future<void> _handleDelete() async {
    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while potentially loading
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Hapus Informasi',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus informasi "${_informasi.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              setState(() => _isLoading = true); // Show loading
              try {
                await _informasiService.deleteInformasi(_informasi.idInformasi!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informasi berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, true); // Return true to refresh list
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final tanggalStr = _informasi.createAt != null
        ? DateFormat('dd MMMM yyyy HH:mm').format(_informasi.createAt!)
        : '-';

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF4169E1),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _informasi.gambar != null &&
                            _informasi.gambar!.isNotEmpty
                        ? Image.network(
                            _getImageUrl(_informasi.gambar),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    size: 50, color: Colors.grey),
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF4169E1).withOpacity(0.1),
                            child: Center(
                              child: Icon(
                                Icons.article_outlined,
                                size: 80,
                                color: const Color(0xFF4169E1).withOpacity(0.5),
                              ),
                            ),
                          ),
                  ),
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context, true), // Return true to refresh list potentially
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        onPressed: _handleEdit,
                        tooltip: 'Edit Informasi',
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _informasi.status == 'Aktif'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _informasi.status == 'Aktif'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              child: Text(
                                _informasi.status ?? '-',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _informasi.status == 'Aktif'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time,
                                size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              tanggalStr,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          _informasi.judul,
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Author info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  const Color(0xFF4169E1).withOpacity(0.1),
                              child: Text(
                                (_informasi.createBy ?? 'U')[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4169E1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dibuat oleh ${_informasi.createBy ?? 'Unknown'}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Description
                        Text(
                          _informasi.deskripsi ?? 'Tidak ada deskripsi',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Delete Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _handleDelete,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: Text(
                              'Hapus Informasi',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
