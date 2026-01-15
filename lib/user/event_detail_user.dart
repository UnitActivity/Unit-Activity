import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/user_dashboard_service.dart';
import 'package:unit_activity/services/custom_auth_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class UserEventDetailPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic>? eventData;

  const UserEventDetailPage({super.key, required this.eventId, this.eventData});

  @override
  State<UserEventDetailPage> createState() => _UserEventDetailPageState();
}

class _UserEventDetailPageState extends State<UserEventDetailPage>
    with SingleTickerProviderStateMixin {
  final UserDashboardService _dashboardService = UserDashboardService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  late TabController _tabController;
  Map<String, dynamic>? _event;
  List<Map<String, dynamic>> _participants = []; // Attendees (already attended)
  List<Map<String, dynamic>> _registeredParticipants =
      []; // Registered (not yet attended)
  bool _isLoading = true;
  bool _isRegistered = false;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Peserta, Logbook
    _loadEventDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEventDetails() async {
    setState(() => _isLoading = true);

    try {
      // Load event details
      if (widget.eventData != null) {
        _event = widget.eventData;
      } else {
        _event = await _dashboardService.getEventDetail(widget.eventId);
      }

      // Load attendees (those who already attended via QR scan)
      _participants = await _dashboardService.getEventParticipants(
        widget.eventId,
      );

      // Load registered participants (those who registered but may not have attended yet)
      _registeredParticipants = await _dashboardService
          .getEventRegisteredParticipants(widget.eventId);

      // Check if user is registered using peserta_event table
      _isRegistered = await _dashboardService.isUserRegistered(widget.eventId);
    } catch (e) {
      print('Error loading event details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat detail event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerEvent() async {
    if (_isRegistering || _isRegistered) return;

    setState(() => _isRegistering = true);

    try {
      final userId = _authService.currentUserId;
      print(
        'DEBUG _registerEvent: userId = $userId, eventId = ${widget.eventId}',
      );

      if (userId == null || userId.isEmpty) {
        throw Exception('User tidak terautentikasi');
      }

      // Validate event status and quota
      if (_event != null) {
        // Check if event has ended
        if (_event!['tanggal_akhir'] != null) {
          final endDate = DateTime.parse(_event!['tanggal_akhir']);
          final now = DateTime.now();
          if (now.isAfter(endDate)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.event_busy, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Event sudah selesai. Pendaftaran ditutup.'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange[700],
                ),
              );
            }
            return;
          }
        }
        
        // Check if event is active (status)
        if (_event!['status'] != true) {
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.block, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Event tidak aktif. Pendaftaran ditutup.'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red[700],
                ),
              );
            }
            return;
        }

        // Check participant quota

        // Check participant quota
        if (_event!['max_participant'] != null) {
          final maxParticipant = _event!['max_participant'] as int;
          
          // Count current registrations using Supabase count
          final response = await _supabase
              .from('absen_event')
              .select('id_absen_e')
              .eq('id_event', widget.eventId)
              .count(CountOption.exact);

          final currentCount = response.count;

          if (currentCount >= maxParticipant) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kuota peserta penuh ($currentCount/$maxParticipant)',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange[700],
                ),
              );
            }
            return;
          }
        }
      }

      // Check if already registered in absen_event table
      final existing = await _supabase
          .from('absen_event')
          .select('id_absen_e')
          .eq('id_event', widget.eventId)
          .eq('id_user', userId)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        print('DEBUG _registerEvent: Already registered in absen_event');
        if (mounted) {
          setState(() => _isRegistered = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda sudah terdaftar di event ini'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Register to event using absen_event table
      final now = DateTime.now();
      await _supabase.from('absen_event').insert({
        'id_event': widget.eventId,
        'id_user': userId,
        'status': 'terdaftar',
        'jam':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      });

      print('DEBUG _registerEvent: Successfully registered to absen_event');

      if (mounted) {
        setState(() => _isRegistered = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Berhasil mendaftar event!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadEventDetails(); // Reload to update participant list
      }
    } catch (e) {
      print('ERROR _registerEvent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendaftar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getEventStatus() {
    if (_event == null) return 'unknown';

    final now = DateTime.now();
    final startDate = _event!['tanggal_mulai'] != null
        ? DateTime.parse(_event!['tanggal_mulai'])
        : null;
    final endDate = _event!['tanggal_akhir'] != null
        ? DateTime.parse(_event!['tanggal_akhir'])
        : null;

    if (startDate == null) return 'unknown';

    if (now.isBefore(startDate)) return 'upcoming';
    if (endDate != null && now.isAfter(endDate)) return 'completed';
    return 'ongoing';
  }

  Future<void> _downloadLogbook() async {
    final logbookUrl = _event?['logbook'];
    if (logbookUrl == null || logbookUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logbook belum tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(logbookUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka logbook: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4169E1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Event',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Event tidak ditemukan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Header Card
                    _buildHeaderCard(isDesktop),
                    const SizedBox(height: 24),

                    // Tabs for Logbook and Participants
                    _buildTabSection(isDesktop),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(bool isDesktop) {
    final status = _getEventStatus();
    final statusColors = {
      'upcoming': Colors.blue,
      'ongoing': Colors.green,
      'completed': Colors.grey,
      'unknown': Colors.grey,
    };
    final statusLabels = {
      'upcoming': 'Mendatang',
      'ongoing': 'Berlangsung',
      'completed': 'Selesai',
      'unknown': 'Unknown',
    };

    // Robust extraction of UKM data
    String? ukmLogo;
    String ukmName = 'UKM';
    if (_event?['ukm'] != null) {
      final ukmData = _event!['ukm'];
      if (ukmData is Map) {
         ukmLogo = ukmData['logo'];
         ukmName = ukmData['nama_ukm'] ?? 'UKM';
      } else if (ukmData is List && ukmData.isNotEmpty) {
         ukmLogo = ukmData[0]['logo'];
         ukmName = ukmData[0]['nama_ukm'] ?? 'UKM';
      }
    }

    final eventImage = _event?['image'] ?? _resolveImageUrl(_event?['gambar']);
    final displayImage = (eventImage != null && eventImage.isNotEmpty) ? eventImage : ukmLogo;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image/Logo
          if (displayImage != null && displayImage.isNotEmpty)
            Container(
              height: isDesktop ? 200 : 150,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(displayImage),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: isDesktop ? 200 : 150,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    ukmName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          // Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColors[status]?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabels[status] ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColors[status],
                  ),
                ),
              ),
              const Spacer(),
              // Participant count - show registered participants count
              Row(
                children: [
                  Icon(Icons.people, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${_registeredParticipants.length} Terdaftar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Event Name
          Text(
            _event?['nama_event'] ?? 'Event',
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),

          // UKM Name
          if (_event?['ukm']?['nama_ukm'] != null)
            Row(
              children: [
                Icon(Icons.groups, size: 18, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  _event!['ukm']['nama_ukm'],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Description
          if (_event?['deskripsi'] != null && _event!['deskripsi'].isNotEmpty)
            Text(
              _event!['deskripsi'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          const SizedBox(height: 20),

          // Event Details
          _buildInfoRow(
            Icons.calendar_today,
            'Tanggal',
            _formatDate(_event?['tanggal_mulai']),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time,
            'Waktu',
            '${_event?['jam_mulai'] ?? '-'} - ${_event?['jam_akhir'] ?? '-'}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_on,
            'Lokasi',
            _event?['lokasi'] ?? 'Lokasi belum ditentukan',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.people,
            'Kuota',
            'Max ${_event?['max_participant'] ?? '-'} peserta',
          ),
          const SizedBox(height: 20),

          // Register Button
          if (status != 'completed')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRegistered || _isRegistering
                    ? null
                    : _registerEvent,
                icon: _isRegistering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isRegistered ? Icons.check_circle : Icons.person_add,
                      ),
                label: Text(
                  _isRegistering
                      ? 'Mendaftar...'
                      : _isRegistered
                      ? 'Sudah Terdaftar'
                      : 'Daftar Event',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRegistered
                      ? Colors.green[600]
                      : const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: _isRegistered ? 0 : 2,
                  disabledBackgroundColor: Colors.green[600],
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4169E1),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF4169E1),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Peserta', icon: Icon(Icons.people, size: 20)),
                Tab(text: 'Logbook', icon: Icon(Icons.book, size: 20)),
              ],
            ),
          ),

          // Tab Content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildParticipantsTab(isDesktop),
                _buildLogbookTab(isDesktop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogbookTab(bool isDesktop) {
    final status = _getEventStatus();
    final hasLogbook =
        _event?['logbook'] != null && _event!['logbook'].isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Logbook Event',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Dokumentasi dan catatan kegiatan event',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),

          if (status == 'completed' && hasLogbook)
            // Show logbook download button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.description, size: 48, color: Colors.green[600]),
                  const SizedBox(height: 12),
                  Text(
                    'Logbook Tersedia',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Event telah selesai. Anda dapat mengunduh logbook.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.green[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _downloadLogbook,
                    icon: const Icon(Icons.download),
                    label: Text(
                      'Download Logbook',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (status == 'completed' && !hasLogbook)
            // Completed but no logbook
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 48,
                    color: Colors.orange[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Logbook Belum Tersedia',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Event telah selesai, namun logbook belum diunggah oleh penyelenggara.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.orange[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            // Event not completed yet
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.blue[600]),
                  const SizedBox(height: 12),
                  Text(
                    'Logbook Akan Tersedia',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Logbook dapat diunduh setelah event selesai.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.blue[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsTab(bool isDesktop) {
    // Combine registered and attended participants
    // _registeredParticipants = from peserta_event (registered)
    // _participants = from absen_event (attended)

    // Create a map of attended user IDs for quick lookup
    final attendedUserIds = <String>{};
    for (var p in _participants) {
      final userId = p['users']?['id_user']?.toString() ?? '';
      if (userId.isNotEmpty) attendedUserIds.add(userId);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Peserta Terdaftar',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4169E1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_registeredParticipants.length} Terdaftar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4169E1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_participants.length} Hadir',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_registeredParticipants.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada peserta yang terdaftar',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _registeredParticipants.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final participant = _registeredParticipants[index];
                  final user = participant['users'];
                  final participantUserId = user?['id_user']?.toString() ?? '';
                  final hasAttended = attendedUserIds.contains(
                    participantUserId,
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: hasAttended
                          ? Colors.green.withOpacity(0.1)
                          : const Color(0xFF4169E1).withOpacity(0.1),
                      child: Text(
                        (user?['username'] ?? 'U')[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          color: hasAttended
                              ? Colors.green[700]
                              : const Color(0xFF4169E1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      user?['username'] ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    subtitle: Text(
                      user?['nim']?.toString() ?? user?['email'] ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasAttended ? Colors.green[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasAttended ? 'Hadir' : 'Terdaftar',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: hasAttended
                              ? Colors.green[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  // Helper to construct full image URL
  String? _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    try {
       return Supabase.instance.client.storage.from('event-images').getPublicUrl(path);
    } catch (_) {
       return path;
    }
  }
}
