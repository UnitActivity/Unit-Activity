import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get events by UKM and periode
  Future<List<Map<String, dynamic>>> getEventsByUkm({
    required String ukmId,
    String? periodeId,
  }) async {
    try {
      print('========== GET EVENTS BY UKM ==========');
      print('UKM ID: $ukmId');
      print('Periode ID: $periodeId');

      var query = _supabase
          .from('events')
          .select('''
            id_events,
            nama_event,
            deskripsi,
            tanggal_mulai,
            tanggal_akhir,
            lokasi,
            max_participant,
            tipevent,
            status,
            status_proposal,
            status_lpj,
            id_ukm,
            id_periode
          ''')
          .eq('id_ukm', ukmId);

      if (periodeId != null) {
        query = query.eq('id_periode', periodeId);
      }

      final response = await query.order('tanggal_mulai', ascending: false);

      print('✅ Found ${response.length} events');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting events: $e');
      rethrow;
    }
  }

  /// Get event by ID
  Future<Map<String, dynamic>?> getEventById(String eventId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('''
            id_events,
            nama_event,
            deskripsi,
            tanggal_mulai,
            tanggal_akhir,
            lokasi,
            max_participant,
            tipevent,
            status,
            status_proposal,
            status_lpj,
            id_ukm,
            id_periode
          ''')
          .eq('id_events', eventId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error getting event by ID: $e');
      rethrow;
    }
  }

  /// Create new event
  Future<Map<String, dynamic>> createEvent({
    required String namaEvent,
    required String deskripsi,
    required DateTime tanggalMulai,
    required DateTime tanggalAkhir,
    required String lokasi,
    required int maxParticipant,
    required String tipevent,
    required String ukmId,
    required String periodeId,
  }) async {
    try {
      print('========== CREATE EVENT ==========');
      print('Event: $namaEvent');
      print('UKM ID: $ukmId');
      print('Periode ID: $periodeId');

      final response = await _supabase
          .from('events')
          .insert({
            'nama_event': namaEvent,
            'deskripsi': deskripsi,
            'tanggal_mulai': tanggalMulai.toIso8601String(),
            'tanggal_akhir': tanggalAkhir.toIso8601String(),
            'lokasi': lokasi,
            'max_participant': maxParticipant,
            'tipevent': tipevent,
            'status': true,
            'status_proposal': 'belum_ajukan',
            'status_lpj': 'belum_ajukan',
            'id_ukm': ukmId,
            'id_periode': periodeId,
          })
          .select()
          .single();

      print('✅ Event created: ${response['id_events']}');
      return response;
    } catch (e) {
      print('❌ Error creating event: $e');
      rethrow;
    }
  }

  /// Update event
  Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    String? namaEvent,
    String? deskripsi,
    DateTime? tanggalMulai,
    DateTime? tanggalAkhir,
    String? lokasi,
    int? maxParticipant,
    String? tipevent,
    bool? status,
  }) async {
    try {
      print('========== UPDATE EVENT ==========');
      print('Event ID: $eventId');

      final Map<String, dynamic> updates = {};
      if (namaEvent != null) updates['nama_event'] = namaEvent;
      if (deskripsi != null) updates['deskripsi'] = deskripsi;
      if (tanggalMulai != null) {
        updates['tanggal_mulai'] = tanggalMulai.toIso8601String();
      }
      if (tanggalAkhir != null) {
        updates['tanggal_akhir'] = tanggalAkhir.toIso8601String();
      }
      if (lokasi != null) updates['lokasi'] = lokasi;
      if (maxParticipant != null) updates['max_participant'] = maxParticipant;
      if (tipevent != null) updates['tipevent'] = tipevent;
      if (status != null) updates['status'] = status;

      final response = await _supabase
          .from('events')
          .update(updates)
          .eq('id_events', eventId)
          .select()
          .single();

      print('✅ Event updated');
      return response;
    } catch (e) {
      print('❌ Error updating event: $e');
      rethrow;
    }
  }

  /// Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      print('========== DELETE EVENT ==========');
      print('Event ID: $eventId');

      await _supabase.from('events').delete().eq('id_events', eventId);

      print('✅ Event deleted');
    } catch (e) {
      print('❌ Error deleting event: $e');
      rethrow;
    }
  }

  /// Get event participants count
  Future<int> getParticipantCount(String eventId) async {
    try {
      final response = await _supabase
          .from('event_participants')
          .select('id_participant')
          .eq('id_event', eventId);

      return response.length;
    } catch (e) {
      print('❌ Error getting participant count: $e');
      return 0;
    }
  }

  /// Update proposal status
  Future<void> updateProposalStatus({
    required String eventId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('events')
          .update({'status_proposal': status})
          .eq('id_events', eventId);

      print('✅ Proposal status updated: $status');
    } catch (e) {
      print('❌ Error updating proposal status: $e');
      rethrow;
    }
  }

  /// Update LPJ status
  Future<void> updateLPJStatus({
    required String eventId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('events')
          .update({'status_lpj': status})
          .eq('id_events', eventId);

      print('✅ LPJ status updated: $status');
    } catch (e) {
      print('❌ Error updating LPJ status: $e');
      rethrow;
    }
  }
}
