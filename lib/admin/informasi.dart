import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'add_informasi_page.dart';
import 'detail_informasi_page.dart';

class InformasiPage extends StatefulWidget {
  const InformasiPage({super.key});

  @override
  State<InformasiPage> createState() => _InformasiPageState();
}

class _InformasiPageState extends State<InformasiPage> {
  final _supabase = Supabase.instance.client;

  String _filterStatus = 'Semua';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 6;
  bool _isLoading = true;
  String _viewMode = 'grid'; // 'grid' or 'list'

  List<Map<String, dynamic>> _allInformasi = [];
  List<Map<String, dynamic>> _allUkm = [];
  List<Map<String, dynamic>> _allPeriode = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_fetchInformasi(), _fetchUkm(), _fetchPeriode()]);
  }

  Future<void> _fetchInformasi() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('informasi')
          .select(
            '*, ukm(nama_ukm), periode_ukm(nama_periode), users(username)',
          )
          .order('create_at', ascending: false);

      setState(() {
        _allInformasi = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching informasi: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchUkm() async {
    try {
      final response = await _supabase
          .from('ukm')
          .select('id_ukm, nama_ukm')
          .order('nama_ukm');
      setState(() {
        _allUkm = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching UKM: $e');
    }
  }

  Future<void> _fetchPeriode() async {
    try {
      final response = await _supabase
          .from('periode_ukm')
          .select('id_periode, nama_periode')
          .order('nama_periode');
      setState(() {
        _allPeriode = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching Periode: $e');
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  List<Map<String, dynamic>> get _filteredInformasi {
    var informasi = _allInformasi.where((item) {
      // Filter pencarian
      if (_searchQuery.isNotEmpty) {
        final matchSearch =
            item['judul'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (item['deskripsi'] ?? '').toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
        if (!matchSearch) return false;
      }

      // Filter status
      if (_filterStatus != 'Semua') {
        if (item['status'] != _filterStatus) return false;
      }

      return true;
    }).toList();

    return informasi;
  }

  List<Map<String, dynamic>> get _paginatedInformasi {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredInformasi.sublist(
      startIndex,
      endIndex > _filteredInformasi.length
          ? _filteredInformasi.length
          : endIndex,
    );
  }

  int get _totalPages {
    return (_filteredInformasi.length / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Stats
        _buildHeader(isDesktop),
        const SizedBox(height: 24),

        // Filter Chips
        _buildFilterChips(),
        const SizedBox(height: 16),

        // Search and Actions Bar
        _buildSearchAndActionsBar(isDesktop),
        const SizedBox(height: 24),

        // Content
        _isLoading
            ? _buildLoadingState()
            : _filteredInformasi.isEmpty
            ? _buildEmptyState()
            : _viewMode == 'grid'
            ? _buildGridView(isDesktop)
            : _buildListView(),

        const SizedBox(height: 24),

        // Pagination
        if (_filteredInformasi.isNotEmpty) _buildPagination(),
      ],
    );
  }

  Widget _buildHeader(bool isDesktop) {
    final totalInfo = _allInformasi.length;
    final activeInfo = _allInformasi
        .where((i) => i['status'] == 'Aktif')
        .length;
    final draftInfo = _allInformasi.where((i) => i['status'] == 'Draft').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Stats Cards
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              'Total Informasi',
              totalInfo.toString(),
              Icons.article_outlined,
              const Color(0xFF4169E1),
            ),
            _buildStatCard(
              'Aktif',
              activeInfo.toString(),
              Icons.check_circle_outline,
              Colors.green,
            ),
            _buildStatCard(
              'Draft',
              draftInfo.toString(),
              Icons.edit_note_outlined,
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Status Filter
          _buildFilterChip(
            'Status',
            _filterStatus,
            ['Semua', 'Aktif', 'Draft', 'Arsip'],
            (value) => setState(() {
              _filterStatus = value;
              _currentPage = 1;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          DropdownButton<String>(
            value: currentValue,
            underline: const SizedBox(),
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4169E1),
            ),
            items: options.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActionsBar(bool isDesktop) {
    return Row(
      children: [
        // Search Bar
        Expanded(
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 1;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari informasi...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _currentPage = 1;
                      }),
                    )
                  : null,
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
                borderSide: const BorderSide(
                  color: Color(0xFF4169E1),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // View Mode Toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.grid_view_rounded,
                  color: _viewMode == 'grid'
                      ? const Color(0xFF4169E1)
                      : Colors.grey[600],
                ),
                onPressed: () => setState(() => _viewMode = 'grid'),
                tooltip: 'Grid View',
              ),
              IconButton(
                icon: Icon(
                  Icons.view_list_rounded,
                  color: _viewMode == 'list'
                      ? const Color(0xFF4169E1)
                      : Colors.grey[600],
                ),
                onPressed: () => setState(() => _viewMode = 'list'),
                tooltip: 'List View',
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Add Button
        ElevatedButton.icon(
          onPressed: _showAddInformasiDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4169E1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.add, size: 20),
          label: Text(
            'Tambah',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
            ),
            SizedBox(height: 16),
            Text('Memuat data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Informasi',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada hasil untuk pencarian "$_searchQuery"'
                  : 'Klik tombol Tambah untuk membuat informasi baru',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(bool isDesktop) {
    final crossAxisCount = isDesktop ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _paginatedInformasi.length,
      itemBuilder: (context, index) {
        final info = _paginatedInformasi[index];
        return _buildGridCard(info);
      },
    );
  }

  Widget _buildGridCard(Map<String, dynamic> info) {
    final ukmName =
        (info['ukm'] as Map<String, dynamic>?)?['nama_ukm'] ?? 'UKM';
    final status = info['status'] ?? 'Draft';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailInformasiPage(informasi: info),
          ),
        );
        _fetchInformasi(); // Refresh after returning
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Status Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: info['gambar'] != null
                        ? Image.network(
                            _supabase.storage
                                .from('informasi-images')
                                .getPublicUrl(info['gambar']),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // UKM Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4169E1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ukmName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4169E1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Expanded(
                      child: Text(
                        info['judul'] ?? 'Tanpa Judul',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(info['create_at']),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedInformasi.length,
      itemBuilder: (context, index) {
        final info = _paginatedInformasi[index];
        return _buildListCard(info);
      },
    );
  }

  Widget _buildListCard(Map<String, dynamic> info) {
    final ukmName =
        (info['ukm'] as Map<String, dynamic>?)?['nama_ukm'] ?? 'UKM';
    final periodeName =
        (info['periode_ukm'] as Map<String, dynamic>?)?['nama_periode'];
    final status = info['status'] ?? 'Draft';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailInformasiPage(informasi: info),
          ),
        );
        _fetchInformasi(); // Refresh after returning
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 120,
                height: 120,
                child: info['gambar'] != null
                    ? Image.network(
                        _supabase.storage
                            .from('informasi-images')
                            .getPublicUrl(info['gambar']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // UKM Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4169E1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ukmName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4169E1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      info['judul'] ?? 'Tanpa Judul',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Description
                    if (info['deskripsi'] != null)
                      Text(
                        info['deskripsi'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // Meta Info
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(info['create_at']),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (periodeName != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              periodeName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Arrow Icon
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
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

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Info Text
          Text(
            'Menampilkan ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage) > _filteredInformasi.length ? _filteredInformasi.length : _currentPage * _itemsPerPage} dari ${_filteredInformasi.length}',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
          ),

          // Navigation Buttons
          Row(
            children: [
              // Previous Button
              IconButton(
                onPressed: _currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: const Color(0xFF4169E1),
                disabledColor: Colors.grey[400],
              ),

              // Page Numbers
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              // Next Button
              IconButton(
                onPressed: _currentPage < _totalPages
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: const Color(0xFF4169E1),
                disabledColor: Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddInformasiDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddInformasiPage(ukmList: _allUkm, periodeList: _allPeriode),
      ),
    );

    if (result == true) {
      _fetchInformasi();
    }
  }
}
