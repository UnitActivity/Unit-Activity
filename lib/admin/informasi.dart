import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InformasiPage extends StatefulWidget {
  const InformasiPage({super.key});

  @override
  State<InformasiPage> createState() => _InformasiPageState();
}

class _InformasiPageState extends State<InformasiPage> {
  String _sortBy = 'Urutkan';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _totalPages = 1;
  final int _itemsPerPage = 5;

  // Sample data - replace with actual data from API/database
  final List<Map<String, dynamic>> _allInformasi = [
    {
      'judul': 'Pendaftaran UKM Periode 2025.1 Dibuka',
      'kategori': 'Pengumuman',
      'tanggal': '15-12-2025',
      'penulis': 'Admin',
      'status': 'Aktif',
    },
    {
      'judul': 'Jadwal Rapat Koordinasi UKM',
      'kategori': 'Agenda',
      'tanggal': '12-12-2025',
      'penulis': 'Admin',
      'status': 'Aktif',
    },
    {
      'judul': 'Peraturan Baru Kegiatan UKM',
      'kategori': 'Peraturan',
      'tanggal': '10-12-2025',
      'penulis': 'Admin',
      'status': 'Aktif',
    },
    {
      'judul': 'Lomba Antar UKM 2025',
      'kategori': 'Event',
      'tanggal': '08-12-2025',
      'penulis': 'Admin',
      'status': 'Aktif',
    },
    {
      'judul': 'Panduan Penggunaan Aplikasi Unit Activity',
      'kategori': 'Panduan',
      'tanggal': '05-12-2025',
      'penulis': 'Admin',
      'status': 'Aktif',
    },
  ];

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
                  vertical: 12,
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
                // Checkbox
                SizedBox(
                  width: 50,
                  child: Checkbox(
                    value: false,
                    onChanged: (value) {},
                    activeColor: const Color(0xFF4169E1),
                  ),
                ),
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
                // Kategori
                Expanded(
                  flex: 2,
                  child: Text(
                    'Kategori',
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
                // Penulis
                Expanded(
                  flex: 1,
                  child: Text(
                    'Penulis',
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
                // Detail
                Expanded(
                  flex: 1,
                  child: Text(
                    'Detail',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _paginatedInformasi.length,
            itemBuilder: (context, index) {
              final info = _paginatedInformasi[index];
              final isEven = index % 2 == 0;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isEven ? Colors.white : Colors.grey[50],
                ),
                child: Row(
                  children: [
                    // Checkbox
                    SizedBox(
                      width: 50,
                      child: Checkbox(
                        value: false,
                        onChanged: (value) {},
                        activeColor: const Color(0xFF4169E1),
                      ),
                    ),
                    // Judul
                    Expanded(
                      flex: 3,
                      child: Text(
                        info['judul'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Kategori
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            info['kategori'],
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          info['kategori'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(info['kategori']),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Tanggal
                    Expanded(
                      flex: 2,
                      child: Text(
                        info['tanggal'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Penulis
                    Expanded(
                      flex: 1,
                      child: Text(
                        info['penulis'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
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
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          info['status'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Detail Button
                    Expanded(
                      flex: 1,
                      child: TextButton(
                        onPressed: () {
                          _showDetailDialog(info);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Lihat',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
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

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedInformasi.length,
      itemBuilder: (context, index) {
        final info = _paginatedInformasi[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4169E1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info,
                      color: Color(0xFF4169E1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info['judul'],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              info['kategori'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            info['kategori'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(info['kategori']),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: false,
                    onChanged: (value) {},
                    activeColor: const Color(0xFF4169E1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildMobileInfoRow(
                Icons.calendar_today_outlined,
                info['tanggal'],
              ),
              const SizedBox(height: 8),
              _buildMobileInfoRow(Icons.person_outline, info['penulis']),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      info['status'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showDetailDialog(info);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Lihat Detail',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pengumuman':
        return const Color(0xFF4169E1);
      case 'Agenda':
        return const Color(0xFFF59E0B);
      case 'Peraturan':
        return const Color(0xFFEF4444);
      case 'Event':
        return const Color(0xFF8B5CF6);
      case 'Panduan':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  void _showAddInformasiDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Tambah Informasi',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Fitur tambah informasi akan segera tersedia.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.inter(
                color: const Color(0xFF4169E1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detail Informasi',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Judul', info['judul']),
              const SizedBox(height: 12),
              _buildDetailRow('Kategori', info['kategori']),
              const SizedBox(height: 12),
              _buildDetailRow('Tanggal', info['tanggal']),
              const SizedBox(height: 12),
              _buildDetailRow('Penulis', info['penulis']),
              const SizedBox(height: 12),
              _buildDetailRow('Status', info['status']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.inter(
                color: const Color(0xFF4169E1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
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
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
