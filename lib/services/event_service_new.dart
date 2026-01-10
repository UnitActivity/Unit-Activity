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
    String? tipeAkses,
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

      // Note: gambar column needs to be added to database first
      // if (gambar != null) {
      //   eventData['gambar'] = gambar;
      // }
      // Note: tipe_akses column needs to be added to database first
      // if (tipeAkses != null) {
      //   eventData['tipe_akses'] = tipeAkses;
      // }

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
    String? gambar,
    String? tipeAkses,
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
      // Note: gambar column needs to be added to database first
      // if (gambar != null) updates['gambar'] = gambar;
      // Note: tipe_akses column needs to be added to database first
      // if (tipeAkses != null) updates['tipe_akses'] = tipeAkses;

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

      final now = DateTime.now();
      final qrCode = '${eventId}_${now.millisecondsSinceEpoch}';
      // Format time as HH:mm:ss.SSS for PostgreSQL time type
      final qrTimeForDb =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';

      await _supabase
          .from('events')
          .update({'qr_code': qrCode, 'qr_time': qrTimeForDb})
          .eq('id_events', eventId);

      print('✅ QR Code generated: $qrCode');
      return {
        'qr_code': qrCode,
        'qr_time': now.toIso8601String(),
        'expires_at': now.add(const Duration(seconds: 10)).toIso8601String(),
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
      // qr_time is stored as time (HH:mm:ss.SSS), we need to parse it differently
      final now = DateTime.now();
      final qrTimeStr = event['qr_time'] as String;
      final timeParts = qrTimeStr.split(':');
      final secondParts = timeParts[2].split('.');

      final qrTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(secondParts[0]),
        secondParts.length > 1
            ? int.parse(secondParts[1].padRight(3, '0').substring(0, 3))
            : 0,
      );

      final difference = now.difference(qrTime).inSeconds;

      if (difference > 10 || difference < 0) {
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
