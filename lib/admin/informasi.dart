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

  String _sortBy = 'Urutkan';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _totalPages = 1;
  final int _itemsPerPage = 5;
  bool _isLoading = true;

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
      if (_searchQuery.isEmpty) return true;
      return item['judul'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item['kategori'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Daftar Informasi',
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),

        // Search and Filter Bar
        _buildSearchAndFilterBar(isDesktop),
        const SizedBox(height: 24),

        // Table
        if (isDesktop) _buildDesktopTable() else _buildMobileList(),

        const SizedBox(height: 24),

        // Pagination
        _buildPagination(),
      ],
    );
  }

  Widget _buildSearchAndFilterBar(bool isDesktop) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      children: [
        // Search Bar
        SizedBox(
          width: isDesktop ? 400 : double.infinity,
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 1; // Reset to first page on search
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari Data',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
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
                borderSide: const BorderSide(color: Color(0xFF4169E1)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Filter and Add Button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sort Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _sortBy,
                underline: const SizedBox(),
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[700]),
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                items: ['Urutkan', 'Judul', 'Kategori', 'Tanggal', 'Status']
                    .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    })
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _sortBy = newValue!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),

            // Add Button
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement add informasi
                _showAddInformasiDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Tambah',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Gambar
                SizedBox(
                  width: 80,
                  child: Text(
                    'Gambar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Judul
                Expanded(
                  flex: 3,
                  child: Text(
                    'Judul',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // UKM
                Expanded(
                  flex: 2,
                  child: Text(
                    'UKM',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // Periode
                Expanded(
                  flex: 2,
                  child: Text(
                    'Periode',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // Tanggal
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tanggal',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // Status
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // Aksi
                SizedBox(
                  width: 100,
                  child: Text(
                    'Aksi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _paginatedInformasi.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada informasi',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _paginatedInformasi.length,
                  itemBuilder: (context, index) {
                    final info = _paginatedInformasi[index];
                    final isEven = index % 2 == 0;
                    final ukmName =
                        (info['ukm'] as Map<String, dynamic>?)?['nama_ukm'] ??
                        '-';
                    final periodeName =
                        (info['periode_ukm']
                            as Map<String, dynamic>?)?['nama_periode'] ??
                        '-';
                    final status = info['status'] ?? 'Draft';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailInformasiPage(informasi: info),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isEven ? Colors.white : Colors.grey[50],
                        ),
                        child: Row(
                          children: [
                            // Gambar
                            SizedBox(
                              width: 80,
                              height: 60,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: info['gambar'] != null
                                    ? Image.network(
                                        _supabase.storage
                                            .from('informasi-images')
                                            .getPublicUrl(info['gambar']),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                        loadingBuilder:
                                            (
                                              context,
                                              child,
                                              loadingProgress,
                                            ) => loadingProgress == null
                                            ? child
                                            : Container(
                                                color: Colors.grey[200],
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    value:
                                                        loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Judul
                            Expanded(
                              flex: 3,
                              child: Text(
                                info['judul'] ?? '-',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // UKM
                            Expanded(
                              flex: 2,
                              child: Text(
                                ukmName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Periode
                            Expanded(
                              flex: 2,
                              child: Text(
                                periodeName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Tanggal
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatDate(info['create_at']),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            // Status
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(status),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            // Aksi
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailInformasiPage(
                                                informasi: info,
                                              ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.visibility),
                                    color: const Color(0xFF4169E1),
                                    iconSize: 20,
                                    tooltip: 'Lihat Detail',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // TODO: Implement edit
                                    },
                                    icon: const Icon(Icons.edit),
                                    color: Colors.orange,
                                    iconSize: 20,
                                    tooltip: 'Edit',
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
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
          ),
        ),
      );
    }

    if (_allInformasi.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Belum ada informasi',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Klik tombol Tambah untuk membuat informasi baru',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: 8,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedInformasi.length,
      itemBuilder: (context, index) {
        final info = _paginatedInformasi[index];
        final ukmName =
            (info['ukm'] as Map<String, dynamic>?)?['nama_ukm'] ?? 'UKM';
        final periodeName =
            (info['periode_ukm'] as Map<String, dynamic>?)?['nama_periode'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailInformasiPage(informasi: info),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (UKM info)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 10 : 12,
                    isSmallScreen ? 10 : 12,
                    isSmallScreen ? 10 : 12,
                    isSmallScreen ? 6 : 8,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: isSmallScreen ? 16 : 20,
                        backgroundColor: const Color.fromRGBO(65, 105, 225, 1),
                        child: Text(
                          ukmName.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ukmName,
                              style: GoogleFonts.inter(
                                fontSize: isSmallScreen ? 13 : 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 1 : 2),
                            Text(
                              _formatDate(info['create_at']),
                              style: GoogleFonts.inter(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Image
                if (info['gambar'] != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                    child: AspectRatio(
                      aspectRatio: isSmallScreen ? 4 / 3 : 16 / 9,
                      child: Image.network(
                        _supabase.storage
                            .from('informasi-images')
                            .getPublicUrl(info['gambar']),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4169E1),
                                ),
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
                                  Icon(
                                    Icons.broken_image_rounded,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gambar tidak dapat dimuat',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    height: isSmallScreen ? 150 : 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(0),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: isSmallScreen ? 36 : 48,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Text(
                            'Tidak ada gambar',
                            style: GoogleFonts.inter(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        info['judul'] ?? 'Tanpa Judul',
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Description (if exists)
                      if (info['deskripsi'] != null &&
                          info['deskripsi'].toString().trim().isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          info['deskripsi'],
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: isSmallScreen ? 8 : 10),

                      // Additional info row
                      Row(
                        children: [
                          // Periode info
                          if (periodeName != null) ...[
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 6 : 8,
                                  vertical: isSmallScreen ? 3 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: isSmallScreen ? 12 : 13,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: isSmallScreen ? 4 : 5),
                                    Flexible(
                                      child: Text(
                                        periodeName,
                                        style: GoogleFonts.inter(
                                          fontSize: isSmallScreen ? 10 : 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          // View detail hint
                          Row(
                            children: [
                              Text(
                                'Lihat detail',
                                style: GoogleFonts.inter(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4169E1),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 3 : 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: isSmallScreen ? 11 : 12,
                                color: const Color(0xFF4169E1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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

        const SizedBox(width: 16),

        // Page Indicator
        Text(
          '$_currentPage Dari $_totalPages',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),

        const SizedBox(width: 16),

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

    // Refresh data jika berhasil tambah
    if (result == true) {
      // Reload informasi list if needed
      setState(() {});
    }
  }
}
