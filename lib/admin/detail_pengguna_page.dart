import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/admin/edit_pengguna_page.dart';

class DetailPenggunaPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const DetailPenggunaPage({super.key, required this.user});

  @override
  State<DetailPenggunaPage> createState() => _DetailPenggunaPageState();
}

class _DetailPenggunaPageState extends State<DetailPenggunaPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // User data that can be updated
  late Map<String, dynamic> _userData;

  // Activity data
  List<Map<String, dynamic>> _eventAttendance = [];
  List<Map<String, dynamic>> _meetingAttendance = [];
  List<Map<String, dynamic>> _ukmMemberships = [];
  List<Map<String, dynamic>> _activityLogs = [];
  bool _isLoadingActivities = true;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.user);
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoadingActivities = true);

    try {
      final userId = _userData['id_user'];

      // Load event attendance with event and UKM details
      final eventData = await _supabase.from('absen_event').select('''
            *,
            events!absen_event_id_event_fkey(
              id_events,
              nama_event,
              tanggal_mulai,
              jam_mulai,
              ukm(nama_ukm)
            )
          ''').eq('id_user', userId).order('create_at', ascending: false);

      // Load meeting attendance with meeting details
      final meetingData = await _supabase.from('absen_pertemuan').select('''
            *,
            pertemuan!absen_pertemuan_id_pertemuan_fkey(
              id_pertemuan,
              topik,
              tanggal_pertemuan,
              jam_mulai,
              ukm(nama_ukm)
            )
          ''').eq('id_user', userId).order('create_at', ascending: false);

      // Load UKM memberships
      final ukmData = await _supabase.from('user_halaman_ukm').select('''
            *,
            ukm(nama_ukm, logo, description)
          ''').eq('id_user', userId).order('follow', ascending: false);

      // Build comprehensive activity log
      final logs = <Map<String, dynamic>>[];

      // Add event attendance to logs
      for (var event in (eventData as List)) {
        logs.add({
          'action':
              'Absensi Event: ${event['events']?['nama_event'] ?? 'Event'}',
          'timestamp': event['create_at'],
          'type': 'event',
          'status': event['status'],
          'details': event,
        });
      }

      // Add meeting attendance to logs
      for (var meeting in (meetingData as List)) {
        logs.add({
          'action':
              'Absensi Pertemuan: ${meeting['pertemuan']?['topik'] ?? 'Pertemuan'}',
          'timestamp': meeting['create_at'],
          'type': 'meeting',
          'status': meeting['status'],
          'details': meeting,
        });
      }

      // Add UKM follows/unfollows to logs
      for (var ukm in (ukmData as List)) {
        if (ukm['follow'] != null) {
          logs.add({
            'action': 'Bergabung dengan ${ukm['ukm']?['nama_ukm'] ?? 'UKM'}',
            'timestamp': ukm['follow'],
            'type': 'ukm',
            'status': 'Bergabung', // Explicit status for history
            'details': ukm,
          });
        }
        if (ukm['unfollow'] != null) {
          logs.add({
            'action': 'Keluar dari ${ukm['ukm']?['nama_ukm'] ?? 'UKM'}',
            'timestamp': ukm['unfollow'],
            'type': 'ukm_unfollow',
            'status': 'Keluar', // Explicit status for history
            'details': ukm,
          });
        }
      }

      // Sort logs by timestamp descending
      logs.sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      setState(() {
        _eventAttendance = List<Map<String, dynamic>>.from(eventData);
        _meetingAttendance = List<Map<String, dynamic>>.from(meetingData);
        _ukmMemberships = List<Map<String, dynamic>>.from(ukmData);
        _activityLogs = logs;
        _isLoadingActivities = false;
      });
    } catch (e) {
      print('Error loading activities: $e');
      setState(() => _isLoadingActivities = false);
    }
  }

  Future<void> _refreshUserData() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id_user', _userData['id_user'])
          .single();

      if (mounted) {
        setState(() {
          _userData = response;
        });
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  Future<void> _navigateToEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPenggunaPage(user: _userData),
      ),
    );

    // If edit was successful, refresh user data
    if (result == true) {
      await _refreshUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          'Detail Pengguna',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4169E1)),
            onPressed: _navigateToEditPage,
            tooltip: 'Edit Pengguna',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Combined Profile & Information Card
                _buildProfileInfoCard(isDesktop),
                const SizedBox(height: 24),

                // Activity Card
                _buildActivityCard(isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard(bool isDesktop) {
    final isMobile = !isDesktop && MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : (isMobile ? 16 : 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Profile Picture - Centered
          CircleAvatar(
            radius: isDesktop ? 60 : (isMobile ? 45 : 50),
            backgroundImage:
                _userData['picture'] != null && _userData['picture'].isNotEmpty
                    ? NetworkImage(_userData['picture'])
                    : null,
            backgroundColor: const Color(0xFF4169E1),
            child: _userData['picture'] == null || _userData['picture'].isEmpty
                ? Text(
                    _getInitials(_userData['username'] ?? ''),
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 32 : (isMobile ? 22 : 28),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Username - Display only
          Text(
            _userData['username'] ?? '',
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 24 : (isMobile ? 16 : 20),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Role Badge - Centered
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4169E1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Mahasiswa',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4169E1),
              ),
            ),
          ),

          SizedBox(height: isMobile ? 20 : 32),

          // Divider
          Divider(color: Colors.grey[300]),

          SizedBox(height: isMobile ? 16 : 24),

          // Information Section Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Informasi Pengguna',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 15 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Information Rows (Display only)
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'NIM',
            value: _userData['nim'] ?? '-',
            isDesktop: isDesktop,
            controller: null,
          ),
          const Divider(height: 32),

          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _userData['email'] ?? '-',
            isDesktop: isDesktop,
            controller: null,
          ),
          const Divider(height: 32),

          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Bergabung Pada',
            value: _formatDate(_userData['create_at']),
            isDesktop: isDesktop,
            controller: null,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(bool isDesktop) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return DefaultTabController(
      length: 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // Header with Tabs
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivitas Pengguna',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    labelColor: const Color(0xFF4169E1),
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: const Color(0xFF4169E1),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: isMobile
                        ? const [
                            Tab(icon: Icon(Icons.event, size: 20)),
                            Tab(icon: Icon(Icons.meeting_room, size: 20)),
                            Tab(icon: Icon(Icons.groups, size: 20)),
                            Tab(icon: Icon(Icons.history, size: 20)),
                          ]
                        : const [
                            Tab(text: 'Event'),
                            Tab(text: 'Pertemuan'),
                            Tab(text: 'UKM'),
                            Tab(text: 'Log Aktivitas'),
                          ],
                  ),
                ],
              ),
            ),

            // Tab Content
            SizedBox(
              height: 400,
              child: TabBarView(
                children: [
                  _buildEventsTab(),
                  _buildMeetingsTab(),
                  _buildUKMTab(),
                  _buildActivityLogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_eventAttendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada aktivitas event',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _eventAttendance.length,
      itemBuilder: (context, index) {
        final attendance = _eventAttendance[index];
        final event = attendance['events'] as Map<String, dynamic>?;
        final status = attendance['status']?.toString() ?? '';
        final isPresent = status.toLowerCase() == 'hadir';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPresent
                ? Colors.green.withOpacity(0.05)
                : Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPresent
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: isPresent
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.event_rounded,
                  color: isPresent ? Colors.green[700] : Colors.red[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event?['nama_event'] ?? 'Event',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event?['ukm']?['nama_ukm'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              event!['ukm']['nama_ukm'],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(event?['tanggal_mulai']),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (attendance['jam'] != null) ...[
                               const SizedBox(width: 8),
                               Text(
                                 '•',
                                 style: GoogleFonts.inter(color: Colors.grey[400]),
                               ),
                               const SizedBox(width: 8),
                               Text(
                                 attendance['jam'].toString().substring(0, 5),
                                 style: GoogleFonts.inter(
                                   fontSize: 13,
                                   color: Colors.grey[600],
                                 ),
                               ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPresent ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isPresent ? Colors.green : Colors.red).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeetingsTab() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_meetingAttendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada aktivitas pertemuan',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final totalPresent = _meetingAttendance
        .where((m) => (m['status']?.toString().toLowerCase() ?? '') == 'hadir')
        .length;

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4169E1).withOpacity(0.1),
                const Color(0xFF4169E1).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4169E1).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$totalPresent',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4169E1),
                    ),
                  ),
                  Text(
                    'Hadir',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 50, color: Colors.grey[300]),
              Column(
                children: [
                  Text(
                    '${_meetingAttendance.length}',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Meetings List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: _meetingAttendance.length,
            itemBuilder: (context, index) {
              final attendance = _meetingAttendance[index];
              final meeting = attendance['pertemuan'] as Map<String, dynamic>?;
              final status = attendance['status']?.toString() ?? '';
              final isPresent = status.toLowerCase() == 'hadir';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPresent
                      ? Colors.green.withOpacity(0.05)
                      : Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPresent
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: isPresent
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.meeting_room_rounded,
                        color: isPresent ? Colors.green[700] : Colors.red[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meeting?['topik'] ?? 'Pertemuan',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (meeting?['ukm']?['nama_ukm'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    meeting!['ukm']['nama_ukm'],
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(meeting?['tanggal_pertemuan']),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (attendance['jam'] != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '•',
                                      style: GoogleFonts.inter(color: Colors.grey[400]),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      attendance['jam'].toString().substring(0, 5),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPresent ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isPresent ? Colors.green : Colors.red).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUKMTab() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ukmMemberships.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum bergabung dengan UKM',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _ukmMemberships.length,
      itemBuilder: (context, index) {
        final membership = _ukmMemberships[index];
        final ukm = membership['ukm'] as Map<String, dynamic>?;
        final status = membership['status']?.toString() ?? '';
        final isActive =
            status.toLowerCase() == 'aktif' || membership['unfollow'] == null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withOpacity(0.05)
                : Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ukm?['logo'] != null &&
                        ukm!['logo'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          ukm['logo'],
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.groups_rounded,
                            color:
                                isActive ? Colors.green[700] : Colors.red[700],
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.groups_rounded,
                        color: isActive ? Colors.green[700] : Colors.red[700],
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ukm?['nama_ukm'] ?? 'UKM',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bergabung: ${_formatDate(membership['follow'])}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (membership['unfollow'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Keluar: ${_formatDate(membership['unfollow'])}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? Colors.green : Colors.red).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  isActive ? 'AKTIF' : 'TIDAK AKTIF',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityLogTab() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activityLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada log aktivitas',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _activityLogs.length,
      itemBuilder: (context, index) {
        final activity = _activityLogs[index];
        final type = activity['type']?.toString() ?? '';
        final status = activity['status']?.toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 0), // Removed margin to close gap
          child: IntrinsicHeight( // Use IntrinsicHeight for timeline line
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch for line
              children: [
                // Timeline dot and line
                SizedBox(
                  width: 30,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getActivityColor(type),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _getActivityColor(type).withOpacity(0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: index < _activityLogs.length - 1
                              ? Colors.grey[200]
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Activity content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getActivityColor(type).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getActivityIcon(type),
                                  size: 16,
                                  color: _getActivityColor(type),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  activity['action'] ?? 'Aktivitas',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDateTime(activity['timestamp']),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (status != null && status.isNotEmpty) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _getStatusColor(status).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('hadir') || lowerStatus.contains('aktif')) {
      return Colors.green;
    } else if (lowerStatus.contains('tidak')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'ukm':
        return const Color(0xFF4169E1);
      case 'ukm_unfollow':
        return Colors.orange;
      case 'event':
        return Colors.green;
      case 'meeting':
        return Colors.purple;
      case 'profile':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'ukm':
        return Icons.groups;
      case 'ukm_unfollow':
        return Icons.exit_to_app;
      case 'event':
        return Icons.event;
      case 'meeting':
        return Icons.meeting_room;
      case 'profile':
        return Icons.person;
      default:
        return Icons.info;
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDesktop,
    TextEditingController?
        controller, // Keep parameter for compatibility but unused
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4169E1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF4169E1), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
