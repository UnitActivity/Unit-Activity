import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_event_page.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isLoading = false;

  // Data from database
  List<Map<String, dynamic>> _allEvents = [];

  // Realtime subscription
  RealtimeChannel? _eventsChannel;
  RealtimeChannel? _documentsChannel;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _subscribeToRealtimeUpdates();
  }

  @override
  void dispose() {
    _eventsChannel?.unsubscribe();
    _documentsChannel?.unsubscribe();
    super.dispose();
  }

  /// Subscribe to realtime updates for events and documents
  void _subscribeToRealtimeUpdates() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Subscribe to event_documents changes
    _documentsChannel = _supabase
        .channel('event_documents_admin_$timestamp')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_documents',
          callback: (payload) {
            print('📄 Document change detected: ${payload.eventType}');
            print('📄 Payload: ${payload.newRecord}');
            // Reload events when document status changes
            if (mounted) {
              _loadEvents();
            }
          },
        )
        .subscribe((status, error) {
          print('📄 Documents subscription status: $status');
          if (error != null) {
            print('📄 Documents subscription error: $error');
          }
        });

    // Subscribe to events table changes
    _eventsChannel = _supabase
        .channel('events_admin_$timestamp')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            print('📅 Event change detected: ${payload.eventType}');
            print('📅 Payload: ${payload.newRecord}');
            // Reload events when event data changes
            if (mounted) {
              _loadEvents();
            }
          },
        )
        .subscribe((status, error) {
          print('📅 Events subscription status: $status');
          if (error != null) {
            print('📅 Events subscription error: $error');
          }
        });

    print('✅ Realtime subscriptions initiated for events and documents');
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load events with related data
      final eventData = await _supabase
          .from('events')
          .select('*, ukm(nama_ukm), users(username)')
          .order('tanggal_mulai', ascending: false);

      // Load all periode separately
      final periodeData = await _supabase
          .from('periode_ukm')
          .select('id_periode, nama_periode');

      // Load all event documents to get actual document status
      final documentsData = await _supabase
          .from('event_documents')
          .select('id_event, document_type, status');

      final periodeMap = <String, String>{};
      for (var p in periodeData) {
        periodeMap[p['id_periode']] = p['nama_periode'];
      }

      // Create document status map: id_event -> {proposal: status, lpj: status}
      final docStatusMap = <String, Map<String, String>>{};
      for (var doc in (documentsData as List)) {
        final eventId = doc['id_event'];
        final docType = doc['document_type'];
        final status = doc['status'] ?? 'menunggu';

        if (eventId != null) {
          docStatusMap[eventId] ??= {};
          docStatusMap[eventId]![docType] = status;
        }
      }

      // Manually attach periode and document status to events
      final events = List<Map<String, dynamic>>.from(eventData);
      for (var event in events) {
        final eventId = event['id_events'];

        // Attach periode
        if (event['id_periode'] != null &&
            periodeMap.containsKey(event['id_periode'])) {
          event['periode_ukm'] = {
            'nama_periode': periodeMap[event['id_periode']],
          };
        }

        // Reconcile document status from event_documents table
        // If document exists in event_documents, use that status
        // Otherwise, use the status from events table (default: belum_ajukan)
        if (docStatusMap.containsKey(eventId)) {
          final docStatus = docStatusMap[eventId]!;

          // Update proposal status if document exists
          if (docStatus.containsKey('proposal')) {
            event['status_proposal'] = docStatus['proposal'];
          }

          // Update LPJ status if document exists
          if (docStatus.containsKey('lpj')) {
            event['status_lpj'] = docStatus['lpj'];
          }
        }

        // Ensure default values
        event['status_proposal'] ??= 'belum_ajukan';
        event['status_lpj'] ??= 'belum_ajukan';
      }

      if (mounted) {
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredEvents {
    var events = _allEvents.where((event) {
      if (_searchQuery.isEmpty) return true;
      final namaEvent = event['nama_event']?.toString().toLowerCase() ?? '';
      final ukmName =
          (event['ukm'] as Map<String, dynamic>?)?['nama_ukm']
              ?.toString()
              .toLowerCase() ??
          '';
      final lokasi = event['lokasi']?.toString().toLowerCase() ?? '';
      final search = _searchQuery.toLowerCase();

      return namaEvent.contains(search) ||
          ukmName.contains(search) ||
          lokasi.contains(search);
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? 50 : 60,
                height: isMobile ? 50 : 60,
                child: const CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              Text(
                'Memuat data event...',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Modern Header with Gradient
          _buildModernHeader(isDesktop),
          const SizedBox(height: 24),

          // Modern Search Bar with Add Button
          _buildModernSearchBar(isDesktop),
          const SizedBox(height: 8),

          // Event Cards
          if (_filteredEvents.isEmpty)
            _buildEmptyState()
          else if (isDesktop)
            _buildModernDesktopCards()
          else
            _buildModernMobileCards(),

          const SizedBox(height: 24),

          // Modern Pagination
          if (_filteredEvents.isNotEmpty) _buildModernPagination(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModernHeader(bool isDesktop) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : (isDesktop ? 32 : 24)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF4169E1), const Color(0xFF5B7FE8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4169E1).withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event_rounded,
              color: Colors.white,
              size: isMobile ? 24 : (isDesktop ? 32 : 28),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Event',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total ${_filteredEvents.length} Event',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari event berdasarkan nama, UKM, atau lokasi...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada event ditemukan',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ubah kata kunci pencarian',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDesktopCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card width based on screen width
        final cardWidth =
            (constraints.maxWidth - 20) / 2; // 2 columns with 20px gap

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: _paginatedEvents.map((event) {
            return SizedBox(
              width: cardWidth,
              child: _buildEventCard(event, true),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildModernMobileCards() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedEvents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildEventCard(_paginatedEvents[index], false),
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, bool isDesktop) {
    // Get event image URL
    final String? imageUrl = event['gambar'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF4169E1).withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4169E1).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4169E1).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Event Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                          child: const Center(
                            child: Icon(
                              Icons.event_rounded,
                              size: 48,
                              color: Color(0xFF4169E1),
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(
                          Icons.event_rounded,
                          size: 48,
                          color: Color(0xFF4169E1),
                        ),
                      ),
                    ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Icon and Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.event_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['nama_event'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: isDesktop ? 14 : 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4169E1,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event['tipevent'] ?? '-',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4169E1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // View Button
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailEventPage(event: event),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      color: const Color(0xFF4169E1),
                      tooltip: 'Lihat Detail',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF4169E1,
                        ).withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 8),

                // Event Details
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.groups_rounded,
                        label: 'UKM',
                        value:
                            (event['ukm']
                                as Map<String, dynamic>?)?['nama_ukm'] ??
                            '-',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.location_on_outlined,
                        label: 'Lokasi',
                        value: event['lokasi'] ?? '-',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tanggal',
                        value: _formatDate(event['tanggal_mulai']),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.access_time_rounded,
                        label: 'Jam',
                        value: _formatTimeRange(
                          event['jam_mulai'],
                          event['jam_akhir'],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Document Status Badges
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Proposal Status
                    Expanded(
                      child: _buildDocumentStatusBadge(
                        label: 'Proposal',
                        status: event['status_proposal'] ?? 'belum_ajukan',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // LPJ Status
                    Expanded(
                      child: _buildDocumentStatusBadge(
                        label: 'LPJ',
                        status: event['status_lpj'] ?? 'belum_ajukan',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatusBadge({
    required String label,
    required String status,
  }) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String statusText;

    switch (status) {
      case 'disetujui':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        statusText = 'Disetujui';
        break;
      case 'menunggu':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
        icon = Icons.hourglass_empty;
        statusText = 'Menunggu';
        break;
      case 'ditolak':
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        statusText = 'Ditolak';
        break;
      case 'revisi':
        bgColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple[700]!;
        icon = Icons.edit;
        statusText = 'Revisi';
        break;
      default: // belum_ajukan
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[600]!;
        icon = Icons.file_upload_outlined;
        statusText = 'Belum Ajukan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModernPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                // Results Info - mobile
                Text(
                  'Halaman $_currentPage dari $_totalPages',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                // Page Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    _buildPageButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    // Page Numbers
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4169E1).withValues(alpha: 0.1),
                            const Color(0xFF4169E1).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4169E1).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4169E1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next Button
                    _buildPageButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Total events info
                Text(
                  '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage) > _filteredEvents.length ? _filteredEvents.length : (_currentPage * _itemsPerPage)} dari ${_filteredEvents.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Results Info
                Text(
                  'Menampilkan ${(_currentPage - 1) * _itemsPerPage + 1} - ${(_currentPage * _itemsPerPage) > _filteredEvents.length ? _filteredEvents.length : (_currentPage * _itemsPerPage)} dari ${_filteredEvents.length} Event',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),

                // Page Navigation
                Row(
                  children: [
                    // Previous Button
                    _buildPageButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                      },
                    ),

                    const SizedBox(width: 12),

                    // Page Numbers
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4169E1).withValues(alpha: 0.1),
                            const Color(0xFF4169E1).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4169E1).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4169E1),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Next Button
                    _buildPageButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFF4169E1).withValues(alpha: 0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? const Color(0xFF4169E1).withValues(alpha: 0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        color: enabled ? const Color(0xFF4169E1) : Colors.grey[400],
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return '-';
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '00:00';
    try {
      // Check if it's a time string (HH:mm:ss format)
      if (timeStr.contains(':') && !timeStr.contains('T')) {
        // It's already a time string, just format it
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return '${parts[0]}:${parts[1]}';
        }
        return timeStr;
      }
      // Otherwise try to parse as datetime
      final date = DateTime.parse(timeStr);
      return DateFormat('HH:mm', 'id_ID').format(date);
    } catch (e) {
      return '00:00';
    }
  }

  /// Format time range (jam_mulai - jam_akhir)
  String _formatTimeRange(String? startTime, String? endTime) {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);
    return '$start - $end';
  }
}
