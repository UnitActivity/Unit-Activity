import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/models/informasi_model.dart';

class InformasiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all informasi (without UUID filter)
  Future<List<InformasiModel>> getAllInformasi() async {
    try {
      final response = await _supabase
          .from('informasi')
          .select()
          .eq('status_aktif', true)
          .order('create_at', ascending: false);

      return (response as List)
          .map((json) => InformasiModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load informasi: $e');
    }
  }

  // Get all informasi for a specific UKM
  Future<List<InformasiModel>> getInformasiByUkm(String idUkm) async {
    try {
      final response = await _supabase
          .from('informasi')
          .select()
          .eq('id_ukm', idUkm)
          .eq('status_aktif', true)
          .order('create_at', ascending: false);

      return (response as List)
          .map((json) => InformasiModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load informasi: $e');
    }
  }

  // Get informasi by ID
  Future<InformasiModel?> getInformasiById(String idInformasi) async {
    try {
      final response = await _supabase
          .from('informasi')
          .select()
          .eq('id_informasi', idInformasi)
          .single();

      return InformasiModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load informasi: $e');
    }
  }

  // Create new informasi
  Future<InformasiModel> createInformasi(InformasiModel informasi) async {
    try {
      final response = await _supabase
          .from('informasi')
          .insert(informasi.toJson())
          .select()
          .single();

      return InformasiModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create informasi: $e');
    }
  }

  // Update informasi
  Future<InformasiModel> updateInformasi(
      String idInformasi, InformasiModel informasi) async {
    try {
      final response = await _supabase
          .from('informasi')
          .update(informasi.toJson())
          .eq('id_informasi', idInformasi)
          .select()
          .single();

      return InformasiModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update informasi: $e');
    }
  }

  // Delete informasi (soft delete)
  Future<void> deleteInformasi(String idInformasi) async {
    try {
      await _supabase
          .from('informasi')
          .update({'status_aktif': false})
          .eq('id_informasi', idInformasi);
    } catch (e) {
      throw Exception('Failed to delete informasi: $e');
    }
  }

  // Hard delete informasi
  Future<void> hardDeleteInformasi(String idInformasi) async {
    try {
      await _supabase
          .from('informasi')
          .delete()
          .eq('id_informasi', idInformasi);
    } catch (e) {
      throw Exception('Failed to delete informasi: $e');
    }
  }
}
