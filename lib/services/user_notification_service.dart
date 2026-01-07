import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

class UserNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final String sender; // Admin, UKM name, or Sistem

  UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.metadata,
    this.sender = 'Sistem',
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    // Extract sender from metadata or direct field
    String senderName = 'Sistem';
    if (json['sender'] != null) {
      senderName = json['sender'];
    } else if (json['pengirim'] != null) {
      senderName = json['pengirim'];
    } else if (json['metadata'] != null) {
      final metadata = json['metadata'] as Map<String, dynamic>?;
      if (metadata != null) {
        if (metadata['sender_name'] != null) {
          senderName = metadata['sender_name'];
        } else if (metadata['sender_type'] == 'admin') {
          senderName = 'Admin';
        } else if (metadata['sender_type'] == 'ukm') {
          senderName = metadata['ukm_name'] ?? 'UKM';
        }
      }
    }

    // Parse the ID from various possible fields
    String notifId = '';
    if (json['id_notifikasi'] != null) {
      notifId = json['id_notifikasi'].toString();
    } else if (json['id_notifikasi_ukm_member'] != null) {
      notifId = json['id_notifikasi_ukm_member'].toString();
    } else if (json['id_broadcast'] != null) {
      notifId = json['id_broadcast'].toString();
    } else if (json['id'] != null) {
      notifId = json['id'].toString();
    }

    return UserNotification(
      id: notifId,
      title: json['judul'] ?? json['title'] ?? '',
      message: json['pesan'] ?? json['message'] ?? '',
      type: json['tipe'] ?? json['type'] ?? 'info',
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['create_at'] != null
                ? DateTime.parse(json['create_at'])
                : DateTime.now()),
      metadata: json['metadata'],
      sender: senderName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
      'sender': sender,
    };
  }

  UserNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    String? sender,
  }) {
    return UserNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      sender: sender ?? this.sender,
    );
  }

  // Get relative time string (e.g., "2 jam lalu", "1 hari lalu")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    }
  }

  // Get readable type name
  String get typeName {
    switch (type.toLowerCase()) {
      case 'event':
        return 'Event';
      case 'announcement':
        return 'Pengumuman';
      case 'info':
        return 'Informasi';
      case 'warning':
        return 'Peringatan';
      case 'success':
        return 'Berhasil';
      default:
        return 'Notifikasi';
    }
  }
}

