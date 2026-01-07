import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/models/pertemuan_model.dart';
import 'package:unit_activity/models/absen_pertemuan_model.dart';

class PertemuanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all pertemuan (without UUID filter)
  Future<List<PertemuanModel>> getAllPertemuan() async {
    try {
      final response = await _supabase
          .from('pertemuan')
          .select()
          .order('tanggal', ascending: false);

      return (response as List)
          .map((json) => PertemuanModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load pertemuan: $e');
    }
  }

  // Get all pertemuan for a specific UKM and periode
  Future<List<PertemuanModel>> getPertemuanByUkm(
    String idUkm,
    String idPeriode,
  ) async {
    try {
      // Include pertemuan with matching id_ukm OR null id_ukm (legacy data)
      final response = await _supabase
          .from('pertemuan')
          .select()
          .or('id_ukm.eq.$idUkm,id_ukm.is.null')
          .order('tanggal', ascending: false);

      return (response as List)
          .map((json) => PertemuanModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load pertemuan: $e');
    }
  }

  // Get pertemuan by ID
  Future<PertemuanModel?> getPertemuanById(String idPertemuan) async {
    try {
      final response = await _supabase
          .from('pertemuan')
          .select()
          .eq('id_pertemuan', idPertemuan)
          .single();

      return PertemuanModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load pertemuan: $e');
    }
  }

  // Create new pertemuan
  Future<PertemuanModel> createPertemuan(PertemuanModel pertemuan) async {
    try {
      final response = await _supabase
          .from('pertemuan')
          .insert(pertemuan.toJson())
          .select()
          .single();

      return PertemuanModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create pertemuan: $e');
    }
  }

  // Update pertemuan
  Future<PertemuanModel> updatePertemuan(PertemuanModel pertemuan) async {
    try {
      final response = await _supabase
          .from('pertemuan')
          .update(pertemuan.toJson())
          .eq('id_pertemuan', pertemuan.idPertemuan!)
          .select()
          .single();

      return PertemuanModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update pertemuan: $e');
    }
  }

  // Delete pertemuan
  Future<void> deletePertemuan(String idPertemuan) async {
    try {
      await _supabase
          .from('pertemuan')
          .delete()
          .eq('id_pertemuan', idPertemuan);
    } catch (e) {
      throw Exception('Failed to delete pertemuan: $e');
    }
  }

  // Get attendance records for a specific pertemuan
  Future<List<AbsenPertemuanModel>> getAbsensiByPertemuan(
    String idPertemuan,
  ) async {
    try {
      final response = await _supabase
          .from('absen_pertemuan')
          .select('''
            *,
            users!inner(
              username,
              nim
            )
          ''')
          .eq('id_pertemuan', idPertemuan)
          .order('jam', ascending: false);

      return (response as List)
          .map((json) => AbsenPertemuanModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load absensi: $e');
    }
  }

  // Record attendance
  Future<AbsenPertemuanModel> recordAbsensi(AbsenPertemuanModel absensi) async {
    try {
      final response = await _supabase
          .from('absen_pertemuan')
          .insert(absensi.toJson())
          .select()
          .single();

      return AbsenPertemuanModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to record absensi: $e');
    }
  }

  // Check if user already attended
  Future<bool> hasAttended(String idUser, String idPertemuan) async {
    try {
      final response = await _supabase
          .from('absen_pertemuan')
          .select()
          .eq('id_user', idUser)
          .eq('id_pertemuan', idPertemuan);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
