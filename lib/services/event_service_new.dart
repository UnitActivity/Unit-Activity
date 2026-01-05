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
    String? gambar,
  }) async {
    try {
      print('========== CREATE EVENT ==========');
      print('Event: $namaEvent');
      print('UKM ID: $ukmId');
      print('Periode ID: $periodeId');

      final Map<String, dynamic> eventData = {
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
      };

      if (gambar != null) {
        eventData['gambar'] = gambar;
      }

      final response = await _supabase
          .from('events')
          .insert(eventData)
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

  /// Generate QR code for event attendance (valid for 10 seconds)
  Future<Map<String, dynamic>> generateAttendanceQR(String eventId) async {
    try {
      print('========== GENERATE ATTENDANCE QR ==========');
      print('Event ID: $eventId');

      final qrCode = '${eventId}_${DateTime.now().millisecondsSinceEpoch}';
      final qrTime = DateTime.now().toIso8601String();

      await _supabase
          .from('events')
          .update({'qr_code': qrCode, 'qr_time': qrTime})
          .eq('id_events', eventId);

      print('✅ QR Code generated: $qrCode');
      return {
        'qr_code': qrCode,
        'qr_time': qrTime,
        'expires_at': DateTime.now()
            .add(const Duration(seconds: 10))
            .toIso8601String(),
      };
    } catch (e) {
      print('❌ Error generating QR code: $e');
      rethrow;
    }
  }

  /// Verify QR code and record attendance
  Future<bool> recordAttendance({
    required String eventId,
    required String userId,
    required String qrCode,
  }) async {
    try {
      print('========== RECORD ATTENDANCE ==========');
      print('Event ID: $eventId, User ID: $userId');

      // Get event QR data
      final event = await _supabase
          .from('events')
          .select('qr_code, qr_time')
          .eq('id_events', eventId)
          .maybeSingle();

      if (event == null) {
        throw Exception('Event tidak ditemukan');
      }

      // Verify QR code matches
      if (event['qr_code'] != qrCode) {
        throw Exception('QR Code tidak valid');
      }

      // Check if QR code is still valid (within 10 seconds)
      final qrTime = DateTime.parse(event['qr_time']);
      final now = DateTime.now();
      final difference = now.difference(qrTime).inSeconds;

      if (difference > 10) {
        throw Exception('QR Code sudah kadaluarsa');
      }

      // Check if already recorded
      final existing = await _supabase
          .from('absen_event')
          .select('id_absen_event')
          .eq('id_event', eventId)
          .eq('id_user', userId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Anda sudah melakukan absensi');
      }

      // Record attendance
      await _supabase.from('absen_event').insert({
        'id_event': eventId,
        'id_user': userId,
        'tanggal': now.toIso8601String(),
        'status': 'hadir',
      });

      print('✅ Attendance recorded');
      return true;
    } catch (e) {
      print('❌ Error recording attendance: $e');
      rethrow;
    }
  }

  /// Get pending participants (status: pending)
  Future<List<Map<String, dynamic>>> getPendingParticipants(
    String eventId,
  ) async {
    try {
      final response = await _supabase
          .from('absen_event')
          .select('*, users(username, email, nim)')
          .eq('id_event', eventId)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting pending participants: $e');
      rethrow;
    }
  }

  /// Accept participant
  Future<void> acceptParticipant(String absenEventId) async {
    try {
      await _supabase
          .from('absen_event')
          .update({'status': 'diterima'})
          .eq('id_absen_event', absenEventId);

      print('✅ Participant accepted');
    } catch (e) {
      print('❌ Error accepting participant: $e');
      rethrow;
    }
  }

  /// Reject participant
  Future<void> rejectParticipant(String absenEventId, String reason) async {
    try {
      await _supabase
          .from('absen_event')
          .update({'status': 'ditolak', 'reject_reason': reason})
          .eq('id_absen_event', absenEventId);

      print('✅ Participant rejected');
    } catch (e) {
      print('❌ Error rejecting participant: $e');
      rethrow;
    }
  }
}
