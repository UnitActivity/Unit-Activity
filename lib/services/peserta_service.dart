import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/models/user_halaman_ukm_model.dart';

class PesertaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all members (peserta) without UUID filter
  Future<List<Map<String, dynamic>>> getAllPeserta() async {
    try {
      final response = await _supabase
          .from('user_halaman_ukm')
          .select('''
            id_follow,
            follow,
            status,
            logbook,
            deskripsi,
            id_user,
            users!inner(
              id_user,
              username,
              email,
              nim
            )
          ''')
          .eq('status', 'aktif')
          .order('follow', ascending: false);

      print('Raw peserta response: $response'); // Debug print

      return (response as List).map((item) {
        final result = {
          'id_follow': item['id_follow'],
          'id_user': item['id_user'],
          'nama': item['users']['username'],
          'email': item['users']['email'],
          'nim': item['users']['nim'],
          'tanggal': item['follow'],
          'status': item['status'],
          'logbook': item['logbook'],
          'deskripsi': item['deskripsi'],
        };
        print('Mapped peserta: $result'); // Debug print
        return result;
      }).toList();
    } catch (e) {
      print('Error in getAllPeserta: $e'); // Debug print
      throw Exception('Failed to load peserta: $e');
    }
  }

  // Get all members (peserta) for a specific UKM and periode
  Future<List<Map<String, dynamic>>> getPesertaByUkm(
    String idUkm,
    String idPeriode,
  ) async {
    try {
      print('=== getPesertaByUkm DEBUG ===');
      print('idUkm: $idUkm');
      print('idPeriode: $idPeriode');

      // First, let's see ALL data for this UKM (even inactive)
      print('\n--- Checking ALL data for UKM (including inactive) ---');
      final allDataResponse = await _supabase
          .from('user_halaman_ukm')
          .select('id_follow, id_user, id_ukm, id_periode, status, follow')
          .eq('id_ukm', idUkm);

      print('Total records for UKM: ${(allDataResponse as List).length}');
      for (var record in allDataResponse) {
        print(
          '  - id_follow: ${record['id_follow']}, id_user: ${record['id_user']}, '
          'id_periode: ${record['id_periode']}, status: ${record['status']}',
        );
      }

      // Now get active peserta list with user details
      print('\n--- Fetching ACTIVE peserta with details ---');
      final response = await _supabase
          .from('user_halaman_ukm')
          .select('''
            *,
            users!inner(
              id_user,
              username,
              email,
              nim
            )
          ''')
          .eq('id_ukm', idUkm)
          .or(
            'status.eq.aktif,status.eq.active',
          ) // Accept both 'aktif' and 'active'
          .order('follow', ascending: false);

      print('Active peserta count: ${(response as List).length}');

      if ((response as List).isEmpty) {
        print('⚠️ WARNING: No active peserta found for UKM $idUkm');
        print('Check if:');
        print('  1. Users have joined this UKM (check user_halaman_ukm table)');
        print('  2. Status column is set to "aktif" or "active"');
        print('  3. id_ukm matches exactly');
        return [];
      }

      if ((response as List).isNotEmpty) {
        print('Sample peserta data:');
        print(response.first);
      }

      // Get total pertemuan for this UKM
      int totalPertemuan = 0;
      try {
        final totalPertemuanResponse = await _supabase
            .from('pertemuan')
            .select('id_pertemuan')
            .eq('id_ukm', idUkm);
        totalPertemuan = (totalPertemuanResponse as List).length;
        print('Total pertemuan for this UKM: $totalPertemuan');
      } catch (e) {
        print('Warning: Could not fetch pertemuan count: $e');
      }

      // Map peserta with attendance data
      final pesertaList = <Map<String, dynamic>>[];

      for (var item in response as List) {
        int kehadiranCount = 0;

        try {
          final attendanceResponse = await _supabase
              .from('absen_pertemuan')
              .select()
              .eq('id_user', item['id_user']);
          kehadiranCount = (attendanceResponse as List).length;
        } catch (e) {
          print(
            'Warning: Could not fetch attendance for user ${item['id_user']}: $e',
          );
          kehadiranCount = 0;
        }

        final peserta = {
          'id_follow': item['id_follow'],
          'id_user': item['id_user'],
          'nama': item['users']['username'],
          'email': item['users']['email'],
          'nim': item['users']['nim'],
          'tanggal': item['follow'],
          'status': item['status'],
          'logbook': item['logbook'],
          'deskripsi': item['deskripsi'],
          'kehadiran_count': kehadiranCount,
          'total_pertemuan': totalPertemuan,
        };

        print('  ✓ Peserta: ${peserta['nama']} (${peserta['nim']})');
        pesertaList.add(peserta);
      }

      print('=== Total peserta loaded: ${pesertaList.length} ===\n');
      return pesertaList;
    } catch (e) {
      print('❌ ERROR in getPesertaByUkm: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to load peserta: $e');
    }
  }

  // Add new member
  Future<UserHalamanUkmModel> addPeserta(UserHalamanUkmModel peserta) async {
    try {
      final response = await _supabase
          .from('user_halaman_ukm')
          .insert(peserta.toJson())
          .select()
          .single();

      return UserHalamanUkmModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add peserta: $e');
    }
  }

  // Update member info
  Future<UserHalamanUkmModel> updatePeserta(
    String idFollow,
    UserHalamanUkmModel peserta,
  ) async {
    try {
      final response = await _supabase
          .from('user_halaman_ukm')
          .update(peserta.toJson())
          .eq('id_follow', idFollow)
          .select()
          .single();

      return UserHalamanUkmModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update peserta: $e');
    }
  }

  // Remove member (unfollow)
  Future<void> removePeserta(String idFollow, String reason) async {
    try {
      await _supabase
          .from('user_halaman_ukm')
          .update({
            'status': 'inactive',
            'unfollow': DateTime.now().toIso8601String(),
            'unfollow_reason': reason,
          })
          .eq('id_follow', idFollow);
    } catch (e) {
      throw Exception('Failed to remove peserta: $e');
    }
  }

  // Check if user is already a member
  Future<bool> isMember(String idUser, String idUkm, String idPeriode) async {
    try {
      final response = await _supabase
          .from('user_halaman_ukm')
          .select()
          .eq('id_user', idUser)
          .eq('id_ukm', idUkm)
          .eq('id_periode', idPeriode)
          .eq('status', 'aktif');

      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check membership: $e');
    }
  }

  // Get member count
  Future<int> getMemberCount(String idUkm, String idPeriode) async {
    try {
      final response = await _supabase
          .from('user_halaman_ukm')
          .select()
          .eq('id_ukm', idUkm)
          .eq('id_periode', idPeriode)
          .eq('status', 'aktif');

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get member count: $e');
    }
  }

  // Search users by NIM for adding as peserta
  Future<List<Map<String, dynamic>>> searchUsersByNim(String nimQuery) async {
    try {
      if (nimQuery.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('users')
          .select('id_user, username, email, nim, picture')
          .ilike('nim', '%$nimQuery%')
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching users by NIM: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  // Get user by exact NIM
  Future<Map<String, dynamic>?> getUserByNim(String nim) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id_user, username, email, nim, picture')
          .eq('nim', nim)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting user by NIM: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  // Add peserta manually by NIM
  Future<Map<String, dynamic>> addPesertaByNim({
    required String nim,
    required String idUkm,
    required String idPeriode,
  }) async {
    try {
      // First, get the user by NIM
      final user = await getUserByNim(nim);
      if (user == null) {
        throw Exception('User dengan NIM $nim tidak ditemukan');
      }

      final idUser = user['id_user'];

      // Check if user is already a member
      final existingMember = await _supabase
          .from('user_halaman_ukm')
          .select()
          .eq('id_user', idUser)
          .eq('id_ukm', idUkm)
          .eq('status', 'aktif')
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('User sudah terdaftar sebagai anggota UKM ini');
      }

      // Add user as peserta
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('user_halaman_ukm')
          .insert({
            'id_user': idUser,
            'id_ukm': idUkm,
            'id_periode': idPeriode,
            'follow': now,
            'status': 'aktif',
            'logbook': null,
            'deskripsi': 'Ditambahkan manual oleh admin UKM',
          })
          .select('''
            *,
            users!inner(
              id_user,
              username,
              email,
              nim
            )
          ''')
          .single();

      return {
        'id_follow': response['id_follow'],
        'id_user': response['id_user'],
        'nama': response['users']['username'],
        'email': response['users']['email'],
        'nim': response['users']['nim'],
        'tanggal': response['follow'],
        'status': response['status'],
        'logbook': response['logbook'],
        'deskripsi': response['deskripsi'],
      };
    } catch (e) {
      print('Error adding peserta by NIM: $e');
      rethrow;
    }
  }

  // Delete peserta (hard delete)
  Future<void> deletePeserta(String idFollow) async {
    try {
      await _supabase
          .from('user_halaman_ukm')
          .delete()
          .eq('id_follow', idFollow);
    } catch (e) {
      print('Error deleting peserta: $e');
      throw Exception('Failed to delete peserta: $e');
    }
  }

  // Get all registered users (for autocomplete suggestions)
  Future<List<Map<String, dynamic>>> getAllRegisteredUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id_user, username, email, nim, picture')
          .order('nim', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting all registered users: $e');
      throw Exception('Failed to get users: $e');
    }
  }
}
