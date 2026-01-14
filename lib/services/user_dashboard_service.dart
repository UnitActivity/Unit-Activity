import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

class UserDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  /// Get current user ID from custom auth service
  String? get currentUserId => _authService.currentUserId;

  /// Get current user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final response = await _supabase
          .from('users')
          .select('nama, email, nim, role')
          .eq('id_user', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Load slider events from database
  Future<List<Map<String, dynamic>>> getSliderEvents({int limit = 5}) async {
    try {
      print('========== LOAD SLIDER EVENTS ==========');

      final response = await _supabase
          .from('events')
          .select('''
            id_events,
            nama_event,
            deskripsi,
            lokasi,
            tanggal_mulai,
            tanggal_akhir,
            jam_mulai,
            jam_akhir,
            tipevent,
            max_participant,
            gambar,
            ukm(id_ukm, nama_ukm, logo)
          ''')
          .eq('status', true)
          .order('tanggal_mulai', ascending: false)
          .limit(limit);

      print('Found ${response.length} slider events');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading slider events: $e');
      return [];
    }
  }

  /// Load informasi/announcements from database
  Future<List<Map<String, dynamic>>> getInformasi({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('informasi')
          .select('''
            id_informasi,
            judul,
            deskripsi,
            gambar,
            status,
            created_at,
            ukm(id_ukm, nama_ukm)
          ''')
          .eq('status', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading informasi: $e');
      return [];
    }
  }

  /// Load upcoming events/schedules for user's joined UKMs
  Future<List<Map<String, dynamic>>> getUpcomingSchedules({
    int limit = 10,
  }) async {
    try {
      final userId = currentUserId;
      print('========== GET UPCOMING SCHEDULES ==========');
      print('User ID: $userId');

      if (userId == null) {
        print('❌ No user logged in');
        return [];
      }

      // Get user's joined UKMs (only active ones - accept both 'aktif' and 'active')
      print('Fetching user joined UKMs...');
      final userUkms = await _supabase
          .from('user_halaman_ukm')
          .select('id_ukm, ukm(nama_ukm)')
          .eq('id_user', userId)
          .or('status.eq.aktif,status.eq.active');

      print('✅ User joined UKMs: ${(userUkms as List).length}');

      if (userUkms.isNotEmpty) {
        print('User UKMs:');
        for (var ukm in userUkms) {
          print('  - ${ukm['ukm']?['nama_ukm']} (ID: ${ukm['id_ukm']})');
        }
      }

      if (userUkms.isEmpty) {
        print('⚠️ User has not joined any UKM - showing all upcoming events');
        // Return all upcoming events if user hasn't joined any UKM
        return await _getAllUpcomingSchedules(limit: limit);
      }

      final ukmIds = (userUkms as List).map((e) => e['id_ukm']).toList();
      print('UKM IDs to filter: $ukmIds');

      List<Map<String, dynamic>> schedules = [];

      // Get upcoming pertemuan for user's UKMs (today and future)
      print('Fetching pertemuan...');
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];

      final pertemuanResponse = await _supabase
          .from('pertemuan')
          .select('''
            id_pertemuan,
            topik,
            tanggal,
            jam_mulai,
            jam_akhir,
            lokasi,
            ukm(id_ukm, nama_ukm)
          ''')
          .inFilter('id_ukm', ukmIds)
          .gte('tanggal', todayStr)
          .order('tanggal', ascending: true)
          .limit(limit);

      print('✅ Found ${(pertemuanResponse as List).length} upcoming pertemuan');

      for (var pertemuan in pertemuanResponse) {
        final schedule = {
          'type': 'pertemuan',
          'id': pertemuan['id_pertemuan'],
          'title': pertemuan['ukm']?['nama_ukm'] ?? 'UKM',
          'subtitle': pertemuan['topik'] ?? 'Pertemuan Rutin',
          'date': pertemuan['tanggal'],
          'time':
              '${pertemuan['jam_mulai'] ?? ''} - ${pertemuan['jam_akhir'] ?? ''}',
          'location': pertemuan['lokasi'] ?? '',
          'icon': 'groups',
          'color': 'blue',
        };
        schedules.add(schedule);
        print(
          '  + Pertemuan: ${schedule['title']}: ${schedule['subtitle']} on ${schedule['date']}',
        );
      }

      // Also get upcoming events
      print('Fetching events...');
      final eventsResponse = await _supabase
          .from('events')
          .select('''
            id_events,
            nama_event,
            tanggal_mulai,
            jam_mulai,
            jam_akhir,
            lokasi,
            tipevent,
            ukm(id_ukm, nama_ukm)
          ''')
          .inFilter('id_ukm', ukmIds)
          .gte('tanggal_mulai', todayStr)
          .order('tanggal_mulai', ascending: true)
          .limit(limit);

      print('✅ Found ${(eventsResponse as List).length} upcoming events');

      for (var event in eventsResponse) {
        final schedule = {
          'type': 'event',
          'id': event['id_events'],
          'title': event['ukm']?['nama_ukm'] ?? 'UKM',
          'subtitle': event['nama_event'] ?? 'Event',
          'date': event['tanggal_mulai'],
          'time': '${event['jam_mulai'] ?? ''} - ${event['jam_akhir'] ?? ''}',
          'location': event['lokasi'] ?? '',
          'icon': 'event',
          'color': 'orange',
        };
        schedules.add(schedule);
        print(
          '  + Event: ${schedule['title']}: ${schedule['subtitle']} on ${schedule['date']}',
        );
      }

      // If no upcoming schedules, get recent past schedules (last 7 days) as reference
      if (schedules.isEmpty) {
        print('⚠️ No upcoming schedules, checking recent past schedules...');
        final weekAgo = today
            .subtract(const Duration(days: 7))
            .toIso8601String()
            .split('T')[0];

        final recentPertemuan = await _supabase
            .from('pertemuan')
            .select('''
              id_pertemuan,
              topik,
              tanggal,
              jam_mulai,
              jam_akhir,
              lokasi,
              ukm(id_ukm, nama_ukm)
            ''')
            .inFilter('id_ukm', ukmIds)
            .gte('tanggal', weekAgo)
            .lt('tanggal', todayStr)
            .order('tanggal', ascending: false)
            .limit(5);

        print(
          'Found ${(recentPertemuan as List).length} recent past pertemuan',
        );

        for (var pertemuan in recentPertemuan) {
          schedules.add({
            'type': 'pertemuan',
            'id': pertemuan['id_pertemuan'],
            'title': pertemuan['ukm']?['nama_ukm'] ?? 'UKM',
            'subtitle': '${pertemuan['topik'] ?? 'Pertemuan'} (Selesai)',
            'date': pertemuan['tanggal'],
            'time':
                '${pertemuan['jam_mulai'] ?? ''} - ${pertemuan['jam_akhir'] ?? ''}',
            'location': pertemuan['lokasi'] ?? '',
            'icon': 'groups',
            'color': 'grey',
          });
        }
      }

      // Sort by date
      schedules.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      print('📊 Total schedules after sorting: ${schedules.length}');
      print('=========================================');

      return schedules.take(limit).toList();
    } catch (e) {
      print('Error loading schedules: $e');
      return [];
    }
  }

  /// Get all upcoming schedules (for users who haven't joined any UKM)
  Future<List<Map<String, dynamic>>> _getAllUpcomingSchedules({
    int limit = 10,
  }) async {
    try {
      final eventsResponse = await _supabase
          .from('events')
          .select('''
            id_events,
            nama_event,
            tanggal_mulai,
            jam_mulai,
            jam_akhir,
            lokasi,
            tipevent,
            ukm(id_ukm, nama_ukm)
          ''')
          .eq('status', true)
          .gte('tanggal_mulai', DateTime.now().toIso8601String())
          .order('tanggal_mulai', ascending: true)
          .limit(limit);

      List<Map<String, dynamic>> schedules = [];

      for (var event in eventsResponse) {
        schedules.add({
          'type': 'event',
          'id': event['id_events'],
          'title': event['ukm']?['nama_ukm'] ?? 'UKM',
          'subtitle': event['nama_event'] ?? 'Event',
          'date': event['tanggal_mulai'],
          'time': '${event['jam_mulai'] ?? ''} - ${event['jam_akhir'] ?? ''}',
          'location': event['lokasi'] ?? '',
          'icon': 'event',
          'color': 'orange',
        });
      }

      return schedules;
    } catch (e) {
      print('Error loading all schedules: $e');
      return [];
    }
  }

  /// Load statistics for the chart (User's attendance in joined UKMs)
  Future<Map<String, dynamic>> getStatisticsData() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return _getEmptyStats('Belum login');
      }

      print('DEBUG: Loading stats for user $userId');

      // 1. Get user's joined UKMs (active ones)
      // fetch separately to avoid join errors
      final joinedUkmsRes = await _supabase
          .from('user_halaman_ukm')
          .select('id_ukm, status')
          .eq('id_user', userId);

      final activeUkmIds = (joinedUkmsRes as List).where((r) {
        final s = (r['status'] as String?)?.toLowerCase() ?? '';
        return s == 'aktif' || s == 'active';
      }).map((r) => r['id_ukm'] as String).toList();

      if (activeUkmIds.isEmpty) {
        return _getEmptyStats('Belum bergabung UKM');
      }

      // Fetch names for these UKMs
      final ukmsRes = await _supabase
          .from('ukm')
          .select('id_ukm, nama_ukm')
          .inFilter('id_ukm', activeUkmIds)
          .limit(2); // Only need top 2

      if (ukmsRes.isEmpty) {
        return _getEmptyStats('Data UKM tidak ditemukan');
      }

      // Take top 2 UKMs
      List<int> data1 = List.filled(12, 0);
      List<int> data2 = List.filled(12, 0);
      String label1 = 'UKM 1';
      String label2 = 'UKM 2';

      // Function to get monthly attendance for a UKM
      Future<List<int>> getMonthlyAttendance(String ukmId) async {
        // Get all meetings for this UKM
        final meetingsRes = await _supabase
            .from('pertemuan')
            .select('id_pertemuan, tanggal')
            .eq('id_ukm', ukmId);
        
        // Get user's attendance for these meetings
        final meetingIds = (meetingsRes as List).map((m) => m['id_pertemuan']).toList();
        
        if (meetingIds.isEmpty) return List.filled(12, 0);

        final attendanceRes = await _supabase
            .from('absen_pertemuan') // CORRECT TABLE NAME
            .select('id_pertemuan, status') // Check status too if needed
            .eq('id_user', userId)
            .inFilter('id_pertemuan', meetingIds);

        // Map attendance back to dates
        // Filter strictly for 'hadir' if needed, but usually row existence implies attended or check status
        final attendedMeetingIds = <String>{};
        for (var a in attendanceRes) {
           final status = (a['status'] as String?)?.toLowerCase() ?? '';
           // If status column exists, wait, previous code checked for 'hadir'. 
           // Let's assume having a record might be enough, OR check status.
           if (status.contains('hadir') || status.isEmpty) { 
              attendedMeetingIds.add(a['id_pertemuan'].toString());
           }
        }
        
        Map<int, int> monthlyCount = {};
        for (var m in meetingsRes) {
          if (attendedMeetingIds.contains(m['id_pertemuan'].toString())) {
             if (m['tanggal'] != null) {
                try {
                  final date = DateTime.parse(m['tanggal']);
                  final month = date.month;
                  monthlyCount[month] = (monthlyCount[month] ?? 0) + 1;
                } catch (_) {}
             }
          }
        }
        
        return List.generate(12, (i) => monthlyCount[i + 1] ?? 0);
      }

      // Process UKM 1
      if (ukmsRes.isNotEmpty) {
        final ukm1 = ukmsRes[0];
        label1 = ukm1['nama_ukm'] ?? 'UKM 1';
        data1 = await getMonthlyAttendance(ukm1['id_ukm']);
      }

      // Process UKM 2
      if (ukmsRes.length > 1) {
        final ukm2 = ukmsRes[1];
        label2 = ukm2['nama_ukm'] ?? 'UKM 2';
        data2 = await getMonthlyAttendance(ukm2['id_ukm']);
      } else {
         label2 = ''; // Hide second label if only 1 UKM
         data2 = List.filled(12, 0);
      }

      return {
        'label1': label1,
        'label2': label2,
        'data1': data1,
        'data2': data2,
      };

    } catch (e) {
      print('Error loading statistics: $e');
      return _getEmptyStats('Error memuat data');
    }
  }

  Map<String, dynamic> _getEmptyStats(String label) {
    return {
      'label1': label,
      'label2': label,
      'data1': List.filled(12, 0),
      'data2': List.filled(12, 0),
    };
  }

  /// Get all events for user
  Future<List<Map<String, dynamic>>> getAllEvents({String? filter}) async {
    try {
      var query = _supabase
          .from('events')
          .select('''
            id_events,
            id_ukm,
            nama_event,
            deskripsi,
            lokasi,
            tanggal_mulai,
            tanggal_akhir,
            jam_mulai,
            jam_akhir,
            tipevent,
            max_participant,
            status,
            ukm(id_ukm, nama_ukm, logo)
          ''')
          .eq('status', true);

      final now = DateTime.now();

      if (filter == 'upcoming') {
        query = query.gte('tanggal_mulai', now.toIso8601String());
      } else if (filter == 'past') {
        query = query.lt('tanggal_akhir', now.toIso8601String());
      }

      final response = await query.order('tanggal_mulai', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading events: $e');
      return [];
    }
  }

  /// Get event detail by ID
  Future<Map<String, dynamic>?> getEventDetail(String eventId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('''
            id_events,
            nama_event,
            deskripsi,
            lokasi,
            tanggal_mulai,
            tanggal_akhir,
            jam_mulai,
            jam_akhir,
            tipevent,
            max_participant,
            logbook,
            status,
            ukm(id_ukm, nama_ukm, logo, description)
          ''')
          .eq('id_events', eventId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error loading event detail: $e');
      return null;
    }
  }

  /// Get event participants/attendees (from absen_event - those who attended)
  Future<List<Map<String, dynamic>>> getEventParticipants(
    String eventId,
  ) async {
    try {
      final response = await _supabase
          .from('absen_event')
          .select('*, users(id_user, nim, email, username, picture)')
          .eq('id_event', eventId)
          .order('jam', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading participants: $e');
      return [];
    }
  }

  /// Get event registered participants (from absen_event - those who registered)
  Future<List<Map<String, dynamic>>> getEventRegisteredParticipants(
    String eventId,
  ) async {
    try {
      print('DEBUG: Fetching registered participants for event $eventId');
      final response = await _supabase
          .from('absen_event')
          .select('*, users(id_user, nim, email, username, picture)')
          .eq('id_event', eventId)
          .order('jam', ascending: false);

      print('DEBUG: Found ${response.length} participants');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting registered participants: $e');
      return [];
    }
  }

  /// Get count of registered participants for an event
  Future<int> getEventRegisteredCount(String eventId) async {
    try {
      final response = await _supabase
          .from('absen_event')
          .select('id_absen_e')
          .eq('id_event', eventId);

      return (response as List).length;
    } catch (e) {
      print('Error getting registered count: $e');
      return 0;
    }
  }

  /// Get event logbook
  Future<Map<String, dynamic>?> getEventLogbook(String eventId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('logbook')
          .eq('id_events', eventId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error loading logbook: $e');
      return null;
    }
  }

  /// Check if user is registered for an event
  /// Uses absen_event table for registration status
  Future<bool> isUserRegistered(String eventId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      print('DEBUG isUserRegistered: eventId = $eventId, userId = $userId');

      // Check absen_event table (registration table)
      final response = await _supabase
          .from('absen_event')
          .select('id_absen_e')
          .eq('id_event', eventId)
          .eq('id_user', userId)
          .limit(1)
          .maybeSingle();

      print('DEBUG isUserRegistered: absen_event Response = $response');

      return response != null;
    } catch (e) {
      print('ERROR isUserRegistered: $e');
      return false;
    }
  }

  /// Get user's registered events from peserta_event table
  /// peserta_event = registration, absen_event = attendance on event day
  Future<List<Map<String, dynamic>>> getUserRegisteredEvents() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('DEBUG getUserRegisteredEvents: No user ID');
        return [];
      }

      print('DEBUG getUserRegisteredEvents: Fetching for userId=$userId');

      // Query absen_event table for registrations - fetch only basic fields
      final response = await _supabase
          .from('absen_event')
          .select('''
            id_absen_e,
            status,
            jam,
            id_event
          ''')
          .eq('id_user', userId)
          .order('jam', ascending: false);

      final registrations = List<Map<String, dynamic>>.from(response);
      print('DEBUG getUserRegisteredEvents: Found ${registrations.length} registrations');

      // Fetch event details separately for each registration
      for (var registration in registrations) {
        final eventId = registration['id_event'];
        if (eventId != null) {
          try {
            // Fetch event details
            final eventResponse = await _supabase
                .from('events')
                .select('id_events, nama_event, deskripsi, lokasi, tanggal_mulai, tanggal_akhir, gambar, id_ukm')
                .eq('id_events', eventId)
                .maybeSingle();

            if (eventResponse != null) {
              // Fetch UKM details if event has id_ukm
              if (eventResponse['id_ukm'] != null) {
                final ukmResponse = await _supabase
                    .from('ukm')
                    .select('nama_ukm')
                    .eq('id_ukm', eventResponse['id_ukm'])
                    .maybeSingle();
                
                if (ukmResponse != null) {
                  eventResponse['ukm'] = ukmResponse;
                }
              }
              
              registration['events'] = eventResponse;
            }
          } catch (e) {
            print('Error fetching event details for $eventId: $e');
          }
        }
      }

      print('DEBUG getUserRegisteredEvents: Returning ${registrations.length} events with details');
      return registrations;
    } catch (e) {
      print('Error loading registered events: $e');
      return [];
    }
  }

  /// Get user's history (past events)
  Future<Map<String, List<Map<String, dynamic>>>> getUserHistory() async {
    try {
      final userId = currentUserId;
      print('========== GET USER HISTORY ==========');
      print('User ID: $userId');

      if (userId == null) {
        print('❌ No user logged in');
        return {};
      }

      // Get user's joined UKMs
      print('Fetching user joined UKMs...');
      final userUkms = await _supabase
          .from('user_halaman_ukm')
          .select('id_ukm, ukm(id_ukm, nama_ukm)')
          .eq('id_user', userId)
          .or('status.eq.aktif,status.eq.active');

      print('✅ User joined UKMs: ${(userUkms as List).length}');

      if (userUkms.isEmpty) {
        print('⚠️ User has not joined any UKM');
        return {};
      }

      final ukmIds = userUkms.map((e) => e['id_ukm']).toList();
      print('UKM IDs to filter: $ukmIds');

      // 1. Get events the user has STRICTLY attended (status='hadir')
      final attendedResponse = await _supabase
          .from('absen_event')
          .select('id_event, jam')
          .eq('id_user', userId)
          .or('status.eq.hadir,status.eq.Hadir');
          
      final attendedEventIds = (attendedResponse as List)
          .map((e) => e['id_event'] as String)
          .toList();

      // Create map for attendance details
      Map<String, Map<String, dynamic>> attendanceMap = {};
      for (var item in attendedResponse) {
        if (item['id_event'] != null) {
          attendanceMap[item['id_event']] = {
            'attendance_time': item['jam'],
            'is_hadir': true
          };
        }
      }

      if (attendedEventIds.isEmpty) {
        print('User has no attended events');
        return {};
      }

      // 2. Fetch details for these attended events
      final eventsResponse = await _supabase
          .from('events')
          .select('''
            id_events,
            nama_event,
            deskripsi,
            lokasi,
            tanggal_mulai,
            tanggal_akhir,
            logbook,
            gambar,
            ukm(id_ukm, nama_ukm)
          ''')
          .inFilter('id_events', attendedEventIds)
          .order('tanggal_akhir', ascending: false);

      print('✅ Found ${eventsResponse.length} strictly attended history events');

      // Group by periode
      Map<String, List<Map<String, dynamic>>> groupedHistory = {};

      for (var event in eventsResponse) {
        // Determine periode based on date
        final dateStr = event['tanggal_mulai'] ?? event['tanggal_akhir'];
        if (dateStr == null) continue;

        final date = DateTime.parse(dateStr);
        final year = date.year;
        final semester = date.month <= 6 ? 1 : 2;
        final periodeKey = '$year.$semester';

        if (!groupedHistory.containsKey(periodeKey)) {
          groupedHistory[periodeKey] = [];
        }

        final attendance = attendanceMap[event['id_events']];
        groupedHistory[periodeKey]!.add({
          'id': event['id_events'],
          'title': event['nama_event'],
          'description': event['deskripsi'],
          'location': event['lokasi'],
          'date_start': event['tanggal_mulai'],
          'date_end': event['tanggal_akhir'],
          'logbook': event['logbook'],
          'image': event['gambar'],
          'ukm_name': event['ukm']?['nama_ukm'],
          'attendance_time': attendance?['attendance_time'],
          'is_attended': attendance?['is_hadir'] ?? false,
          'illustration': _getIllustration(event['nama_event']),
        });
      }

      // Sort by periode descending
      final sortedKeys = groupedHistory.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      Map<String, List<Map<String, dynamic>>> sortedHistory = {};
      for (var key in sortedKeys) {
        sortedHistory[key] = groupedHistory[key]!;
      }

      print('📊 Total periods: ${sortedHistory.length}');
      print('=========================================');
      return sortedHistory;
    } catch (e) {
      print('❌ Error loading history: $e');
      return {};
    }
  }

  /// Get illustration type based on event name
  String _getIllustration(String? eventName) {
    if (eventName == null) return 'person_gaming';

    final name = eventName.toLowerCase();
    if (name.contains('badminton') ||
        name.contains('sport') ||
        name.contains('olahraga')) {
      return 'person_badminton';
    } else if (name.contains('camping') ||
        name.contains('live in') ||
        name.contains('retreat')) {
      return 'person_camping';
    } else {
      return 'person_gaming';
    }
  }

  /// Get all pertemuan (meetings) for the user
  /// Includes meetings from joined UKMs AND any meeting the user has attended
  Future<List<Map<String, dynamic>>> getUserPertemuan({
    bool upcomingOnly = false,
  }) async {
    try {
      final userId = currentUserId;
      print('========== GET USER PERTEMUAN (SAFE MODE) ==========');
      
      if (userId == null) return [];

      // 1. Get Joined UKMs
      final userUkms = await _supabase
          .from('user_halaman_ukm')
          .select('id_ukm')
          .eq('id_user', userId)
          .or('status.eq.aktif,status.eq.active');

      final joinedUkmIds = (userUkms as List).map((e) => e['id_ukm']).toSet();

      // 2. Get User Attendance
      final attendanceResponse = await _supabase
          .from('absen_pertemuan')
          .select('id_pertemuan, status, jam')
          .eq('id_user', userId);

      final attendanceMap = <String, Map<String, dynamic>>{};
      final attendedMeetingIds = <String>{};

      for (var item in attendanceResponse) {
        final id = item['id_pertemuan'].toString();
        attendedMeetingIds.add(id);
        attendanceMap[id] = {
          'status_hadir': (item['status'] as String?)?.toLowerCase(),
          'waktu_absen': item['jam'],
        };
      }

      // 3. Prepare Meeting Queries (No Joins yet)
      List<dynamic> rawMeetings = [];

      // Only fetch attended meetings
      if (attendedMeetingIds.isEmpty) {
        return [];
      }

      final idsToFetch = attendedMeetingIds.toList();
      if (idsToFetch.isEmpty) return [];

      var query = _supabase
          .from('pertemuan')
          .select('*')
          .inFilter('id_pertemuan', idsToFetch);

      if (upcomingOnly) {
           final todayStr = DateTime.now().toIso8601String().split('T')[0];
           query = query.gte('tanggal', todayStr);
      }
      final res = await query;
      rawMeetings.addAll(res as List);

      // 4. Manually Fetch and Map UKM Details
      // Collect all UKM IDs from the fetched meetings
      final allUkmIds = rawMeetings
          .map((m) => m['id_ukm'])
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> ukmDetailsMap = {};
      
      if (allUkmIds.isNotEmpty) {
        try {
          final ukmRes = await _supabase
              .from('ukm')
              .select('id_ukm, nama_ukm, logo')
              .inFilter('id_ukm', allUkmIds);
          
          for (var u in ukmRes) {
            ukmDetailsMap[u['id_ukm'].toString()] = u;
          }
        } catch (e) {
          print('Error fetching UKM details: $e');
        }
      }

      // 5. Merge and Sort
      final Map<String, dynamic> uniqueMeetings = {};
      
      for (var m in rawMeetings) {
        uniqueMeetings[m['id_pertemuan'].toString()] = m;
      }
      
      final sortedMeetings = uniqueMeetings.values.toList();
      
      if (upcomingOnly) {
         sortedMeetings.sort((a, b) => (a['tanggal'] ?? '').compareTo(b['tanggal'] ?? ''));
      } else {
         sortedMeetings.sort((a, b) => (b['tanggal'] ?? '').compareTo(a['tanggal'] ?? ''));
      }

      // 6. Transform
      List<Map<String, dynamic>> resultList = [];
      
      for (var m in sortedMeetings) {
        final id = m['id_pertemuan'].toString();
        final ukmId = m['id_ukm']?.toString();
        final attendance = attendanceMap[id];
        final ukm = ukmDetailsMap[ukmId];
        
        resultList.add({
          'id_pertemuan': id,
          'judul': m['topik'] ?? 'Pertemuan',
          'topik': m['topik'],
          'deskripsi': m['deskripsi'] ?? 'Tidak ada deskripsi',
          'tanggal': m['tanggal'],
          'waktu_mulai': m['jam_mulai'],
          'waktu_selesai': m['jam_akhir'],
          'lokasi': m['lokasi'],
          'status': m['status'],
          'ukm_name': ukm?['nama_ukm'] ?? '',
          'ukm_logo': ukm?['logo'],
          'id_ukm': ukmId,
          'user_status_hadir': attendance?['status_hadir'],
          'user_waktu_absen': attendance?['waktu_absen'],
          'is_attended': attendance != null,
        });
      }

      print('✅ Fetched ${resultList.length} meetings (Safe Mode)');
      return resultList;

    } catch (e) {
      print('❌ Error loading user pertemuan: $e');
      return [];
    }
  }
}
