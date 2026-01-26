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
    } else if (json['id_notification_pref'] != null) {
      notifId = json['id_notification_pref'].toString();
    }

    return UserNotification(
      id: notifId,
      title: json['judul'] ?? json['title'] ?? '',
      message: json['pesan'] ?? json['message'] ?? '',
      type: json['tipe'] ?? json['type'] ?? 'info',
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: json['create_at'] != null
          ? DateTime.parse(json['create_at'])
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

  int _currentPage = 0;
  final int _pageSize = 15;
  bool _hasMore = true;

  List<UserNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<UserNotification> get notifications => _notifications;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get unreadCount => _unreadCount;
  
  /// Get current user ID from custom auth service
  String? get currentUserId => _authService.currentUserId;

  /// Compatibility wrapper for older code calling loadNotifications
  /// If refresh is true, it loads page 0.
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      await loadPage(0);
    } else {
      // If called without refresh (e.g. initial load), load page 0 if empty
      if (_notifications.isEmpty) {
        await loadPage(0);
      }
    }
  }

  /// Fetch separate unread count for badge
  Future<void> fetchUnreadCount() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final count = await _supabase
          .from('notification_preference')
          .count(CountOption.exact)
          .eq('id_user', userId)
          .eq('is_read', false);
      
      _unreadCount = count;
      notifyListeners();
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  /// Load notifications for a specific page (0-indexed)
  Future<void> loadPage(int page) async {
    if (_isLoading) return;
    
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

      final int from = page * _pageSize;
      final int to = from + _pageSize - 1;

      print('========== LOAD USER NOTIFICATIONS (Page $page) ==========');
      print('Range: $from - $to');

      // 1. Fetch from notification_preference
      final userNotifications = await _supabase
          .from('notification_preference')
          .select('*')
          .eq('id_user', userId)
          .order('create_at', ascending: false)
          .range(from, to);

      List<UserNotification> batchNotifications = [];

      for (var json in userNotifications) {
          String senderName = 'Admin';
          if (json['id_ukm'] != null) {
            senderName = 'UKM';
          } else if (json['type'] == 'event') {
            senderName = 'Event';
          }

          batchNotifications.add(
            UserNotification(
              id: json['id_notification_pref']?.toString() ?? json['id']?.toString() ?? '',
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

      // Replace notifications list (Don't append)
      _notifications = batchNotifications;
      _currentPage = page;
      _hasMore = batchNotifications.length >= _pageSize;
      
      // Update unread count separately
      await fetchUnreadCount();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Next page
  Future<void> nextPage() async {
    if (!_hasMore) return;
    await loadPage(_currentPage + 1);
  }

  /// Previous page
  Future<void> prevPage() async {
    if (_currentPage > 0) {
      await loadPage(_currentPage - 1);
    }
  }

  /// Reload current page
  Future<void> refresh() async {
    await loadPage(_currentPage);
    await fetchUnreadCount();
  }

  /// Mark single as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;
      
      // Update local first
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }

      await _supabase
          .from('notification_preference')
          .update({'is_read': true})
          .eq('id_notification_pref', notificationId);

      await fetchUnreadCount();
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      // 1. Update DB
      await _supabase
          .from('notification_preference')
          .update({'is_read': true})
          .eq('id_user', userId)
          .eq('is_read', false);

      // 2. Update local state
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      
      notifyListeners();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      await _supabase
          .from('notification_preference')
          .delete()
          .eq('id_notification_pref', notificationId)
          .eq('id_user', userId);

      _notifications.removeWhere((n) => n.id == notificationId);
      await fetchUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
  
  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }
}
