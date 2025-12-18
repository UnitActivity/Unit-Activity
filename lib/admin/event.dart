import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_event_page.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  String _sortBy = 'Urutkan';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Dummy data
  final List<Map<String, dynamic>> _allEvents = [
    {
      'namaEvent': 'Sparing Basket w/ UWIKA',
      'ukm': 'UKM Basket',
      'tipeEvent': 'Sparing',
      'lokasi': 'Lapangan Basket Kampus',
      'tanggal': '22-12-2025',
      'jam': '17:00',
      'dibuat': '20-12-2025',
      'deskripsi':
          'Pertandingan persahabatan basket antara tim UKM Basket dengan UWIKA. Event ini bertujuan untuk meningkatkan kemampuan dan kerjasama tim.',
    },
    {
      'namaEvent': 'Friendly Match Futsal',
      'ukm': 'UKM Futsal',
      'tipeEvent': 'Sparing',
      'lokasi': 'Lapangan Futsal Indoor',
      'tanggal': '01-12-2025',
      'jam': '15:00',
      'dibuat': '28-11-2025',
      'deskripsi':
          'Pertandingan futsal antar kampus untuk mempererat tali silaturahmi dan meningkatkan sportivitas.',
    },
    {
      'namaEvent': 'Mini Tournament Badminton',
      'ukm': 'UKM Badminton',
      'tipeEvent': 'Turnamen Internal',
      'lokasi': 'Merr Badminton Court',
      'tanggal': '05-12-2025',
      'jam': '10:00',
      'dibuat': '04-12-2025',
      'deskripsi':
          'Turnamen badminton internal untuk seluruh anggota UKM. Hadiah menarik untuk juara 1, 2, dan 3.',
    },
    {
      'namaEvent': 'Pentas Musik Akustik',
      'ukm': 'UKM Musik',
      'tipeEvent': 'Penampilan',
      'lokasi': 'Vidya Loka Lt.2',
      'tanggal': '14-12-2025',
      'jam': '18:00',
      'dibuat': '10-12-2025',
      'deskripsi':
          'Penampilan musik akustik dari anggota UKM Musik. Menampilkan berbagai genre musik dari pop, jazz, hingga indie.',
    },
    {
      'namaEvent': 'E-Sport Scrim Mobile Legends',
      'ukm': 'UKM E-Sport',
      'tipeEvent': 'Sparing',
      'lokasi': 'Ruangan 5A',
      'tanggal': '26-12-2025',
      'jam': '17:00',
      'dibuat': '23-12-2025',
      'deskripsi':
          'Latihan bersama (scrim) Mobile Legends untuk persiapan turnamen regional. Terbuka untuk semua anggota UKM E-Sport.',
    },
  ];

  List<Map<String, dynamic>> get _filteredEvents {
    var events = _allEvents.where((event) {
      if (_searchQuery.isEmpty) return true;
      return event['namaEvent'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          event['ukm'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          event['lokasi'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();

    return events;
  }

  int get _totalPages {
    return (_filteredEvents.length / _itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> get _paginatedEvents {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredEvents.sublist(
      startIndex,
      endIndex > _filteredEvents.length ? _filteredEvents.length : endIndex,
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
          'Daftar Event',
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

        // Filter Dropdown
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
            items: ['Urutkan', 'Nama Event', 'Tipe Event', 'Lokasi', 'Tanggal']
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
                // Nama Event
                Expanded(
                  flex: 3,
                  child: Text(
                    'Nama Event',
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
                // Lokasi
                Expanded(
                  flex: 2,
                  child: Text(
                    'Lokasi',
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
                // Jam
                Expanded(
                  flex: 1,
                  child: Text(
                    'Jam',
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
            itemCount: _paginatedEvents.length,
            itemBuilder: (context, index) {
              final event = _paginatedEvents[index];
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
                    // Nama Event
                    Expanded(
                      flex: 3,
                      child: Text(
                        event['namaEvent'] ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // UKM
                    Expanded(
                      flex: 2,
                      child: Text(
                        event['ukm'] ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Lokasi
                    Expanded(
                      flex: 2,
                      child: Text(
                        event['lokasi'] ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Tanggal
                    Expanded(
                      flex: 2,
                      child: Text(
                        event['tanggal'] ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Jam
                    Expanded(
                      flex: 1,
                      child: Text(
                        event['jam'] ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Detail Button
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailEventPage(event: event),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        color: const Color(0xFF4169E1),
                        tooltip: 'Lihat Detail',
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
      itemCount: _paginatedEvents.length,
      itemBuilder: (context, index) {
        final event = _paginatedEvents[index];

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
                      Icons.event,
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
                          event['namaEvent'] ?? '-',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event['ukm'] ?? '-',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildMobileInfoRow(
                Icons.location_on_outlined,
                event['lokasi'] ?? '-',
              ),
              const SizedBox(height: 8),
              _buildMobileInfoRow(
                Icons.calendar_today_outlined,
                '${event['tanggal'] ?? '-'} - ${event['jam'] ?? '-'}',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailEventPage(event: event),
                      ),
                    );
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
}
