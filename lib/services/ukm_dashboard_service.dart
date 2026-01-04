import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

class UkmDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService =
      CustomAuthService(); // Singleton instance

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

      // Get global periode (id_ukm = NULL, status = 'aktif')
      // Periode global berlaku untuk SEMUA UKM
      final activeResponse = await _supabase
          .from('periode_ukm')
          .select(
            'id_periode, nama_periode, semester, tahun, status, tanggal_awal, tanggal_akhir, create_at',
          )
          .isFilter('id_ukm', null) // Periode global (id_ukm = NULL)
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
          .isFilter('id_ukm', null) // Periode global
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
        final pesertaQuery = _supabase
            .from('user_halaman_ukm')
            .select('id_follow')
            .eq('id_ukm', ukmId)
            .eq('status', 'aktif');

        if (periodeId != null) {
          pesertaQuery.eq('id_periode', periodeId);
        }

        final pesertaResponse = await _executeQuery(
          pesertaQuery,
          errorContext: 'fetching peserta count',
        );
        totalPeserta = pesertaResponse.length;
      } catch (e) {
        print('Error fetching peserta: $e');
        totalPeserta = 0;
      }

      // ========== GET TOTAL EVENTS ==========
      try {
        final eventQuery = _supabase
            .from('events')
            .select('id_events')
            .eq('id_ukm', ukmId);

        if (periodeId != null) {
          eventQuery.eq('id_periode', periodeId);
        }

        final eventResponse = await _executeQuery(
          eventQuery,
          errorContext: 'fetching events count',
        );
        totalEvent = eventResponse.length;
      } catch (e) {
        print('Error fetching events: $e');
        totalEvent = 0;
      }

      // ========== GET TOTAL PERTEMUAN ==========
      try {
        final pertemuanQuery = _supabase
            .from('pertemuan')
            .select('id_pertemuan')
            .eq('id_ukm', ukmId);

        if (periodeId != null) {
          pertemuanQuery.eq('id_periode', periodeId);
        }

        final pertemuanResponse = await _executeQuery(
          pertemuanQuery,
          errorContext: 'fetching pertemuan count',
        );
        totalPertemuan = pertemuanResponse.length;
      } catch (e) {
        print('Error fetching pertemuan: $e');
        totalPertemuan = 0;
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
}
