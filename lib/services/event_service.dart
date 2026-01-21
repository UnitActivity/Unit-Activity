import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/models/event_model.dart';
import 'package:unit_activity/models/absen_event_model.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all events (without UUID filter)
  Future<List<EventModel>> getAllEvents() async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .order('tanggal_mulai', ascending: false);

      return (response as List)
          .map((json) => EventModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load events: $e');
    }
  }

  // Get all events for a specific UKM
  Future<List<EventModel>> getEventsByUkm(String idUkm) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('id_ukm', idUkm)
          .order('tanggal_mulai', ascending: false);

      return (response as List)
          .map((json) => EventModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load events: $e');
    }
  }

  // Get event by ID
  Future<EventModel?> getEventById(String idEvent) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('id_events', idEvent)
          .single();

      return EventModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load event: $e');
    }
  }

  // Create new event
  Future<EventModel> createEvent(EventModel event) async {
    try {
      final response = await _supabase
          .from('events')
          .insert(event.toJson())
          .select()
          .single();

      return EventModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Update event
  Future<EventModel> updateEvent(String idEvent, EventModel event) async {
    try {
      final response = await _supabase
          .from('events')
          .update(event.toJson())
          .eq('id_events', idEvent)
          .select()
          .single();

      return EventModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete event
  Future<void> deleteEvent(String idEvent) async {
    try {
      await _supabase
          .from('events')
          .delete()
          .eq('id_events', idEvent);
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Get attendance list for an event
  Future<List<AbsenEventModel>> getEventAttendance(String idEvent) async {
    try {
      final response = await _supabase
          .from('absen_event')
          .select()
          .eq('id_event', idEvent)
          .order('create_at', ascending: false);

      return (response as List)
          .map((json) => AbsenEventModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load attendance: $e');
    }
  }

  // Record attendance
  Future<AbsenEventModel> recordAttendance(AbsenEventModel attendance) async {
    try {
      final response = await _supabase
          .from('absen_event')
          .insert(attendance.toJson())
          .select()
          .single();

      return AbsenEventModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to record attendance: $e');
    }
  }

  // Check if user already attended
  Future<bool> hasUserAttended(String idUser, String idEvent) async {
    try {
      final response = await _supabase
          .from('absen_event')
          .select()
          .eq('id_user', idUser)
          .eq('id_event', idEvent);

      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check attendance: $e');
    }
  }

  // Update QR code for event
  Future<void> updateQRCode(String idEvent, String qrCode, String qrTime) async {
    try {
      await _supabase
          .from('events')
          .update({
            'qr_code': qrCode,
            'qr_time': qrTime,
          })
          .eq('id_events', idEvent);
    } catch (e) {
      throw Exception('Failed to update QR code: $e');
    }
  }
}
