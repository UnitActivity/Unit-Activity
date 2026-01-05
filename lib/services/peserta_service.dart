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
          .eq('status', 'active')
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
      // Get peserta list
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
          .eq('id_periode', idPeriode)
          .eq('status', 'active')
          .order('follow', ascending: false);

      // Get total pertemuan for this UKM and periode
      final totalPertemuanResponse = await _supabase
          .from('pertemuan')
          .select('id_pertemuan')
          .eq('id_ukm', idUkm)
          .eq('id_periode', idPeriode);

      final totalPertemuan = (totalPertemuanResponse as List).length;

      // Map peserta with attendance data
      final pesertaList = <Map<String, dynamic>>[];

      for (var item in response as List) {
        // Get attendance count for this user
        final attendanceResponse = await _supabase
            .from('user_pertemuan')
            .select('id_user_pertemuan')
            .eq('id_user', item['id_user'])
            .eq('id_periode', idPeriode);

        final kehadiranCount = (attendanceResponse as List).length;

        pesertaList.add({
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
        });
      }

      return pesertaList;
    } catch (e) {
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
          .eq('status', 'active');

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
          .eq('status', 'active');

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get member count: $e');
    }
  }
}
