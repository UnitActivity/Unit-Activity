import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/notification_service.dart';

class UserPageWrapper extends StatefulWidget {
  final Widget child;
  final String pageName;

  const UserPageWrapper({required this.child, required this.pageName, Key? key})
    : super(key: key);

  @override
  State<UserPageWrapper> createState() => _UserPageWrapperState();
}

class _UserPageWrapperState extends State<UserPageWrapper> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late NotificationService _notificationService;
  RealtimeChannel? _notifChannel;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _notifChannel?.unsubscribe();
    super.dispose();
  }

  void _setupNotificationListener() {
    try {
      _notifChannel = _supabase
          .channel('public:event_notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'event_notifications',
            callback: (payload) {
              _handleNotification(payload);
            },
          )
          .subscribe();
    } catch (e) {
      print('Error setting up notification listener: $e');
    }
  }

  void _handleNotification(PostgresChangePayload payload) {
    final data = payload.newRecord;

    if (data['status'] == 'sent' && mounted) {
      _notificationService.showNotificationPopup(
        context,
        title: data['event_title'] ?? 'Ada Kegiatan Baru',
        subtitle:
            data['event_description'] ?? 'Perhatikan jadwal kegiatan terbaru',
        ukmName: data['ukm_name'] ?? 'UKM',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
