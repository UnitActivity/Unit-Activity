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
        print('No user logged in');
        return [];
      }

      // Get user's joined UKMs (only active ones - accept both 'aktif' and 'active')
      final userUkms = await _supabase
          .from('user_halaman_ukm')
          .select('id_ukm, ukm(nama_ukm)')
          .eq('id_user', userId)
          .or('status.eq.aktif,status.eq.active');

      print('User joined UKMs: ${(userUkms as List).length}');

      if (userUkms.isEmpty) {
        print('User has not joined any UKM');
        // Return all upcoming events if user hasn't joined any UKM
        return await _getAllUpcomingSchedules(limit: limit);
      }

      final ukmIds = (userUkms as List).map((e) => e['id_ukm']).toList();
      print('UKM IDs: $ukmIds');

      // Get upcoming pertemuan for user's UKMs
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
          .gte('tanggal', DateTime.now().toIso8601String().split('T')[0])
          .order('tanggal', ascending: true)
          .limit(limit);

      print('Found ${(pertemuanResponse as List).length} pertemuan');

      List<Map<String, dynamic>> schedules = [];

      for (var pertemuan in pertemuanResponse) {
        schedules.add({
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
        });
      }

      // Also get upcoming events
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
          .gte('tanggal_mulai', DateTime.now().toIso8601String())
          .order('tanggal_mulai', ascending: true)
          .limit(limit);

      print('Found ${(eventsResponse as List).length} events');

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

      // Sort by date
      schedules.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      print('Total schedules: ${schedules.length}');
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
      var query = _supabase.from('events').select('''
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
            gambar,
            status,
            ukm(id_ukm, nama_ukm, logo)
          ''');
      // Removed .eq('status', true) to show all events

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
            gambar,
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

  /// Get event participants/attendees
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
  Future<bool> isUserRegistered(String eventId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final response = await _supabase
          .from('absen_event')
          .select('id_absen')
          .eq('id_event', eventId)
          .eq('id_user', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking registration: $e');
      return false;
    }
  }

  /// Get user's registered events
  Future<List<Map<String, dynamic>>> getUserRegisteredEvents() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final response = await _supabase
          .from('absen_event')
          .select('''
            id_absen,
            jam,
            created_at,
            events(
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
          .order('created_at', ascending: false);

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
      if (userId == null) return {};

      // Get user's attendance history
      final attendanceResponse = await _supabase
          .from('absen_event')
          .select('''
            id_absen,
            jam,
            created_at,
            events(
              id_events,
              nama_event,
              deskripsi,
              lokasi,
              tanggal_mulai,
              tanggal_akhir,
              logbook,
              gambar,
              ukm(nama_ukm)
            )
          ''')
          .eq('id_user', userId)
          .order('created_at', ascending: false);

      // Group by periode
      Map<String, List<Map<String, dynamic>>> groupedHistory = {};

      for (var attendance in attendanceResponse) {
        final event = attendance['events'];
        if (event == null) continue;

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
          'attendance_time': attendance['jam'],
          'attendance_date': attendance['created_at'],
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

      return sortedHistory;
    } catch (e) {
      print('Error loading history: $e');
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
}
