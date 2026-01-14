import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

class UkmDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService =
      CustomAuthService(); // Singleton instance

  // Public getter for supabase client (needed for notifications)
  SupabaseClient get supabase => _supabase;

  // Timeout duration for requests
  static const Duration _requestTimeout = Duration(seconds: 10);

  /// Helper method to execute query with timeout
  Future<List<dynamic>> _executeQuery(
    dynamic query, {
    String errorContext = '',
  }) async {
    try {
      final result = await query.timeout(_requestTimeout);
      return result as List<dynamic>;
    } catch (e) {
      print('Error $errorContext: $e');
      return [];
    }
  }

  /// Get current UKM ID from logged in user
  /// This method properly queries the ukm table using id_admin
  Future<String?> getCurrentUkmId() async {
    try {
      print('========== GET CURRENT UKM ID ==========');

      // Get current user ID from session (this is id_admin)
      final adminId = _authService.currentUserId;
      print('Current admin ID from session: $adminId');

      if (adminId == null) {
        print('❌ No user logged in');
        return null;
      }

      // Query UKM table to get actual id_ukm based on id_admin
      print('Querying ukm table for admin: $adminId');
      final response = await _supabase
          .from('ukm')
          .select('id_ukm, nama_ukm')
          .eq('id_admin', adminId)
          .maybeSingle();

      print('UKM query result: $response');

      if (response == null) {
        print('❌ No UKM record found for admin: $adminId');
        print('⚠️ The admin exists but UKM profile needs to be created');
        return null;
      }

      final ukmId = response['id_ukm'] as String?;
      final namaUkm = response['nama_ukm'] as String?;
      print('✅ Found UKM: $namaUkm (ID: $ukmId)');

      return ukmId;
    } catch (e) {
      print('❌ Error getting current UKM ID: $e');
      return null;
    }
  }

  /// Get complete UKM details by admin ID (for current logged in UKM admin)
  Future<Map<String, dynamic>?> getCurrentUkmDetails() async {
    try {
      print('========== GET CURRENT UKM DETAILS ==========');

      // Get current admin ID from session
      final adminId = _authService.currentUserId;
      print('Current admin ID: $adminId');

      if (adminId == null) {
        print('❌ No user logged in');
        return null;
      }

      // Query UKM table to get complete UKM details
      final response = await _supabase
          .from('ukm')
          .select(
            'id_ukm, nama_ukm, description, logo, create_at, id_admin, id_current_periode',
          )
          .eq('id_admin', adminId)
          .maybeSingle();

      print('UKM details result: $response');

      if (response == null) {
        print('❌ No UKM profile found for admin: $adminId');
        print('⚠️ Admin needs to create UKM profile first');
        return null;
      }

      print('✅ UKM details loaded: ${response['nama_ukm']}');
      return response;
    } catch (e) {
      print('❌ Error fetching UKM details: $e');
      return null;
    }
  }

  /// Get current active periode (GLOBAL - untuk semua UKM)
  Future<Map<String, dynamic>?> getCurrentPeriode(String? ukmId) async {
    try {
      print('========== GET CURRENT PERIODE (GLOBAL) ==========');

      // Get global periode with status = 'aktif'
      // Periode global berlaku untuk SEMUA UKM
      final activeResponse = await _supabase
          .from('periode_ukm')
          .select(
            'id_periode, nama_periode, semester, tahun, status, tanggal_awal, tanggal_akhir, create_at',
          )
          .ilike('status', 'aktif') // Case insensitive search
          .order('create_at', ascending: false)
          .limit(1)
          .maybeSingle();

      print('Global active periode query result: $activeResponse');

      if (activeResponse != null) {
        print(
          '✅ Found global active periode: ${activeResponse['nama_periode']} (${activeResponse['semester']} ${activeResponse['tahun']})',
        );
        return activeResponse;
      }

      // Fallback: Get latest global periode regardless of status
      print(
        '⚠️ No active global periode found, getting latest global periode...',
      );
      final latestResponse = await _supabase
          .from('periode_ukm')
          .select(
            'id_periode, nama_periode, semester, tahun, status, tanggal_awal, tanggal_akhir, create_at',
          )
          .order('create_at', ascending: false)
          .limit(1)
          .maybeSingle();

      print('Latest global periode query result: $latestResponse');

      if (latestResponse != null) {
        print(
          '⚠️ Using latest global periode: ${latestResponse['nama_periode']} (status: ${latestResponse['status']})',
        );
        print(
          '⚠️ WARNING: This periode status is NOT "aktif", consider updating it in database',
        );
      } else {
        print('❌ No global periode found at all');
      }

      return latestResponse;
    } catch (e) {
      print('❌ Error fetching current periode: $e');
      return null;
    }
  }

  /// Get UKM dashboard statistics
  Future<Map<String, dynamic>> getUkmStats(
    String ukmId, {
    String? periodeId,
  }) async {
    try {
      int totalPeserta = 0;
      int totalEvent = 0;
      int totalPertemuan = 0;

      // ========== GET TOTAL PESERTA ==========
      try {
        print('=== Dashboard getUkmStats DEBUG ===');
        print('ukmId: $ukmId');
        print('periodeId: $periodeId');
        
        // Simple query - just filter by UKM and status
        final pesertaResponse = await _supabase
            .from('user_halaman_ukm')
            .select('id_follow')
            .eq('id_ukm', ukmId)
            .eq('status', 'aktif');

        totalPeserta = (pesertaResponse as List).length;
        print('Dashboard peserta count: $totalPeserta');
      } catch (e) {
        print('Error fetching peserta: $e');
        totalPeserta = 0;
      }

      // ========== GET TOTAL EVENTS (for this UKM and current periode) ==========
      try {
        // Count events for this UKM and periode (matching Event page query)
        var eventQuery = _supabase
            .from('events')
            .select('id_events')
            .eq('id_ukm', ukmId);
        
        // Filter by periode to match Event page (Dashboard shows "Total Event Periode ini")
        if (periodeId != null) {
          eventQuery = eventQuery.eq('id_periode', periodeId);
        }

        final eventResponse = await eventQuery;
        totalEvent = (eventResponse as List).length;
        print('Dashboard events count (UKM $ukmId, periode $periodeId): $totalEvent');
      } catch (e) {
        print('Error fetching events: $e');
        totalEvent = 0;
      }

      // ========== GET TOTAL PERTEMUAN (matching Pertemuan page - upcoming only, NO UKM filter) ==========
      try {
        final now = DateTime.now();
        final todayStr = now.toIso8601String().split('T')[0]; // Get date only
        
        // Pertemuan page uses: _pertemuanService.getAllPertemuan() which loads ALL pertemuan
        // Then client-side filters by "Mendatang" (tanggal >= today)
        // So we should NOT filter by id_ukm, just by upcoming date
        final pertemuanResponse = await _supabase
            .from('pertemuan')
            .select('id_pertemuan')
            .gte('tanggal', todayStr); // Only upcoming pertemuan

        totalPertemuan = (pertemuanResponse as List).length;
        print('Dashboard pertemuan count (upcoming, all UKMs): $totalPertemuan');
      } catch (e) {
        print('Error fetching pertemuan: $e');
        totalPertemuan = 0;
      }

      // ========== GET EVENTS WITHOUT DOCUMENTS ==========
      int eventsWithoutProposal = 0;
      int eventsWithoutLpj = 0;
      
      try {
        // Get all events for this UKM (active events only)
        final allEvents = await _supabase
            .from('events')
            .select('id_events, status, tanggal_akhir')
            .eq('id_ukm', ukmId);
        
        print('DEBUG: Total events for UKM $ukmId: ${(allEvents as List).length}');
        
        // Get all event documents for this UKM
        final allDocs = await _supabase
            .from('event_documents')
            .select('id_event, document_type')
            .eq('id_ukm', ukmId);
        
        print('DEBUG: Total documents for UKM $ukmId: ${(allDocs as List).length}');
        
        // Create sets for quick lookup
        final eventsWithProposal = <String>{};
        final eventsWithLpj = <String>{};
        
        for (final doc in (allDocs as List)) {
          final eventId = doc['id_event']?.toString();
          final docType = doc['document_type']?.toString();
          if (eventId != null) {
            if (docType == 'proposal') {
              eventsWithProposal.add(eventId);
            } else if (docType == 'lpj') {
              eventsWithLpj.add(eventId);
            }
          }
        }
        
        print('DEBUG: Events with proposal: ${eventsWithProposal.length}');
        print('DEBUG: Events with LPJ: ${eventsWithLpj.length}');
        
        // Count events without documents
        final now = DateTime.now();
        for (final event in (allEvents as List)) {
          final eventId = event['id_events']?.toString();
          if (eventId == null) continue;
          
          // Check for missing proposal (all active events should have proposal)
          if (!eventsWithProposal.contains(eventId)) {
            eventsWithoutProposal++;
            print('DEBUG: Event without proposal: $eventId');
          }
          
          // Check for missing LPJ (only for completed events)
          final endDateStr = event['tanggal_akhir']?.toString();
          if (endDateStr != null) {
            try {
              final endDate = DateTime.parse(endDateStr);
              if (endDate.isBefore(now) && !eventsWithLpj.contains(eventId)) {
                eventsWithoutLpj++;
                print('DEBUG: Completed event without LPJ: $eventId');
              }
            } catch (e) {
              // Ignore parse errors
            }
          }
        }
        
        print('======== ALERT SUMMARY ========');
        print('Events without proposal: $eventsWithoutProposal');
        print('Events without LPJ: $eventsWithoutLpj');
        print('===============================');
      } catch (e) {
        print('Error checking event documents: $e');
      }

      print(
        'UKM stats loaded: Peserta=$totalPeserta, Events=$totalEvent, Pertemuan=$totalPertemuan',
      );

      return {
        'success': true,
        'data': {
          'totalPeserta': totalPeserta,
          'totalEvent': totalEvent,
          'totalPertemuan': totalPertemuan,
          'eventsWithoutProposal': eventsWithoutProposal,
          'eventsWithoutLpj': eventsWithoutLpj,
        },
      };
    } catch (e) {
      print('Error loading UKM stats: $e');
      return {
        'success': false,
        'error': 'Gagal mengambil data statistik: ${e.toString()}',
      };
    }
  }

  /// Get UKM informasi for carousel
  /// Includes both UKM-specific informasi and global informasi (id_ukm = NULL)
  Future<Map<String, dynamic>> getUkmInformasi(
    String ukmId, {
    int limit = 5,
    String? periodeId,
  }) async {
    try {
      print('========== GET UKM INFORMASI ==========');
      print('UKM ID: $ukmId');
      print('Periode ID: $periodeId');
      print('Limit: $limit');

      // Query untuk informasi UKM spesifik DAN informasi global (id_ukm = NULL)
      var query = _supabase
          .from('informasi')
          .select(
            'id_informasi, judul, deskripsi, gambar, create_at, status_aktif, id_ukm, id_periode',
          )
          .eq('status_aktif', true)
          .or('id_ukm.eq.$ukmId,id_ukm.is.null'); // UKM spesifik ATAU global

      // Add periode filter if provided
      if (periodeId != null) {
        query = query.or('id_periode.eq.$periodeId,id_periode.is.null');
      }

      final response = await _executeQuery(
        query.order('create_at', ascending: false).limit(limit),
        errorContext: 'fetching UKM informasi',
      );

      print('✅ Found ${response.length} informasi (including global)');
      return {'success': true, 'data': response};
    } catch (e) {
      print('❌ Error fetching UKM informasi: $e');
      return {
        'success': false,
        'error': 'Gagal mengambil informasi: ${e.toString()}',
      };
    }
  }

  /// Get UKM details
  Future<Map<String, dynamic>> getUkmDetails(String ukmId) async {
    try {
      final response = await _executeQuery(
        _supabase
            .from('ukm')
            .select('id_ukm, nama_ukm, description, logo')
            .eq('id_ukm', ukmId)
            .single(),
        errorContext: 'fetching UKM details',
      );

      if (response.isEmpty) {
        return {'success': false, 'error': 'UKM tidak ditemukan'};
      }

      return {'success': true, 'data': response[0]};
    } catch (e) {
      print('Error fetching UKM details: $e');
      return {
        'success': false,
        'error': 'Gagal mengambil detail UKM: ${e.toString()}',
      };
    }
  }

  /// Get recent events for UKM
  Future<Map<String, dynamic>> getRecentEvents(
    String ukmId, {
    int limit = 5,
  }) async {
    try {
      final response = await _executeQuery(
        _supabase
            .from('events')
            .select('id_events, nama_event, tanggal_mulai, lokasi, status')
            .eq('id_ukm', ukmId)
            .order('create_at', ascending: false)
            .limit(limit),
        errorContext: 'fetching recent events',
      );

      return {'success': true, 'data': response};
    } catch (e) {
      print('Error fetching recent events: $e');
      return {
        'success': false,
        'error': 'Gagal mengambil event terbaru: ${e.toString()}',
      };
    }
  }

  /// Get upcoming events for UKM
  Future<Map<String, dynamic>> getUpcomingEvents(
    String ukmId, {
    int limit = 5,
  }) async {
    try {
      final now = DateTime.now();
      final response = await _executeQuery(
        _supabase
            .from('events')
            .select('id_events, nama_event, tanggal_mulai, lokasi')
            .eq('id_ukm', ukmId)
            .gte('tanggal_mulai', now.toIso8601String())
            .order('tanggal_mulai')
            .limit(limit),
        errorContext: 'fetching upcoming events',
      );

      return {'success': true, 'data': response};
    } catch (e) {
      print('Error fetching upcoming events: $e');
      return {
        'success': false,
        'error': 'Gagal mengambil event mendatang: ${e.toString()}',
      };
    }
  }

  /// Get all active UKM members
  Future<List<Map<String, dynamic>>> getUkmMembers(String ukmId) async {
    try {
      final response = await _supabase
          .from('user_halaman_ukm')
          .select('id_user, status')
          .eq('id_ukm', ukmId)
          .eq('status', 'aktif');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching UKM members: $e');
      return [];
    }
  }

  /// Get alerts and warnings for UKM dashboard
  /// Similar pattern to admin DashboardService.getAlerts()
  Future<Map<String, dynamic>> getAlerts(String ukmId) async {
    try {
      List<Map<String, dynamic>> alerts = [];

      // Check events without proposal
      try {
        final eventsNoProposal = await _supabase
            .from('events')
            .select('id_events, nama_event')
            .eq('id_ukm', ukmId)
            .eq('status', true)
            .or('status_proposal.is.null,status_proposal.eq.belum_ajukan');

        if ((eventsNoProposal as List).isNotEmpty) {
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
        final overdueEvents = await _supabase
            .from('events')
            .select('id_events, nama_event, tanggal_akhir')
            .eq('id_ukm', ukmId)
            .lt('tanggal_akhir', now.toIso8601String())
            .or('status_lpj.is.null,status_lpj.eq.belum_ajukan');

        if ((overdueEvents as List).isNotEmpty) {
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
          final proposals = await _supabase
              .from('event_documents')
              .select('id_document')
              .eq('id_ukm', ukmId)
              .eq('document_type', 'proposal')
              .eq('status', 'menunggu');
          pendingProposals = (proposals as List).length;
        } catch (e) {
          print('Error fetching pending proposals: $e');
        }

        try {
          final lpjs = await _supabase
              .from('event_documents')
              .select('id_document')
              .eq('id_ukm', ukmId)
              .eq('document_type', 'lpj')
              .eq('status', 'menunggu');
          pendingLpj = (lpjs as List).length;
        } catch (e) {
          print('Error fetching pending LPJs: $e');
        }

        final totalPending = pendingProposals + pendingLpj;
        if (totalPending > 0) {
          alerts.add({
            'type': 'info',
            'title': 'Dokumen Menunggu Review',
            'message':
                '$pendingProposals proposal dan $pendingLpj LPJ menunggu review admin',
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
  /// Get Top Members by attendance
  Future<List<Map<String, dynamic>>> getTopMembers(
    String ukmId, {
    String? periodeId,
    int limit = 5,
  }) async {
    try {
      print('========== GET TOP MEMBERS ==========');
      
      // 1. Get all pertemuan IDs for this UKM (and periode if specified)
      var query = _supabase
          .from('pertemuan')
          .select('id_pertemuan')
          .or('id_ukm.eq.$ukmId,id_ukm.is.null');

      // Note: We might want to filter by periode, but 'pertemuan' table doesn't seem to have 'id_periode' explicitly shown in previous `read_file` of `pertemuan_service.dart`.
      // Let's check `pertemuan_service.dart` again or `pertemuan` model.
      // `PertemuanService` used `.or('id_ukm.eq.$idUkm,id_ukm.is.null')`.
      
      final pertemuanResponse = await _executeQuery(
        query,
        errorContext: 'fetching pertemuan for top members',
      );
      
      if (pertemuanResponse.isEmpty) return [];

      final pertemuanIds = pertemuanResponse
          .map((p) => p['id_pertemuan'])
          .toList();

      // 2. Get all absences for these meetings
      final attendanceResponse = await _supabase
          .from('absen_pertemuan')
          .select('id_user')
          .filter('id_pertemuan', 'in', pertemuanIds);

      // 3. Count attendance by user
      final userCounts = <String, int>{};
      for (var record in (attendanceResponse as List)) {
        final userId = record['id_user'] as String;
        userCounts[userId] = (userCounts[userId] ?? 0) + 1;
      }

      // 4. Sort by count descending and take top 'limit'
      final sortedUsers = userCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topUsers = sortedUsers.take(limit).toList();
      
      if (topUsers.isEmpty) return [];

      // 5. Get user details for these users
      final userIds = topUsers.map((e) => e.key).toList();
      final usersResponse = await _supabase
          .from('users')
          .select('id_user, username, email, nim, picture')
          .filter('id_user', 'in', userIds);
          
      final usersMap = {
        for (var u in (usersResponse as List)) u['id_user']: u
      };

      // 6. Construct result
      final results = <Map<String, dynamic>>[];
      for (var entry in topUsers) {
        final userId = entry.key;
        final count = entry.value;
        final user = usersMap[userId];
        
        if (user != null) {
          results.add({
            'id_user': userId,
            'nama': user['username'],
            'nim': user['nim'],
            'picture': user['picture'],
            'kehadiran_count': count,
          });
        }
      }

      print('✅ Found ${results.length} top members');
      return results;
    } catch (e) {
      print('❌ Error fetching top members: $e');
      return [];
    }
  }
}

