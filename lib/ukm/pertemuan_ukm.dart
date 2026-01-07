import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/ukm/detail_pertemuan_ukm.dart';
import 'package:unit_activity/ukm/add_pertemuan_ukm_page.dart';
import 'package:unit_activity/services/pertemuan_service.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';
import 'package:unit_activity/models/pertemuan_model.dart';
import 'package:intl/intl.dart';

class PertemuanUKMPage extends StatefulWidget {
  const PertemuanUKMPage({super.key});

  @override
  State<PertemuanUKMPage> createState() => _PertemuanUKMPageState();
}

class _PertemuanUKMPageState extends State<PertemuanUKMPage> {
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final PertemuanService _pertemuanService = PertemuanService();
  final UkmDashboardService _dashboardService = UkmDashboardService();
  final TextEditingController _searchController = TextEditingController();

  List<PertemuanModel> _pertemuanList = [];
  List<PertemuanModel> _filteredPertemuanList = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';

  // Calculate total pages based on data length
  int get _totalPages {
    if (_pertemuanList.isEmpty) return 0;
    return (_pertemuanList.length / _itemsPerPage).ceil();
  }

  // Get paginated data for current page
  List<PertemuanModel> get _paginatedPertemuan {
    if (_filteredPertemuanList.isEmpty) return [];
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex >= _filteredPertemuanList.length) return [];
    return _filteredPertemuanList.sublist(
      startIndex,
      endIndex > _filteredPertemuanList.length ? _filteredPertemuanList.length : endIndex,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPertemuan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredPertemuanList = _pertemuanList.where((p) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final topik = p.topik?.toLowerCase() ?? '';
          final lokasi = p.lokasi?.toLowerCase() ?? '';
          if (!topik.contains(_searchQuery.toLowerCase()) &&
              !lokasi.contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }
        return true;
      }).toList();
      _currentPage = 1;
    });
  }

  Future<void> _loadPertemuan() async {
    setState(() => _isLoading = true);
    try {
      // Load all pertemuan without UUID filter
      final pertemuan = await _pertemuanService.getAllPertemuan();
      setState(() {
        _pertemuanList = pertemuan;
        _filteredPertemuanList = pertemuan;
        _currentPage = 1; // Reset to first page
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Gradient
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4169E1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_note_rounded,
                    color: Colors.white,
                    size: isMobile ? 24 : 32,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar Pertemuan',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 18 : (isDesktop ? 28 : 24),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total ${_filteredPertemuanList.length} Pertemuan',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 13 : 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  ElevatedButton.icon(
                    onPressed: _navigateToAddPertemuan,
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Tambah Pertemuan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4169E1),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (isMobile) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToAddPertemuan,
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  'Tambah Pertemuan',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Cari pertemuan...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4169E1)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('Mendatang'),
                const SizedBox(width: 8),
                _buildFilterChip('Selesai'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pertemuan Cards
          _paginatedPertemuan.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _paginatedPertemuan.length,
                  itemBuilder: (context, index) {
                    final pertemuan = _paginatedPertemuan[index];
                    return _buildPertemuanCard(pertemuan);
                  },
                ),
          
          if (_filteredPertemuanList.isNotEmpty && _totalPages > 1) ...[
            const SizedBox(height: 24),
            _buildPagination(),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = label);
        _applyFilters();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4169E1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4169E1) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPertemuanCard(PertemuanModel pertemuan) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final tanggalStr = pertemuan.tanggal != null
        ? DateFormat('dd MMM yyyy').format(pertemuan.tanggal!)
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4169E1).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4169E1).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          final pertemuanMap = {
            'id': pertemuan.idPertemuan,
            'topik': pertemuan.topik,
            'tanggal': tanggalStr,
            'jamMulai': pertemuan.jamMulai,
            'jamAkhir': pertemuan.jamAkhir,
            'lokasi': pertemuan.lokasi,
          };
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPertemuanUKMPage(pertemuan: pertemuanMap),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_note_rounded,
                    color: const Color(0xFF4169E1),
                    size: isMobile ? 20 : 28,
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pertemuan.topik ?? 'Pertemuan',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 4 : 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4169E1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_rounded, size: isMobile ? 12 : 14, color: const Color(0xFF4169E1)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                pertemuan.lokasi ?? '-',
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4169E1),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Eye Icon
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.visibility_rounded,
                    color: const Color(0xFF4169E1),
                    size: isMobile ? 18 : 22,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 10 : 12),
            // Date & Time row
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 4 : 5),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: isMobile ? 10 : 12, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        tanggalStr,
                        style: GoogleFonts.inter(fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 4 : 5),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: isMobile ? 10 : 12, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        pertemuan.jamMulai ?? '00:00',
                        style: GoogleFonts.inter(fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.event_note_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada pertemuan',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Klik tombol "Tambah Pertemuan" untuk memulai',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
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
          Text(
            'Halaman $_currentPage dari $_totalPages',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: const Color(0xFF4169E1),
              ),
              IconButton(
                onPressed: _currentPage < _totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: const Color(0xFF4169E1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddPertemuan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPertemuanUKMPage()),
    );
    if (result == true) {
      _loadPertemuan();
    }
  }
}
