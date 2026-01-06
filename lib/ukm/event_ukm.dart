import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  List<Map<String, dynamic>> _eventList = [];
  List<Map<String, dynamic>> _filteredEventList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';

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
        // Search filter
        final matchesSearch =
            _searchQuery.isEmpty ||
            event['nama_event'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        // Status filter
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

        return matchesSearch && matchesStatus;
      }).toList();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Event',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            ElevatedButton.icon(
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
          ],
        ),
        const SizedBox(height: 24),

        // Search and Filter
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
            const SizedBox(height: 12),
            // Filter chips - wrapped for mobile
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
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredEventList.length,
                itemBuilder: (context, index) {
                  final event = _filteredEventList[index];
                  return _buildEventCard(event);
                },
              ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final tanggalMulai = event['tanggal_mulai'] != null
        ? DateTime.parse(event['tanggal_mulai'])
        : null;
    final tanggalAkhir = event['tanggal_akhir'] != null
        ? DateTime.parse(event['tanggal_akhir'])
        : null;

    final tanggalStr = tanggalMulai != null && tanggalAkhir != null
        ? '${DateFormat('dd MMM yyyy').format(tanggalMulai)} - ${DateFormat('dd MMM yyyy').format(tanggalAkhir)}'
        : '-';

    final statusProposal = event['status_proposal'] ?? 'belum_ajukan';
    final statusLPJ = event['status_lpj'] ?? 'belum_ajukan';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to event detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailEventUkmPage(
                eventId: event['id_events'],
                eventData: event,
              ),
            ),
          ).then((_) => _loadEvents()); // Reload events when returning
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Event Icon
              Container(
                width: 48,
                height: 48,
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
              const SizedBox(width: 16),

              // Event Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['nama_event'] ?? 'Unnamed Event',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                tanggalStr,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event['lokasi'] ?? '-',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip('Proposal', statusProposal),
                        const SizedBox(width: 8),
                        _buildStatusChip('LPJ', statusLPJ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Navigate to edit event page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur edit akan segera hadir'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    color: const Color(0xFF4169E1),
                    tooltip: 'Edit Event',
                  ),
                  IconButton(
                    onPressed: () =>
                        _deleteEvent(event['id_events'], event['nama_event']),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Hapus',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
