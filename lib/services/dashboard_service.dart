import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      int ukmCount = 0;
      int usersCount = 0;
      int eventCount = 0;
      int activeEvents = 0;
      int openRegistrations = 0;
      int totalFollowers = 0;

      // ========== GET TOTAL UKM ==========
      try {
        final ukmResponse =
            await _supabase.from('ukm').select('id_ukm') as List;
        ukmCount = ukmResponse.length;
      } catch (e) {
        print('Error fetching UKM: $e');
        ukmCount = 0;
      }

      // ========== GET TOTAL USERS (MAHASISWA) ==========
      try {
        final usersResponse =
            await _supabase.from('users').select('id_user') as List;
        usersCount = usersResponse.length;
      } catch (e) {
        print('Error fetching Users: $e');
        usersCount = 0;
      }

      // ========== GET TOTAL EVENTS ==========
      try {
        final eventResponse =
            await _supabase.from('events').select('id_events') as List;
        eventCount = eventResponse.length;
      } catch (e) {
        print('Error fetching Events: $e');
        eventCount = 0;
      }

      // ========== GET ACTIVE EVENTS (status=true) ==========
      try {
        final activeEventsResponse =
            await _supabase
                    .from('events')
                    .select('id_events')
                    .eq('status', true)
                as List;
        activeEvents = activeEventsResponse.length;
      } catch (e) {
        print('Error fetching Active Events: $e');
        activeEvents = 0;
      }

      // ========== GET OPEN REGISTRATIONS ==========
      try {
        final openRegsResponse =
            await _supabase
                    .from('periode_ukm')
                    .select('id_periode')
                    .eq('is_registration_open', true)
                as List;
        openRegistrations = openRegsResponse.length;
      } catch (e) {
        print('Error fetching Open Registrations: $e');
        openRegistrations = 0;
      }

      // ========== GET TOTAL FOLLOWERS ==========
      try {
        final followersResponse =
            await _supabase.from('user_halaman_ukm').select('id_follow')
                as List;
        totalFollowers = followersResponse.length;
      } catch (e) {
        print('Error fetching Followers: $e');
        totalFollowers = 0;
      }

      print(
        'Dashboard stats loaded: UKM=$ukmCount, Users=$usersCount, Events=$eventCount, ActiveEvents=$activeEvents, OpenRegs=$openRegistrations, Followers=$totalFollowers',
      );

      return {
        'success': true,
        'data': {
          'totalUkm': ukmCount,
          'totalUsers': usersCount,
          'totalEvent': eventCount,
          'activeEvents': activeEvents,
          'openRegistrations': openRegistrations,
          'totalFollowers': totalFollowers,
        },
      };
    } catch (e) {
      print('Error loading dashboard stats: $e');
      return {
        'success': false,
        'error': 'Gagal mengambil data dashboard: ${e.toString()}',
      };
    }
  }

  /// Get event statistics by month (with custom period)
  Future<Map<String, dynamic>> getEventsByMonth([
    String period = '6_bulan',
  ]) async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      // Calculate start date based on period
      switch (period) {
        case 'hari_ini':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'minggu_ini':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'bulan_ini':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case '3_bulan':
          startDate = DateTime(now.year, now.month - 3, 1);
          break;
        case '6_bulan':
          startDate = DateTime(now.year, now.month - 6, 1);
          break;
        case 'tahun_ini':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month - 6, 1);
      }

      final response =
          await _supabase
                  .from('events')
                  .select('tanggal_mulai, nama_event')
                  .gte('tanggal_mulai', startDate.toIso8601String())
                  .order('tanggal_mulai')
              as List;

      // Group by month
      Map<String, int> monthlyData = {};
      for (var event in response) {
        if (event['tanggal_mulai'] != null) {
          final date = DateTime.parse(event['tanggal_mulai']);
          final monthKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
        }
      }

      return {'success': true, 'data': monthlyData};
    } catch (e) {
      print('Error fetching events by month: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get UKM ranking by member count
  Future<Map<String, dynamic>> getUkmRanking() async {
    try {
      final response =
          await _supabase
                  .from('user_halaman_ukm')
                  .select('id_ukm, ukm(nama_ukm)')
              as List;

      // Count members per UKM
      Map<String, dynamic> ukmCounts = {};
      for (var follow in response) {
        final ukmId = follow['id_ukm'];
        final ukmName = follow['ukm']?['nama_ukm'] ?? 'Unknown';

        if (!ukmCounts.containsKey(ukmId)) {
          ukmCounts[ukmId] = {'name': ukmName, 'count': 0};
        }
        ukmCounts[ukmId]['count']++;
      }

      // Convert to list and sort
      List<Map<String, dynamic>> ranking = ukmCounts.entries.map((entry) {
        return {
          'id': entry.key,
          'name': entry.value['name'],
          'members': entry.value['count'],
        };
      }).toList();

      ranking.sort(
        (a, b) => (b['members'] as int).compareTo(a['members'] as int),
      );

      return {
        'success': true,
        'data': ranking.take(10).toList(), // Top 10
      };
    } catch (e) {
      print('Error fetching UKM ranking: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get follower growth trend (with custom period)
  Future<Map<String, dynamic>> getFollowerTrend([
    String period = '6_bulan',
  ]) async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      // Calculate start date based on period
      switch (period) {
        case 'hari_ini':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'minggu_ini':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'bulan_ini':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case '3_bulan':
          startDate = DateTime(now.year, now.month - 3, 1);
          break;
        case '6_bulan':
          startDate = DateTime(now.year, now.month - 6, 1);
          break;
        case 'tahun_ini':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month - 6, 1);
      }

      final response =
          await _supabase
                  .from('user_halaman_ukm')
                  .select('follow, created_at')
                  .gte('created_at', startDate.toIso8601String())
                  .order('created_at')
              as List;

      // Group by month
      Map<String, int> monthlyData = {};
      for (var follow in response) {
        final dateStr = follow['created_at'] ?? follow['follow'];
        if (dateStr != null) {
          final date = DateTime.parse(dateStr);
          final monthKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
        }
      }

      return {'success': true, 'data': monthlyData};
    } catch (e) {
      print('Error fetching follower trend: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get recent activities (last 5 events)
  Future<Map<String, dynamic>> getRecentActivities() async {
    try {
      final response =
          await _supabase
                  .from('events')
                  .select('id_events, nama_event, create_at, ukm(nama_ukm)')
                  .order('create_at', ascending: false)
                  .limit(5)
              as List;

      return {'success': true, 'data': response};
    } catch (e) {
      print('Error fetching recent activities: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get upcoming events (next 5 events by date)
  Future<Map<String, dynamic>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final response =
          await _supabase
                  .from('events')
                  .select(
                    'id_events, nama_event, tanggal_mulai, lokasi, ukm(nama_ukm)',
                  )
                  .gte('tanggal_mulai', now.toIso8601String())
                  .order('tanggal_mulai')
                  .limit(5)
              as List;

      return {'success': true, 'data': response};
    } catch (e) {
      print('Error fetching upcoming events: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get alerts and warnings
  Future<Map<String, dynamic>> getAlerts() async {
    try {
      List<Map<String, dynamic>> alerts = [];

      // Check events without proposal
      try {
        final eventsNoProposal =
            await _supabase
                    .from('events')
                    .select('id_events, nama_event')
                    .or(
                      'status_proposal.is.null,status_proposal.eq.belum_ajukan',
                    )
                    .eq('status', true)
                as List;

        if (eventsNoProposal.isNotEmpty) {
          alerts.add({
            'type': 'warning',
            'title': 'Event Tanpa Proposal',
            'message':
                '${eventsNoProposal.length} event aktif belum upload proposal',
            'count': eventsNoProposal.length,
          });
        }
      } catch (e) {
        print('Error checking events without proposal: $e');
      }

      // Check overdue LPJ (events ended but no LPJ)
      try {
        final now = DateTime.now();
        final overdueEvents =
            await _supabase
                    .from('events')
                    .select('id_events, nama_event, tanggal_akhir')
                    .lt('tanggal_akhir', now.toIso8601String())
                    .or('status_lpj.is.null,status_lpj.eq.belum_ajukan')
                as List;

        if (overdueEvents.isNotEmpty) {
          alerts.add({
            'type': 'danger',
            'title': 'LPJ Terlambat',
            'message':
                '${overdueEvents.length} event sudah selesai tapi belum upload LPJ',
            'count': overdueEvents.length,
          });
        }
      } catch (e) {
        print('Error checking overdue LPJ: $e');
      }

      // Check pending document approvals
      try {
        int pendingProposals = 0;
        int pendingLpj = 0;

        try {
          final proposals =
              await _supabase
                      .from('event_proposal')
                      .select('id_proposal')
                      .eq('status', 'menunggu')
                  as List;
          pendingProposals = proposals.length;
        } catch (e) {
          print('Error fetching pending proposals: $e');
        }

        try {
          final lpjs =
              await _supabase
                      .from('event_lpj')
                      .select('id_lpj')
                      .eq('status', 'menunggu')
                  as List;
          pendingLpj = lpjs.length;
        } catch (e) {
          print('Error fetching pending LPJs: $e');
        }

        final totalPending = pendingProposals + pendingLpj;
        if (totalPending > 0) {
          alerts.add({
            'type': 'info',
            'title': 'Dokumen Menunggu Review',
            'message':
                '$pendingProposals proposal dan $pendingLpj LPJ perlu direview',
            'count': totalPending,
          });
        }
      } catch (e) {
        print('Error checking pending documents: $e');
      }

      return {'success': true, 'data': alerts};
    } catch (e) {
      print('Error fetching alerts: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get detailed stats for specific table
  Future<Map<String, dynamic>> getTableStats(String tableName) async {
    try {
      final response = await _supabase
          .from(tableName)
          .select('*')
          .count(CountOption.exact);

      return {'success': true, 'count': response.count};
    } catch (e) {
      return {
        'success': false,
        'error': 'Gagal mengambil data: ${e.toString()}',
      };
    }
  }
}