class UserNotificationService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  List<UserNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<UserNotification> get notifications => _notifications;

  /// Get current user ID from custom auth service
  String? get currentUserId => _authService.currentUserId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((notif) => !notif.isRead).length;

  /// Load notifications from Supabase
  /// Gets notifications from Admin, UKM, and broadcast notifications
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = currentUserId;
      if (userId == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('========== LOAD USER NOTIFICATIONS ==========');
      print('User ID: $userId');

      List<UserNotification> allNotifications = [];

      // 1. Load user-specific notifications from notification_preference
      try {
        print('Fetching from notification_preference...');
        final userNotifications = await _supabase
            .from('notification_preference')
            .select('*')
            .eq('id_user', userId)
            .order('create_at', ascending: false)
            .limit(50);

        print('Found ${userNotifications.length} user-specific notifications');

        // Debug: Print first notification details
        if (userNotifications.isNotEmpty) {
          print('Sample notification_preference record:');
          print('  - ID: ${userNotifications[0]['id_notification_pref']}');
          print('  - Judul: ${userNotifications[0]['judul']}');
          print('  - Type: ${userNotifications[0]['type']}');
          print('  - Is Read: ${userNotifications[0]['is_read']}');
        }

        for (var json in userNotifications) {
          // Determine sender based on type and linked IDs
          String senderName = 'Admin';
          if (json['id_ukm'] != null) {
            senderName = 'UKM';
          } else if (json['type'] == 'event') {
            senderName = 'Event';
          }

          allNotifications.add(
            UserNotification(
              id:
                  json['id_notification_pref']?.toString() ??
                  json['id']?.toString() ??
                  '',
              title: json['judul'] ?? 'Notifikasi',
              message: json['pesan'] ?? '',
              type: json['type'] ?? 'info',
              isRead: json['is_read'] ?? false,
              createdAt: json['create_at'] != null
                  ? DateTime.parse(json['create_at'])
                  : DateTime.now(),
              metadata: {
                'id_events': json['id_events'],
                'id_pertemuan': json['id_pertemuan'],
                'id_informasi': json['id_informasi'],
                'id_ukm': json['id_ukm'],
              },
              sender: senderName,
            ),
          );
        }
      } catch (e) {
        print('Error loading user notifications: $e');
        print('Stack trace: ${StackTrace.current}');
      }

      // 2. Load broadcast notifications (from Admin to all users)
      try {
        final broadcastNotifications = await _supabase
            .from('notifikasi_broadcast')
            .select('*')
            .eq('status_aktif', true)
            .order('created_at', ascending: false)
            .limit(30);

        print(
          'Found ${broadcastNotifications.length} broadcast notifications from Admin',
        );

        for (var json in broadcastNotifications) {
          allNotifications.add(
            UserNotification.fromJson({
              ...json,
              'id':
                  json['id_broadcast'] ??
                  json['id_notifikasi_broadcast'] ??
                  json['id'],
              'type': json['tipe'] ?? 'announcement',
              'sender':
                  json['pengirim'] ??
                  'Admin', // Broadcast notifications are from Admin
            }),
          );
        }
      } catch (e) {
        print('Error loading broadcast notifications: $e');
        print('Broadcast error details: ${e.toString()}');
      }

      // 3. Load notifications from UKMs that user has joined
      try {
        // Get user's joined UKMs (accept both 'aktif' and 'active')
        final userUkms = await _supabase
            .from('user_halaman_ukm')
            .select('id_ukm')
            .eq('id_user', userId)
            .or('status.eq.aktif,status.eq.active');

        print('User is in ${userUkms.length} UKMs');

        if (userUkms.isNotEmpty) {
          final ukmIds = (userUkms as List).map((e) => e['id_ukm']).toList();
          print('UKM IDs: $ukmIds');

          // Get notifications from those UKMs - try with and without join
          try {
            final ukmNotifications = await _supabase
                .from('notifikasi_ukm_member')
                .select('*, ukm!inner(nama_ukm)')
                .inFilter('id_ukm', ukmIds)
                .order('created_at', ascending: false)
                .limit(30);

            print('Found ${ukmNotifications.length} UKM notifications');

            for (var json in ukmNotifications) {
              final ukmName =
                  json['ukm']?['nama_ukm'] ?? json['pengirim'] ?? 'UKM';
              allNotifications.add(
                UserNotification.fromJson({
                  ...json,
                  'id': json['id_notifikasi_ukm_member'] ?? json['id'],
                  'type': json['tipe'] ?? 'info',
                  'sender': ukmName,
                  'metadata': {'sender_type': 'ukm', 'sender_name': ukmName},
                }),
              );
            }
          } catch (joinError) {
            print('Error with join query, trying without join: $joinError');

            // Fallback: query without join
            final ukmNotifications = await _supabase
                .from('notifikasi_ukm_member')
                .select('*')
                .inFilter('id_ukm', ukmIds)
                .order('created_at', ascending: false)
                .limit(30);

            print(
              'Found ${ukmNotifications.length} UKM notifications (without join)',
            );

            for (var json in ukmNotifications) {
              final ukmName = json['pengirim'] ?? 'UKM';
              allNotifications.add(
                UserNotification.fromJson({
                  ...json,
                  'id': json['id_notifikasi_ukm_member'] ?? json['id'],
                  'type': json['tipe'] ?? 'info',
                  'sender': ukmName,
                  'metadata': {'sender_type': 'ukm', 'sender_name': ukmName},
                }),
              );
            }
          }
        }
      } catch (e) {
        print('Error loading UKM notifications: $e');
        print('Stack trace: $e');
      }

      // 4. Load event-related notifications
      try {
        final eventNotifications = await _supabase
            .from('notification_preference')
            .select('*')
            .eq('target_type', 'all_users')
            .order('create_at', ascending: false)
            .limit(20);

        print('Found ${eventNotifications.length} event notifications');

        for (var json in eventNotifications) {
          // Avoid duplicates
          if (!allNotifications.any((n) => n.id == json['id_notifikasi'])) {
            allNotifications.add(
              UserNotification.fromJson({
                ...json,
                'sender': 'Admin', // All-user notifications are from Admin
              }),
            );
          }
        }
      } catch (e) {
        print('Error loading event notifications: $e');
      }

      // Sort all notifications by created_at descending
      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Remove duplicates based on id
      final seen = <String>{};
      allNotifications = allNotifications.where((notif) {
        if (seen.contains(notif.id)) return false;
        seen.add(notif.id);
        return true;
      }).toList();

      _notifications = allNotifications;
      _isLoading = false;

      print('Total notifications loaded: ${_notifications.length}');
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
      print('Stack trace: ${StackTrace.current}');
      _error = e.toString();
      _isLoading = false;

      // Don't load sample data - keep empty list to show no notifications
      _notifications = [];
      notifyListeners();
    }
  }

  /// Load sample notifications for development/testing - NOT USED IN PRODUCTION
  @Deprecated('Use loadNotifications() instead - sample data removed')
  void _loadSampleNotifications() {
    // Empty - we don't want dummy data
    _notifications = [];
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Update local state first for instant feedback
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }

      // Try to update in database - try multiple tables
      try {
        // Try notification_preference table (user-specific notifications)
        await _supabase
            .from('notification_preference')
            .update({'is_read': true})
            .eq('id_notifikasi', notificationId)
            .eq('id_user', user.id);
      } catch (e) {
        print('Not in notification_preference table: $e');
      }

      // Note: Broadcast and UKM member notifications don't track read status per user
      // They are marked as read only in local state
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Try to update in database
      await _supabase
          .from('notification_preference')
          .update({'is_read': true})
          .eq('id_user', user.id)
          .eq('is_read', false);

      // Update local state
      _notifications = _notifications
          .map((notif) => notif.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      // Update local state anyway
      _notifications = _notifications
          .map((notif) => notif.copyWith(isRead: true))
          .toList();
      notifyListeners();
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Try to delete from database
      await _supabase
          .from('notification_preference')
          .delete()
          .eq('id_notifikasi', notificationId)
          .eq('id_user', user.id);

      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
      // Remove from local state anyway
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
