import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

class UkmNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? senderType; // 'admin' or 'ukm'
  final String? senderName;
  final Map<String, dynamic>? metadata;

  UkmNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.senderType,
    this.senderName,
    this.metadata,
  });

  factory UkmNotification.fromJson(Map<String, dynamic> json) {
    return UkmNotification(
      id: json['id_notifikasi'] ?? json['id'] ?? '',
      title: json['judul'] ?? json['title'] ?? '',
      message: json['pesan'] ?? json['message'] ?? '',
      type: json['tipe'] ?? json['type'] ?? 'info',
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      senderType: json['sender_type'],
      senderName:
          json['sender_name'] ??
          json['admin']?['username'] ??
          json['ukm']?['nama_ukm'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_notifikasi': id,
      'judul': title,
      'pesan': message,
      'tipe': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'sender_type': senderType,
      'sender_name': senderName,
      'metadata': metadata,
    };
  }

  UkmNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? senderType,
    String? senderName,
    Map<String, dynamic>? metadata,
  }) {
    return UkmNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderType: senderType ?? this.senderType,
      senderName: senderName ?? this.senderName,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get relative time string
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
      case 'reminder':
        return 'Pengingat';
      default:
        return 'Notifikasi';
    }
  }
}

class UkmNotificationService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  List<UkmNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<UkmNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((notif) => !notif.isRead).length;

  /// Load notifications for UKM from database
  /// Gets notifications from Admin and global announcements
  Future<void> loadNotifications({String? ukmId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('========== LOAD UKM NOTIFICATIONS ==========');

      // Get current UKM ID if not provided
      String? targetUkmId = ukmId;
      if (targetUkmId == null) {
        final adminId = _authService.currentUserId;
        if (adminId == null) {
          _error = 'User not authenticated';
          _isLoading = false;
          notifyListeners();
          return;
        }

        // Get UKM ID from admin
        final ukmResponse = await _supabase
            .from('ukm')
            .select('id_ukm')
            .eq('id_admin', adminId)
            .maybeSingle();

        targetUkmId = ukmResponse?['id_ukm'];
      }

      print('Loading notifications for UKM: $targetUkmId');

      List<UkmNotification> allNotifications = [];

      // 1. Load UKM-specific notifications (sent to this UKM)
      if (targetUkmId != null) {
        try {
          final ukmNotifications = await _supabase
              .from('notifikasi_ukm')
              .select('*')
              .eq('id_ukm', targetUkmId)
              .order('created_at', ascending: false)
              .limit(50);

          print('Found ${ukmNotifications.length} UKM-specific notifications');

          for (var json in ukmNotifications) {
            allNotifications.add(
              UkmNotification.fromJson({...json, 'sender_type': 'admin'}),
            );
          }
        } catch (e) {
          print('Error loading UKM notifications: $e');
        }
      }

      // 2. Load global/broadcast notifications (from Admin to all UKMs)
      try {
        final globalNotifications = await _supabase
            .from('notifikasi_broadcast')
            .select('*')
            .order('created_at', ascending: false)
            .limit(50);

        print('Found ${globalNotifications.length} broadcast notifications');

        for (var json in globalNotifications) {
          allNotifications.add(
            UkmNotification.fromJson({
              ...json,
              'sender_type': 'admin',
              'sender_name': 'Admin',
            }),
          );
        }
      } catch (e) {
        print('Error loading broadcast notifications: $e');
      }

      // 3. Load notifications from notification_preference table with target_type = 'ukm'
      if (targetUkmId != null) {
        try {
          final targetNotifications = await _supabase
              .from('notification_preference')
              .select('*')
              .or('target_ukm.eq.$targetUkmId,target_type.eq.all_ukm')
              .order('create_at', ascending: false)
              .limit(50);

          print('Found ${targetNotifications.length} targeted notifications');

          for (var json in targetNotifications) {
            allNotifications.add(UkmNotification.fromJson(json));
          }
        } catch (e) {
          print('Error loading targeted notifications: $e');
        }
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

      // Don't load sample data - keep empty list
      _notifications = [];
      notifyListeners();
    }
  }

  /// Load sample notifications - DEPRECATED, not used in production
  @Deprecated('Use loadNotifications() instead')
  void _loadSampleNotifications() {
    // Empty - we don't want dummy data
    _notifications = [];
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // Update in database
      await _supabase
          .from('notifikasi_ukm')
          .update({'is_read': true})
          .eq('id_notifikasi', notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      // Update local state anyway
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final ukmId = await _getUkmId();
      if (ukmId != null) {
        await _supabase
            .from('notifikasi_ukm')
            .update({'is_read': true})
            .eq('id_ukm', ukmId)
            .eq('is_read', false);
      }

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
      await _supabase
          .from('notifikasi_ukm')
          .delete()
          .eq('id_notifikasi', notificationId);

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

  /// Create a new notification (for UKM to send)
  Future<bool> createNotification({
    required String title,
    required String message,
    required String type,
    String? targetUserId,
  }) async {
    try {
      final ukmId = await _getUkmId();
      if (ukmId == null) {
        throw Exception('UKM not found');
      }

      await _supabase.from('notification_preference').insert({
        'judul': title,
        'pesan': message,
        'type': type,
        'sender_ukm': ukmId,
        'target_user': targetUserId,
        'is_read': false,
        'create_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  /// Get current UKM ID
  Future<String?> _getUkmId() async {
    try {
      final adminId = _authService.currentUserId;
      if (adminId == null) return null;

      final response = await _supabase
          .from('ukm')
          .select('id_ukm')
          .eq('id_admin', adminId)
          .maybeSingle();

      return response?['id_ukm'];
    } catch (e) {
      return null;
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Clear all notifications (local only)
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
