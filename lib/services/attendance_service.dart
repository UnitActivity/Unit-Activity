import 'package:supabase_flutter/supabase_flutter.dart';
import 'dynamic_qr_service.dart';

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Record attendance for event via QR scan
  /// User must be registered in peserta_event before attendance can be recorded
  Future<Map<String, dynamic>> recordEventAttendance({
    required String eventId,
    required String qrCode,
  }) async {
    try {
      print('========== RECORD EVENT ATTENDANCE ==========');
      print('Event ID: $eventId');
      print('QR Code: $qrCode');

      final userId = currentUserId;
      if (userId == null) {
        return {
          'success': false,
          'message':
              'User tidak terautentikasi. Silakan login terlebih dahulu.',
        };
      }

      // Check if event exists
      final eventResponse = await _supabase
          .from('events')
          .select('id_events, nama_event, status, tanggal_mulai, tanggal_akhir')
          .eq('id_events', eventId)
          .maybeSingle();

      if (eventResponse == null) {
        return {'success': false, 'message': 'Event tidak ditemukan.'};
      }

      if (eventResponse['status'] == false) {
        return {'success': false, 'message': 'Event sudah tidak aktif.'};
      }

      // CRITICAL: Check if user is registered in peserta_event table first
      final registration = await _supabase
          .from('peserta_event')
          .select('id_peserta, status')
          .eq('id_event', eventId)
          .eq('id_user', userId)
          .maybeSingle();

      if (registration == null) {
        return {
          'success': false,
          'message':
              'Anda belum terdaftar di event "${eventResponse['nama_event']}".\n\nSilakan daftar terlebih dahulu melalui halaman Event.',
        };
      }

      // Check if already attended
      final existingAttendance = await _supabase
          .from('absen_event')
          .select('id_absen_e')
          .eq('id_event', eventId)
          .eq('id_user', userId)
          .maybeSingle();

      if (existingAttendance != null) {
        return {
          'success': false,
          'message':
              'Anda sudah tercatat hadir di event "${eventResponse['nama_event']}".',
        };
      }

      // Record attendance
      final now = DateTime.now();
      await _supabase.from('absen_event').insert({
        'id_event': eventId,
        'id_user': userId,
        'jam':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'status': 'hadir',
        'created_at': now.toIso8601String(),
      });

      print('✅ Attendance recorded successfully');

      return {
        'success': true,
        'message': 'Berhasil absen di event "${eventResponse['nama_event']}"!',
        'event_name': eventResponse['nama_event'],
        'event_id': eventId,
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      };
    } catch (e) {
      print('❌ Error recording event attendance: $e');
      return {
        'success': false,
        'message': 'Gagal mencatat kehadiran: ${e.toString()}',
      };
    }
  }

  /// Record attendance for pertemuan (meeting) via QR scan
  Future<Map<String, dynamic>> recordPertemuanAttendance({
    required String pertemuanId,
    required String qrCode,
  }) async {
    try {
      print('========== RECORD PERTEMUAN ATTENDANCE ==========');
      print('Pertemuan ID: $pertemuanId');
      print('QR Code: $qrCode');

      final userId = currentUserId;
      if (userId == null) {
        return {
          'success': false,
          'message':
              'User tidak terautentikasi. Silakan login terlebih dahulu.',
        };
      }

      // Check if pertemuan exists
      final pertemuanResponse = await _supabase
          .from('pertemuan')
          .select('id_pertemuan, topik, id_ukm, tanggal')
          .eq('id_pertemuan', pertemuanId)
          .maybeSingle();

      if (pertemuanResponse == null) {
        return {'success': false, 'message': 'Pertemuan tidak ditemukan.'};
      }

      // Check if user is member of the UKM
      final ukmId = pertemuanResponse['id_ukm'];
      final isMember = await _isUserMemberOfUkm(userId, ukmId);

      if (!isMember) {
        return {
          'success': false,
          'message':
              'Anda bukan anggota UKM ini. Hanya anggota yang dapat absen.',
        };
      }

      // Check if already attended
      final existingAttendance = await _supabase
          .from('absen_pertemuan')
          .select('id_absen_p')
          .eq('id_pertemuan', pertemuanId)
          .eq('id_user', userId)
          .maybeSingle();

      if (existingAttendance != null) {
        return {
          'success': false,
          'message':
              'Anda sudah tercatat hadir di pertemuan "${pertemuanResponse['topik']}".',
        };
      }

      // Record attendance
      final now = DateTime.now();
      await _supabase.from('absen_pertemuan').insert({
        'id_pertemuan': pertemuanId,
        'id_user': userId,
        'jam':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'status': 'hadir',
        'created_at': now.toIso8601String(),
      });

      print('✅ Pertemuan attendance recorded successfully');

      return {
        'success': true,
        'message':
            'Berhasil absen di pertemuan "${pertemuanResponse['topik']}"!',
        'pertemuan_name': pertemuanResponse['topik'],
        'pertemuan_id': pertemuanId,
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      };
    } catch (e) {
      print('❌ Error recording pertemuan attendance: $e');
      return {
        'success': false,
        'message': 'Gagal mencatat kehadiran: ${e.toString()}',
      };
    }
  }

  /// Process QR code and record attendance (auto-detect event or pertemuan)
  Future<Map<String, dynamic>> processQRCodeAttendance(String qrCode) async {
    try {
      print('========== PROCESS QR CODE ==========');
      print('QR Code: $qrCode');

      // Validate dynamic QR code first
      final validation = DynamicQRService.validateDynamicQR(qrCode);

      if (validation['valid'] != true) {
        final errorType = validation['error_type'];
        String message = validation['message'] ?? 'QR Code tidak valid.';

        // Custom messages based on error type
        if (errorType == 'EXPIRED') {
          final expiredSeconds = validation['expired_seconds_ago'] ?? 0;
          message =
              'QR Code sudah kadaluarsa $expiredSeconds detik yang lalu.\n\nSilakan scan QR Code yang baru.';
        } else if (errorType == 'INVALID_SIGNATURE') {
          message =
              'QR Code tidak valid atau telah dimodifikasi.\n\nPastikan Anda menscan QR Code yang benar.';
        } else if (errorType == 'INVALID_FORMAT') {
          message =
              'Format QR Code tidak sesuai.\n\nPastikan Anda menscan QR Code untuk absensi.';
        }

        return {'success': false, 'message': message, 'error_type': errorType};
      }

      // QR code is valid, extract data
      final type = validation['type'] as String;
      final id = validation['id'] as String;
      final ageSeconds = validation['age_seconds'] as int;

      print('✅ QR Code valid - Type: $type, ID: $id, Age: ${ageSeconds}s');

      // Process based on type
      if (type.toUpperCase().contains('EVENT')) {
        return await recordEventAttendance(eventId: id, qrCode: qrCode);
      } else if (type.toUpperCase().contains('PERTEMUAN') ||
          type.toUpperCase().contains('MEETING')) {
        return await recordPertemuanAttendance(pertemuanId: id, qrCode: qrCode);
      } else {
        // Try to auto-detect
        return await _autoDetectAndRecordAttendance(qrCode, id);
      }
    } catch (e) {
      print('❌ Error processing QR code: $e');
      return {
        'success': false,
        'message': 'Gagal memproses QR Code: ${e.toString()}',
      };
    }
  }

  /// Auto-detect attendance type and record
  Future<Map<String, dynamic>> _autoDetectAndRecordAttendance(
    String qrCode,
    String id,
  ) async {
    // Try event first
    final eventResponse = await _supabase
        .from('events')
        .select('id_events')
        .eq('id_events', id)
        .maybeSingle();

    if (eventResponse != null) {
      return await recordEventAttendance(eventId: id, qrCode: qrCode);
    }

    // Try pertemuan
    final pertemuanResponse = await _supabase
        .from('pertemuan')
        .select('id_pertemuan')
        .eq('id_pertemuan', id)
        .maybeSingle();

    if (pertemuanResponse != null) {
      return await recordPertemuanAttendance(pertemuanId: id, qrCode: qrCode);
    }

    return {
      'success': false,
      'message':
          'QR Code tidak terkait dengan event atau pertemuan yang valid.',
    };
  }

  /// Check if user is member of UKM (active status only)
  Future<bool> _isUserMemberOfUkm(String userId, String ukmId) async {
    try {
      // Check for both 'aktif' and 'active' status values
      final response = await _supabase
          .from('user_halaman_ukm')
          .select('id_user')
          .eq('id_user', userId)
          .eq('id_ukm', ukmId)
          .or('status.eq.aktif,status.eq.active')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking UKM membership: $e');
      return false;
    }
  }

  /// Get user's attendance history
  Future<List<Map<String, dynamic>>> getUserAttendanceHistory() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      List<Map<String, dynamic>> history = [];

      // Get event attendance
      final eventAttendance = await _supabase
          .from('absen_event')
          .select('''
            id_absen_e,
            jam,
            status,
            created_at,
            events(id_events, nama_event, lokasi, tanggal_mulai)
          ''')
          .eq('id_user', userId)
          .order('created_at', ascending: false);

      for (var item in eventAttendance) {
        history.add({
          'type': 'event',
          'id': item['id_absen_e'],
          'name': item['events']?['nama_event'] ?? 'Event',
          'location': item['events']?['lokasi'],
          'date': item['events']?['tanggal_mulai'],
          'time': item['jam'],
          'status': item['status'],
          'recorded_at': item['created_at'],
        });
      }

      // Get pertemuan attendance
      final pertemuanAttendance = await _supabase
          .from('absen_pertemuan')
          .select('''
            id_absen_p,
            jam,
            status,
            created_at,
            pertemuan(id_pertemuan, topik, lokasi, tanggal)
          ''')
          .eq('id_user', userId)
          .order('created_at', ascending: false);

      for (var item in pertemuanAttendance) {
        history.add({
          'type': 'pertemuan',
          'id': item['id_absen_p'],
          'name': item['pertemuan']?['topik'] ?? 'Pertemuan',
          'location': item['pertemuan']?['lokasi'],
          'date': item['pertemuan']?['tanggal'],
          'time': item['jam'],
          'status': item['status'],
          'recorded_at': item['created_at'],
        });
      }

      // Sort by recorded_at descending
      history.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['recorded_at'] ?? '') ?? DateTime.now();
        final dateB =
            DateTime.tryParse(b['recorded_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      return history;
    } catch (e) {
      print('Error loading attendance history: $e');
      return [];
    }
  }
}
