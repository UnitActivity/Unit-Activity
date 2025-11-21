import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      int ukmCount = 0;
      int usersCount = 0;
      int eventCount = 0;

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

      print(
        'Dashboard stats loaded: UKM=$ukmCount, Users=$usersCount, Events=$eventCount',
      );

      return {
        'success': true,
        'data': {
          'totalUkm': ukmCount,
          'totalUsers': usersCount,
          'totalEvent': eventCount,
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
