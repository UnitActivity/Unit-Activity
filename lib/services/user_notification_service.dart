import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id_notifikasi'] ?? json['id'] ?? '',
      title: json['judul'] ?? json['title'] ?? '',
      message: json['pesan'] ?? json['message'] ?? '',
      type: json['tipe'] ?? json['type'] ?? 'info',
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      metadata: json['metadata'],
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
  }) {
    return UserNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
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

  List<UserNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<UserNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((notif) => !notif.isRead).length;

  /// Load notifications from Supabase
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Try to fetch from notifikasi table
      final response = await _supabase
          .from('notifikasi')
          .select()
          .eq('id_user', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      _notifications = (response as List)
          .map((json) => UserNotification.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
      _error = e.toString();
      _isLoading = false;

      // Load sample notifications if database fails
      _loadSampleNotifications();
      notifyListeners();
    }
  }

  /// Load sample notifications for development/testing
  void _loadSampleNotifications() {
    _notifications = [
      UserNotification(
        id: '1',
        title: 'Selamat Datang!',
        message: 'Selamat datang di Unit Activity',
        type: 'info',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      UserNotification(
        id: '2',
        title: 'Pertemuan UKM Baru',
        message: 'Ada pertemuan UKM baru minggu ini',
        type: 'event',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      UserNotification(
        id: '3',
        title: 'Informasi Terkini',
        message: 'Lihat informasi terbaru dari UKM',
        type: 'announcement',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Try to update in database
      await _supabase
          .from('notifikasi')
          .update({'is_read': true})
          .eq('id_notifikasi', notificationId)
          .eq('id_user', user.id);

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
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Try to update in database
      await _supabase
          .from('notifikasi')
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
          .from('notifikasi')
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
