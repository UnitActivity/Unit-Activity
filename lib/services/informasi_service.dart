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

  // Get all informasi for a specific UKM with pagination
  Future<List<InformasiModel>> getInformasiByUkm(
    String idUkm, {
    int page = 1,
    int limit = 5,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      final response = await _supabase
          .from('informasi')
          .select()
          .eq('id_ukm', idUkm)
          .eq('status_aktif', true)
          .order('create_at', ascending: false)
          .range(from, to);

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

      final createdInformasi = InformasiModel.fromJson(response);

      // Create notification for UKM members if id_ukm is present
      if (createdInformasi.idUkm != null &&
          createdInformasi.statusAktif == true) {
        try {
          // Get UKM name
          final ukmData = await _supabase
              .from('ukm')
              .select('nama_ukm')
              .eq('id_ukm', createdInformasi.idUkm!)
              .single();

          final ukmName = ukmData['nama_ukm'] ?? 'UKM';

          // Create notification for UKM members using notification_preference
          await _supabase.from('notification_preference').insert({
            'id_ukm': createdInformasi.idUkm,
            'judul': '📢 Informasi Baru dari $ukmName',
            'pesan':
                createdInformasi.deskripsi?.isNotEmpty == true &&
                    createdInformasi.deskripsi!.length > 100
                ? '${createdInformasi.deskripsi!.substring(0, 100)}...'
                : createdInformasi.deskripsi ??
                      'Informasi baru telah ditambahkan',
            'type': 'info',
            'id_informasi': response['id_informasi'],
            'is_read': false,
            'create_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          print('Error creating UKM notification: $e');
          // Continue even if notification fails
        }
      }

      return createdInformasi;
    } catch (e) {
      throw Exception('Failed to create informasi: $e');
    }
  }

  // Update informasi
  Future<InformasiModel> updateInformasi(
    String idInformasi,
    InformasiModel informasi,
  ) async {
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
