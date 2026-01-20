import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/event_service_new.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';
import 'package:unit_activity/ukm/add_event_page.dart';
import 'package:unit_activity/ukm/detail_event_ukm.dart';
import 'package:intl/intl.dart';

class EventUKMPage extends StatefulWidget {
  const EventUKMPage({super.key});

  @override
  State<EventUKMPage> createState() => _EventUKMPageState();
}

class _EventUKMPageState extends State<EventUKMPage> {
  final EventService _eventService = EventService();
  final UkmDashboardService _dashboardService = UkmDashboardService();
  final _supabase = Supabase.instance.client;

  // Helper to get public URL for event image
  String _getEventImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) return imagePath;
    // Otherwise, get public URL from event-images bucket
    return _supabase.storage.from('event-images').getPublicUrl(imagePath);
  }

  List<Map<String, dynamic>> _eventList = [];
  List<Map<String, dynamic>> _filteredEventList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'Semua';
  String _selectedAccessFilter = 'Semua'; // TAMBAHAN: Filter Jenis Akses
  String _searchQuery = '';
  
  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  List<Map<String, dynamic>> get _paginatedEvents {
    if (_filteredEventList.isEmpty) return [];
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex >= _filteredEventList.length) return [];
    
    return _filteredEventList.sublist(
      startIndex,
      endIndex > _filteredEventList.length
          ? _filteredEventList.length
          : endIndex,
    );
  }
  
  int get _totalPages {
    if (_filteredEventList.isEmpty) return 0;
    return (_filteredEventList.length / _itemsPerPage).ceil();
  }

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current UKM ID
      final ukmId = await _dashboardService.getCurrentUkmId();
      if (ukmId == null) {
        throw Exception('Tidak dapat mengidentifikasi UKM');
      }

      // Get current periode
      final periode = await _dashboardService.getCurrentPeriode(ukmId);
      final periodeId = periode?['id_periode'] as String?;

      // Load events
      final events = await _eventService.getEventsByUkm(
        ukmId: ukmId,
        periodeId: periodeId,
      );

      setState(() {
        _eventList = events;
        _filteredEventList = events;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _errorMessage = 'Gagal memuat data event: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEventList = _eventList.where((event) {
        // 1. Search filter
        final matchesSearch =
            _searchQuery.isEmpty ||
            event['nama_event'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        // 2. Status filter (Waktu)
        bool matchesStatus = true;
        if (_selectedFilter != 'Semua') {
          final now = DateTime.now();
          final tanggalMulai = event['tanggal_mulai'] != null
              ? DateTime.parse(event['tanggal_mulai'])
              : null;
          final tanggalAkhir = event['tanggal_akhir'] != null
              ? DateTime.parse(event['tanggal_akhir'])
              : null;

          if (_selectedFilter == 'Mendatang' && tanggalMulai != null) {
            matchesStatus = tanggalMulai.isAfter(now);
          } else if (_selectedFilter == 'Berlangsung' &&
              tanggalMulai != null &&
              tanggalAkhir != null) {
            matchesStatus =
                now.isAfter(tanggalMulai) && now.isBefore(tanggalAkhir);
          } else if (_selectedFilter == 'Selesai' && tanggalAkhir != null) {
            matchesStatus = tanggalAkhir.isBefore(now);
          }
        }

        // 3. Access Type Filter (TAMBAHAN: Filter Jenis Akses)
        bool matchesAccess = true;
        if (_selectedAccessFilter != 'Semua') {
          final tipeAkses = event['tipe_akses']?.toString().toLowerCase() ?? '';
          // Asumsi data di database: 'umum' atau 'anggota'
          if (_selectedAccessFilter == 'Umum') {
            matchesAccess = tipeAkses == 'umum';
          } else if (_selectedAccessFilter == 'Anggota') {
            // Jika bukan umum (atau spesifik 'anggota'), kita anggap Anggota
            matchesAccess = tipeAkses == 'anggota';
          }
        }

        return matchesSearch && matchesStatus && matchesAccess;
      }).toList();
      _currentPage = 1;
    });
  }

  Future<void> _navigateToAddEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEventPage()),
    );

    // Reload if event was added
    if (result == true) {
      _loadEvents();
    }
  }

  Future<void> _deleteEvent(String eventId, String eventName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hapus Event',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus event "$eventName"?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Hapus', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _eventService.deleteEvent(eventId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadEvents();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus event: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        // Modern Header with Gradient
        Container(
          padding: EdgeInsets.all(isMobile ? 20 : (isDesktop ? 32 : 24)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
                  Icons.event_rounded,
                  color: Colors.white,
                  size: isMobile ? 24 : (isDesktop ? 32 : 28),
                ),
              ),
              SizedBox(width: isMobile ? 12 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Event',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 18 : (isDesktop ? 28 : 24),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total ${_filteredEventList.length} Event',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : (isDesktop ? 16 : 14),
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                ElevatedButton.icon(
                  onPressed: _navigateToAddEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4169E1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    'Tambah Event',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
              onPressed: _navigateToAddEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Tambah Event',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Search and Filter Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Cari event...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[400],
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
            const SizedBox(height: 16),

            // Filter Status Chips
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Status:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Semua', 'Mendatang', 'Berlangsung', 'Selesai'].map((
                      filter,
                    ) {
                      final isSelected = _selectedFilter == filter;
                      return FilterChip(
                        label: Text(
                          filter,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                          _applyFilters();
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF4169E1),
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF4169E1)
                              : Colors.grey[300]!,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8), // Align with chip text
                    child: Text(
                      'Status: ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Semua', 'Mendatang', 'Berlangsung', 'Selesai'].map((
                        filter,
                      ) {
                        final isSelected = _selectedFilter == filter;
                        return FilterChip(
                          label: Text(
                            filter,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                            _applyFilters();
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF4169E1),
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF4169E1)
                                : Colors.grey[300]!,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 16), // Increased spacing between sections

            // Filter Jenis Akses Chips
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jenis Akses:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Semua', 'Umum', 'Anggota'].map((
                      filter,
                    ) {
                      final isSelected = _selectedAccessFilter == filter;
                      return FilterChip(
                        label: Text(
                          filter,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedAccessFilter = filter);
                          _applyFilters();
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.green.shade600,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.green.shade600
                              : Colors.grey[300]!,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Jenis Akses: ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Semua', 'Umum', 'Anggota'].map((
                        filter,
                      ) {
                        final isSelected = _selectedAccessFilter == filter;
                        return FilterChip(
                          label: Text(
                            filter,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedAccessFilter = filter);
                            _applyFilters();
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.green.shade600,
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? Colors.green.shade600
                                : Colors.grey[300]!,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Event List
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadEvents,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : _filteredEventList.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Tidak ada event yang cocok dengan pencarian'
                            : 'Belum ada event',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _paginatedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _paginatedEvents[index];
                      return _buildEventCard(event);
                    },
                  ),
                  
                  // Pagination Controls - Always show when there are events
                  if (_filteredEventList.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
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
                    ),
                ],
              ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final tanggalMulai = event['tanggal_mulai'] != null
        ? DateTime.parse(event['tanggal_mulai'])
        : null;
    final jamStr = event['jam'] ?? '00:00';

    final tanggalStr = tanggalMulai != null
        ? DateFormat('dd MMM yyyy').format(tanggalMulai)
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailEventUkmPage(
                eventId: event['id_events'],
                eventData: event,
              ),
            ),
          ).then((_) => _loadEvents());
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  if (event['gambar'] != null && event['gambar'].toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        _getEventImageUrl(event['gambar']?.toString()),
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: const Color(0xFF4169E1),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 4),
                                Text(
                                  'Gagal memuat gambar',
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada gambar',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Document status badge
                  if (_hasIncompleteDocuments(event))
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Dokumen Belum Lengkap',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Tipe akses badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event['tipe_akses'] == 'umum' ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            event['tipe_akses'] == 'umum' ? Icons.public : Icons.group,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event['tipe_akses'] == 'umum' ? 'Umum' : 'Anggota',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content section
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4169E1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'EVENT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4169E1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Event title
                  Text(
                    event['nama_event'] ?? 'Unnamed Event',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event['lokasi'] ?? '-',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Date and time
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        tanggalStr,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        jamStr,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
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
  }

  bool _hasIncompleteDocuments(Map<String, dynamic> event) {
    final statusProposal = event['status_proposal']?.toString() ?? 'belum_ajukan';
    final statusLpj = event['status_lpj']?.toString() ?? 'belum_ajukan';
    final logbook = event['logbook']?.toString();

    return statusProposal == 'belum_ajukan' ||
           statusLpj == 'belum_ajukan' ||
           logbook == null ||
           logbook.isEmpty;
  }

  Widget _buildStatusChip(String label, String status) {
    Color color;
    String text;

    switch (status) {
      case 'disetujui':
        color = Colors.green;
        text = 'Disetujui';
        break;
      case 'menunggu':
        color = Colors.orange;
        text = 'Menunggu';
        break;
      case 'ditolak':
        color = Colors.red;
        text = 'Ditolak';
        break;
      default:
        color = Colors.grey;
        text = 'Belum Ajukan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $text',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}