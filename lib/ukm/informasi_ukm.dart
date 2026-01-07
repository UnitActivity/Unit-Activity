import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/services/informasi_service.dart';
import 'package:unit_activity/models/informasi_model.dart';
import 'package:unit_activity/ukm/add_informasi_ukm_page.dart';
import 'package:intl/intl.dart';

class InformasiUKMPage extends StatefulWidget {
  const InformasiUKMPage({super.key});

  @override
  State<InformasiUKMPage> createState() => _InformasiUKMPageState();
}

class _InformasiUKMPageState extends State<InformasiUKMPage> {
  final InformasiService _informasiService = InformasiService();
  final TextEditingController _searchController = TextEditingController();

  String _filterStatus = 'Semua';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 6;
  bool _isLoading = true;
  String _viewMode = 'grid'; // 'grid' or 'list'

  List<InformasiModel> _allInformasi = [];

  @override
  void initState() {
    super.initState();
    _loadInformasi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInformasi() async {
    setState(() => _isLoading = true);
    try {
      final informasi = await _informasiService.getAllInformasi();
      setState(() {
        _allInformasi = informasi;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<InformasiModel> get _filteredInformasi {
    return _allInformasi.where((item) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchSearch = item.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (item.deskripsi ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchSearch) return false;
      }
      // Status filter
      if (_filterStatus != 'Semua') {
        if (item.status != _filterStatus) return false;
      }
      return true;
    }).toList();
  }

  List<InformasiModel> get _paginatedInformasi {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex >= _filteredInformasi.length) return [];
    return _filteredInformasi.sublist(
      startIndex,
      endIndex > _filteredInformasi.length ? _filteredInformasi.length : endIndex,
    );
  }

  int get _totalPages => (_filteredInformasi.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          _buildStatsCards(isMobile),
          SizedBox(height: isMobile ? 16 : 24),

          // Filter Chips
          _buildFilterChips(isMobile),
          SizedBox(height: isMobile ? 12 : 16),

          // Search and Actions Bar
          _buildSearchAndActionsBar(isDesktop, isMobile),
          SizedBox(height: isMobile ? 16 : 24),

          // Content
          _isLoading
              ? _buildLoadingState()
              : _filteredInformasi.isEmpty
                  ? _buildEmptyState()
                  : _viewMode == 'grid'
                      ? _buildGridView(isDesktop, isMobile)
                      : _buildListView(),

          const SizedBox(height: 24),

          // Pagination
          if (_filteredInformasi.isNotEmpty && _totalPages > 0) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isMobile) {
    final totalInfo = _allInformasi.length;
    final activeInfo = _allInformasi.where((i) => i.status == 'Aktif').length;
    final draftInfo = _allInformasi.where((i) => i.status == 'Draft').length;

    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      children: [
        _buildStatCard('Total Informasi', totalInfo.toString(), Icons.article_outlined, const Color(0xFF4169E1), isMobile),
        _buildStatCard('Aktif', activeInfo.toString(), Icons.check_circle_outline, Colors.green, isMobile),
        _buildStatCard('Draft', draftInfo.toString(), Icons.edit_note_outlined, Colors.orange, isMobile),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: isMobile ? 4 : 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 16 : 20),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(label, style: GoogleFonts.inter(fontSize: isMobile ? 10 : 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Status', _filterStatus, ['Semua', 'Aktif', 'Draft'], (value) {
            setState(() {
              _filterStatus = value;
              _currentPage = 1;
            });
          }, isMobile),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String currentValue, List<String> options, Function(String) onChanged, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: GoogleFonts.inter(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          DropdownButton<String>(
            value: currentValue,
            underline: const SizedBox(),
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700], size: isMobile ? 18 : 20),
            style: GoogleFonts.inter(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w600, color: const Color(0xFF4169E1)),
            items: options.map((value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: (value) { if (value != null) onChanged(value); },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActionsBar(bool isDesktop, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 1;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari informasi...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // View Mode Toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.grid_view_rounded, size: 20, color: _viewMode == 'grid' ? const Color(0xFF4169E1) : Colors.grey[600]),
                onPressed: () => setState(() => _viewMode = 'grid'),
                tooltip: 'Grid View',
              ),
              IconButton(
                icon: Icon(Icons.view_list_rounded, size: 20, color: _viewMode == 'list' ? const Color(0xFF4169E1) : Colors.grey[600]),
                onPressed: () => setState(() => _viewMode = 'list'),
                tooltip: 'List View',
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _loadInformasi,
          icon: const Icon(Icons.refresh),
          color: const Color(0xFF4169E1),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _navigateToAddInformasi,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4169E1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: const Icon(Icons.add, size: 20),
          label: Text('Tambah', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.article_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Belum ada informasi', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Klik tombol "Tambah" untuk menambah informasi', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(bool isDesktop, bool isMobile) {
    final crossAxisCount = isDesktop ? 3 : (isMobile ? 1 : 2);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.2 : 0.85,
      ),
      itemCount: _paginatedInformasi.length,
      itemBuilder: (context, index) => _buildGridCard(_paginatedInformasi[index]),
    );
  }

  Widget _buildGridCard(InformasiModel info) {
    final tanggalStr = info.createAt != null ? DateFormat('dd MMM yyyy').format(info.createAt!) : '-';
    final statusColor = info.status == 'Aktif' ? Colors.green : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF4169E1).withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                if (info.gambar != null && info.gambar!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: Image.network(info.gambar!, width: double.infinity, height: 140, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(child: Icon(Icons.image, size: 48, color: Colors.grey[400]))),
                  )
                else
                  Center(child: Icon(Icons.article, size: 48, color: const Color(0xFF4169E1).withOpacity(0.5))),
                // Status Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                    child: Text(info.status ?? '-', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF4169E1).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('UKM', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF4169E1))),
                ),
                const SizedBox(height: 8),
                // Title
                Text(info.judul, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(tanggalStr, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedInformasi.length,
      itemBuilder: (context, index) => _buildListCard(_paginatedInformasi[index]),
    );
  }

  Widget _buildListCard(InformasiModel info) {
    final tanggalStr = info.createAt != null ? DateFormat('dd MMM yyyy').format(info.createAt!) : '-';
    final statusColor = info.status == 'Aktif' ? Colors.green : Colors.orange;

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
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF4169E1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: info.gambar != null && info.gambar!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(info.gambar!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.article, color: Colors.grey[400])),
                  )
                : Icon(Icons.article, size: 32, color: const Color(0xFF4169E1).withOpacity(0.5)),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                      child: Text(info.status ?? '-', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Text(tanggalStr, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 8),
                Text(info.judul, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                if (info.deskripsi != null) ...[
                  const SizedBox(height: 4),
                  Text(info.deskripsi!, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          // Actions
          Row(
            children: [
              IconButton(onPressed: () => _showEditDialog(info), icon: const Icon(Icons.edit_outlined), color: const Color(0xFF4169E1)),
              IconButton(onPressed: () => _showDeleteDialog(info), icon: const Icon(Icons.delete_outline), color: Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Halaman $_currentPage dari ${_totalPages > 0 ? _totalPages : 1}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          Row(
            children: [
              IconButton(onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null, icon: const Icon(Icons.chevron_left), color: const Color(0xFF4169E1)),
              IconButton(onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null, icon: const Icon(Icons.chevron_right), color: const Color(0xFF4169E1)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddInformasi() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddInformasiUKMPage()));
    if (result == true) _loadInformasi();
  }

  void _showEditDialog(InformasiModel info) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur edit akan segera hadir')));
  }

  void _showDeleteDialog(InformasiModel info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Hapus Informasi', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus informasi "${info.judul}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _informasiService.deleteInformasi(info.idInformasi!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informasi berhasil dihapus'), backgroundColor: Colors.green));
                  _loadInformasi();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
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
}
