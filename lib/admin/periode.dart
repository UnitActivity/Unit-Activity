import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PeriodePage extends StatefulWidget {
  const PeriodePage({super.key});

  @override
  State<PeriodePage> createState() => _PeriodePageState();
}

class _PeriodePageState extends State<PeriodePage> {
  String _sortBy = 'Urutkan';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _totalPages = 2;
  final int _itemsPerPage = 8;

  // Sample data - replace with actual data from API/database
  final List<Map<String, dynamic>> _allPeriode = [
    {
      'periode': '2025.1',
      'tanggalAwal': '1-08-2025',
      'tanggalAkhir': '31-01-2026',
      'dibuat': '10-12-2025',
    },
    {
      'periode': '2024.2',
      'tanggalAwal': '1-02-2025',
      'tanggalAkhir': '31-07-2025',
      'dibuat': '10-12-2025',
    },
    {
      'periode': '2024.1',
      'tanggalAwal': '1-08-2024',
      'tanggalAkhir': '31-01-2024',
      'dibuat': '10-12-2025',
    },
    {
      'periode': '2023.2',
      'tanggalAwal': '1-02-2024',
      'tanggalAkhir': '31-07-2024',
      'dibuat': '10-12-2025',
    },
    {
      'periode': '2023.1',
      'tanggalAwal': '1-08-2023',
      'tanggalAkhir': '31-01-2024',
      'dibuat': '10-12-2025',
    },
    {
      'periode': '2022.2',
      'tanggalAwal': '1-02-2023',
      'tanggalAkhir': '31-07-2023',
      'dibuat': '10-12-2025',
    },
    {
      'periode': '2022.1',
      'tanggalAwal': '1-08-2022',
      'tanggalAkhir': '31-01-2023',
      'dibuat': '10-12-2025',
    },
    {
      'periode': '2021.2',
      'tanggalAwal': '1-02-2022',
      'tanggalAkhir': '31-01-2022',
      'dibuat': '10-12-2025',
    },
  ];

  List<Map<String, dynamic>> get _filteredPeriode {
    var periode = _allPeriode.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item['periode'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item['tanggalAwal'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item['tanggalAkhir'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();

    return periode;
  }

  List<Map<String, dynamic>> get _paginatedPeriode {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredPeriode.sublist(
      startIndex,
      endIndex > _filteredPeriode.length ? _filteredPeriode.length : endIndex,
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
          'Daftar Periode',
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
                items: ['Urutkan', 'Periode', 'Tanggal Awal', 'Tanggal Akhir']
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
                // TODO: Implement add periode
                _showAddPeriodeDialog();
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
                // Tanggal Awal
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tanggal Awal',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // Tanggal Akhir
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tanggal Akhir',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // Dibuat
                Expanded(
                  flex: 2,
                  child: Text(
                    'Dibuat',
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
            itemCount: _paginatedPeriode.length,
            itemBuilder: (context, index) {
              final periode = _paginatedPeriode[index];
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
                    // Periode
                    Expanded(
                      flex: 2,
                      child: Text(
                        periode['periode'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Tanggal Awal
                    Expanded(
                      flex: 2,
                      child: Text(
                        periode['tanggalAwal'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Tanggal Akhir
                    Expanded(
                      flex: 2,
                      child: Text(
                        periode['tanggalAkhir'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Dibuat
                    Expanded(
                      flex: 2,
                      child: Text(
                        periode['dibuat'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
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
      itemCount: _paginatedPeriode.length,
      itemBuilder: (context, index) {
        final periode = _paginatedPeriode[index];

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
                      Icons.calendar_month,
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
                          'Periode ${periode['periode']}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tahun Akademik',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
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
                Icons.play_arrow,
                'Mulai: ${periode['tanggalAwal']}',
              ),
              const SizedBox(height: 8),
              _buildMobileInfoRow(
                Icons.stop,
                'Berakhir: ${periode['tanggalAkhir']}',
              ),
              const SizedBox(height: 8),
              _buildMobileInfoRow(
                Icons.access_time_outlined,
                'Dibuat: ${periode['dibuat']}',
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

  void _showAddPeriodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Tambah Periode',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Fitur tambah periode akan segera tersedia.',
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
}
