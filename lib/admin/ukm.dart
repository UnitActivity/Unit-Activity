import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UkmPage extends StatefulWidget {
  const UkmPage({super.key});

  @override
  State<UkmPage> createState() => _UkmPageState();
}

class _UkmPageState extends State<UkmPage> {
  String _sortBy = 'Urutkan';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _totalPages = 2;
  final int _itemsPerPage = 8;

  // Sample data - replace with actual data from API/database
  final List<Map<String, dynamic>> _allUkm = [
    {
      'id': '001',
      'ukm': 'Basket',
      'email': 'ukmbasket@ukdc.ac.id',
      'detail': 'Lihat',
      'createdAt': '10-12-2025',
    },
    {
      'id': '002',
      'ukm': 'Badminton',
      'email': 'ukmbadminton@ukdc.ac.id',
      'detail': 'Lihat',
      'createdAt': '10-12-2025',
    },
    {
      'id': '003',
      'ukm': 'Dance',
      'email': 'ukmdance@ukdc.ac.id',
      'detail': 'Lihat',
      'createdAt': '10-12-2025',
    },
    {
      'id': '004',
      'ukm': 'E-Sport',
      'email': 'ukmesport@ukdc.ac.id',
      'detail': 'Lihat',
      'createdAt': '10-12-2025',
    },
    {
      'id': '005',
      'ukm': 'Futsal',
      'email': 'ukmfutsal@ukdc.ac.id',
      'detail': 'Lihat',
      'createdAt': '10-12-2025',
    },
    {
      'id': '006',
      'ukm': 'Jurnalistik',
      'email': 'ukmjurnalistik@ukdc.ac.id',
      'detail': 'Lihat',
      'createdAt': '10-12-2025',
    },
    {
      'id': '007',
      'ukm': 'Musik',
      'email': 'ukmmusik@ukdc.ac.id',
      'detail': 'Lihat',
      'createdAt': '10-12-2025',
    },
    {
      'id': '008',
      'ukm': 'Kulintang',
      'email': 'ukmkulintang@ukdc.ac.id',
      'detail': 'Lihat',
      'createdAt': '10-12-2025',
    },
  ];

  List<Map<String, dynamic>> get _filteredUkm {
    var ukm = _allUkm.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item['id'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item['ukm'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item['email'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();

    return ukm;
  }

  List<Map<String, dynamic>> get _paginatedUkm {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredUkm.sublist(
      startIndex,
      endIndex > _filteredUkm.length ? _filteredUkm.length : endIndex,
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
          'Daftar UKM',
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
                items: ['Urutkan', 'ID UKM', 'Nama UKM', 'Email', 'Tanggal']
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
                // TODO: Implement add UKM
                _showAddUkmDialog();
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
                // ID UKM
                Expanded(
                  flex: 2,
                  child: Text(
                    'ID UKM',
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
                // Email
                Expanded(
                  flex: 3,
                  child: Text(
                    'Email',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // Detail
                Expanded(
                  flex: 2,
                  child: Text(
                    'Detail',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // Created At
                Expanded(
                  flex: 2,
                  child: Text(
                    'create at',
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
            itemCount: _paginatedUkm.length,
            itemBuilder: (context, index) {
              final ukm = _paginatedUkm[index];
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
                    // ID UKM
                    Expanded(
                      flex: 2,
                      child: Text(
                        ukm['id'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // UKM
                    Expanded(
                      flex: 2,
                      child: Text(
                        ukm['ukm'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Email
                    Expanded(
                      flex: 3,
                      child: Text(
                        ukm['email'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Detail Button
                    Expanded(
                      flex: 2,
                      child: TextButton(
                        onPressed: () {
                          _showDetailDialog(ukm);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          ukm['detail'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    // Created At
                    Expanded(
                      flex: 2,
                      child: Text(
                        ukm['createdAt'],
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
      itemCount: _paginatedUkm.length,
      itemBuilder: (context, index) {
        final ukm = _paginatedUkm[index];

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
                    child: Icon(
                      Icons.groups,
                      color: const Color(0xFF4169E1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ukm['ukm'],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${ukm['id']}',
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
              _buildMobileInfoRow(Icons.email_outlined, ukm['email']),
              const SizedBox(height: 8),
              _buildMobileInfoRow(
                Icons.calendar_today_outlined,
                ukm['createdAt'],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showDetailDialog(ukm);
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

  void _showAddUkmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Tambah UKM',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Fitur tambah UKM akan segera tersedia.',
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

  void _showDetailDialog(Map<String, dynamic> ukm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detail UKM',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID UKM', ukm['id']),
            const SizedBox(height: 12),
            _buildDetailRow('Nama UKM', ukm['ukm']),
            const SizedBox(height: 12),
            _buildDetailRow('Email', ukm['email']),
            const SizedBox(height: 12),
            _buildDetailRow('Dibuat pada', ukm['createdAt']),
          ],
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
