import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

class UserDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  /// Get current user ID from custom auth service
  String? get currentUserId => _authService.currentUserId;

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

  /// Load statistics for the chart (UKM meeting/event counts)
  Future<Map<String, dynamic>> getStatisticsData() async {
    try {
      // Get top 2 UKMs by activity
      final ukmResponse = await _supabase
          .from('ukm')
          .select('id_ukm, nama_ukm')
          .limit(2);

      if (ukmResponse.isEmpty) {
        return {
          'label1': 'UKM 1',
          'label2': 'UKM 2',
          'data1': List.generate(12, (i) => 4 + (i % 4)),
          'data2': List.generate(12, (i) => 5 + (i % 3)),
        };
      }

      List<int> data1 = [];
      List<int> data2 = [];
      String label1 = 'UKM 1';
      String label2 = 'UKM 2';

      // Get meeting counts for first UKM
      if (ukmResponse.isNotEmpty) {
        final ukm1Id = ukmResponse[0]['id_ukm'];
        label1 = ukmResponse[0]['nama_ukm'] ?? 'UKM 1';

        final meetings1 = await _supabase
            .from('pertemuan')
            .select('id_pertemuan, tanggal')
            .eq('id_ukm', ukm1Id);

        // Generate monthly data
        data1 = _generateMonthlyData(meetings1);
      }

      // Get meeting counts for second UKM
      if (ukmResponse.length > 1) {
        final ukm2Id = ukmResponse[1]['id_ukm'];
        label2 = ukmResponse[1]['nama_ukm'] ?? 'UKM 2';

        final meetings2 = await _supabase
            .from('pertemuan')
            .select('id_pertemuan, tanggal')
            .eq('id_ukm', ukm2Id);

        data2 = _generateMonthlyData(meetings2);
      } else {
        data2 = List.generate(12, (i) => 5 + (i % 3));
      }

      return {
        'label1': label1,
        'label2': label2,
        'data1': data1.isEmpty ? List.generate(12, (i) => 4 + (i % 4)) : data1,
        'data2': data2.isEmpty ? List.generate(12, (i) => 5 + (i % 3)) : data2,
      };
    } catch (e) {
      print('Error loading statistics: $e');
      return {
        'label1': 'UKM 1',
        'label2': 'UKM 2',
        'data1': List.generate(12, (i) => 4 + (i % 4)),
        'data2': List.generate(12, (i) => 5 + (i % 3)),
      };
    }
  }

  /// Generate monthly data from meetings list
  List<int> _generateMonthlyData(List<dynamic> meetings) {
    Map<int, int> monthlyCount = {};

    for (var meeting in meetings) {
      if (meeting['tanggal'] != null) {
        try {
          final date = DateTime.parse(meeting['tanggal']);
          final month = date.month;
          monthlyCount[month] = (monthlyCount[month] ?? 0) + 1;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    return List.generate(12, (i) => monthlyCount[i + 1] ?? 0);
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
          .select('''
            id_absen,
            jam,
            status,
            created_at,
            users(id_user, username, nim, email)
          ''')
          .eq('id_event', eventId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading participants: $e');
      return [];
    }
  }

  /// Get event registered participants (from peserta_event - those who registered)
  Future<List<Map<String, dynamic>>> getEventRegisteredParticipants(
    String eventId,
  ) async {
    try {
      final response = await _supabase
          .from('peserta_event')
          .select('''
            id_peserta,
            status,
            registered_at,
            created_at,
            users:id_user(id_user, username, nim, email)
          ''')
          .eq('id_event', eventId)
          .order('registered_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading registered participants: $e');
      return [];
    }
  }

  /// Get count of registered participants for an event
  Future<int> getEventRegisteredCount(String eventId) async {
    try {
      final response = await _supabase
          .from('peserta_event')
          .select('id_peserta')
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
  /// Uses peserta_event table for registration status
  Future<bool> isUserRegistered(String eventId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      print(
        'DEBUG isUserRegistered: Checking eventId=$eventId, userId=$userId',
      );

      // Check peserta_event table (registration table)
      final response = await _supabase
          .from('peserta_event')
          .select('id_peserta, status')
          .eq('id_event', eventId)
          .eq('id_user', userId)
          .maybeSingle();

      print('DEBUG isUserRegistered: peserta_event Response = $response');
      return response != null;
    } catch (e) {
      print('Error checking registration: $e');
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

      // Query peserta_event table for registrations
      final response = await _supabase
          .from('peserta_event')
          .select('''
            id_peserta,
            status,
            registered_at,
            created_at,
            events:id_event(
              id_events,
              nama_event,
              deskripsi,
              lokasi,
              tanggal_mulai,
              tanggal_akhir,
              gambar,
              ukm(nama_ukm)
            )
          ''')
          .eq('id_user', userId)
          .order('registered_at', ascending: false);

      print(
        'DEBUG getUserRegisteredEvents: Found ${(response as List).length} registered events from peserta_event',
      );
      return List<Map<String, dynamic>>.from(response);
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

      // Get all events from user's joined UKMs that have ended
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
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
          .inFilter('id_ukm', ukmIds)
          .lt('tanggal_akhir', todayStr)
          .order('tanggal_akhir', ascending: false);

      print('✅ Found ${(eventsResponse as List).length} past events');

      // Get user's attendance records
      final eventIds = eventsResponse.map((e) => e['id_events']).toList();
      Map<String, Map<String, dynamic>> attendanceMap = {};

      if (eventIds.isNotEmpty) {
        final attendanceData = await _supabase
            .from('absen_event')
            .select('id_event, jam, created_at')
            .eq('id_user', userId)
            .inFilter('id_event', eventIds);

        for (var item in attendanceData) {
          attendanceMap[item['id_event']] = {
            'attendance_time': item['jam'],
            'attendance_date': item['created_at'],
          };
        }
      }

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
          'attendance_date': attendance?['attendance_date'],
          'is_attended': attendance != null,
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

  /// Get all pertemuan (meetings) from UKMs that user has joined
  Future<List<Map<String, dynamic>>> getUserPertemuan({
    bool upcomingOnly = false,
  }) async {
    try {
      final userId = currentUserId;
      print('========== GET USER PERTEMUAN ==========');
      print('User ID: $userId');
      print('Upcoming only: $upcomingOnly');

      if (userId == null) {
        print('❌ No user logged in');
        return [];
      }

      // Get user's joined UKMs
      print('Fetching user joined UKMs...');
      final userUkms = await _supabase
          .from('user_halaman_ukm')
          .select('id_ukm, ukm(id_ukm, nama_ukm, logo)')
          .eq('id_user', userId)
          .or('status.eq.aktif,status.eq.active');

      print('✅ User joined UKMs: ${(userUkms as List).length}');

      if (userUkms.isEmpty) {
        print('⚠️ User has not joined any UKM');
        return [];
      }

      final ukmIds = userUkms.map((e) => e['id_ukm']).toList();
      print('UKM IDs to filter: $ukmIds');

      // Build query for pertemuan
      var query = _supabase
          .from('pertemuan')
          .select('''
            id_pertemuan,
            topik,
            deskripsi,
            tanggal,
            jam_mulai,
            jam_akhir,
            lokasi,
            status,
            created_at,
            ukm(id_ukm, nama_ukm, logo)
          ''')
          .inFilter('id_ukm', ukmIds);

      // Filter by date if upcomingOnly
      if (upcomingOnly) {
        final todayStr = DateTime.now().toIso8601String().split('T')[0];
        query = query.gte('tanggal', todayStr);
      }

      final pertemuanResponse = await query.order('tanggal', ascending: false);

      print('✅ Found ${(pertemuanResponse as List).length} pertemuan');

      // Get user's attendance records for these pertemuan
      final pertemuanIds = pertemuanResponse
          .map((p) => p['id_pertemuan'])
          .toList();

      Map<String, Map<String, dynamic>> attendanceMap = {};
      if (pertemuanIds.isNotEmpty) {
        // Note: absen_pertemuan uses 'status' and 'jam' columns per SQL schema
        final attendanceData = await _supabase
            .from('absen_pertemuan')
            .select('id_pertemuan, status, jam, created_at')
            .eq('id_user', userId)
            .inFilter('id_pertemuan', pertemuanIds);

        for (var item in attendanceData) {
          attendanceMap[item['id_pertemuan']] = {
            'status_hadir':
                item['status'], // Map 'status' to 'status_hadir' for UI
            'waktu_absen': item['jam'] ?? item['created_at'],
          };
        }
      }

      // Transform data
      List<Map<String, dynamic>> pertemuanList = [];
      for (var pertemuan in pertemuanResponse) {
        final attendance = attendanceMap[pertemuan['id_pertemuan']];
        pertemuanList.add({
          'id_pertemuan': pertemuan['id_pertemuan'],
          'judul': pertemuan['topik'] ?? 'Pertemuan',
          'topik': pertemuan['topik'],
          'deskripsi': pertemuan['deskripsi'],
          'tanggal': pertemuan['tanggal'],
          'waktu_mulai': pertemuan['jam_mulai'],
          'waktu_selesai': pertemuan['jam_akhir'],
          'lokasi': pertemuan['lokasi'],
          'status': pertemuan['status'],
          'ukm_name': pertemuan['ukm']?['nama_ukm'] ?? '',
          'ukm_logo': pertemuan['ukm']?['logo'],
          'id_ukm': pertemuan['ukm']?['id_ukm'],
          'user_status_hadir': attendance?['status_hadir'],
          'user_waktu_absen': attendance?['waktu_absen'],
          'is_attended': attendance != null,
        });
      }

      print('=========================================');
      return pertemuanList;
    } catch (e) {
      print('Error loading user pertemuan: $e');
      return [];
    }
  }
}
