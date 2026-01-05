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

  List<UserNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<UserNotification> get notifications => _notifications;

  /// Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;
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

      // 1. Load user-specific notifications (direct to this user)
      try {
        final userNotifications = await _supabase
            .from('notifikasi')
            .select('*')
            .eq('id_user', userId)
            .order('created_at', ascending: false)
            .limit(50);

        print('Found ${userNotifications.length} user-specific notifications');

        for (var json in userNotifications) {
          allNotifications.add(
            UserNotification.fromJson({
              ...json,
              'sender': 'Sistem', // Default sender for direct notifications
            }),
          );
        }
      } catch (e) {
        print('Error loading user notifications: $e');
      }

      // 2. Load broadcast notifications (from Admin to all users)
      try {
        final broadcastNotifications = await _supabase
            .from('notifikasi_broadcast')
            .select('*')
            .order('created_at', ascending: false)
            .limit(30);

        print('Found ${broadcastNotifications.length} broadcast notifications');

        for (var json in broadcastNotifications) {
          allNotifications.add(
            UserNotification.fromJson({
              ...json,
              'type': json['tipe'] ?? 'announcement',
              'sender': 'Admin', // Broadcast notifications are from Admin
            }),
          );
        }
      } catch (e) {
        print('Error loading broadcast notifications: $e');
      }

      // 3. Load notifications from UKMs that user has joined
      try {
        // Get user's joined UKMs
        final userUkms = await _supabase
            .from('user_halaman_ukm')
            .select('id_ukm')
            .eq('id_user', userId);

        if (userUkms.isNotEmpty) {
          final ukmIds = (userUkms as List).map((e) => e['id_ukm']).toList();

          // Get notifications from those UKMs
          final ukmNotifications = await _supabase
              .from('notifikasi_ukm_member')
              .select('*, ukm(nama_ukm)')
              .inFilter('id_ukm', ukmIds)
              .order('created_at', ascending: false)
              .limit(30);

          print('Found ${ukmNotifications.length} UKM notifications');

          for (var json in ukmNotifications) {
            final ukmName = json['ukm']?['nama_ukm'] ?? 'UKM';
            allNotifications.add(
              UserNotification.fromJson({
                ...json,
                'type': json['tipe'] ?? 'info',
                'sender': ukmName, // Use UKM name as sender
                'metadata': {'sender_type': 'ukm', 'sender_name': ukmName},
              }),
            );
          }
        }
      } catch (e) {
        print('Error loading UKM notifications: $e');
      }

      // 4. Load event-related notifications
      try {
        final eventNotifications = await _supabase
            .from('notifikasi')
            .select('*')
            .eq('target_type', 'all_users')
            .order('created_at', ascending: false)
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
        message:
            'Selamat datang di Unit Activity. Jelajahi berbagai UKM dan event menarik yang tersedia.',
        type: 'info',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        metadata: {'sender_type': 'admin', 'sender_name': 'Admin'},
        sender: 'Admin',
      ),
      UserNotification(
        id: '2',
        title: 'Pertemuan UKM Minggu Ini',
        message:
            'Jangan lupa hadir di pertemuan UKM E-Sport hari Jumat pukul 16.00 di Ruang Multimedia.',
        type: 'event',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        metadata: {'sender_type': 'ukm', 'sender_name': 'UKM E-Sport'},
        sender: 'UKM E-Sport',
      ),
      UserNotification(
        id: '3',
        title: 'Pendaftaran Event Dibuka',
        message:
            'Pendaftaran event Sparing Badminton telah dibuka. Segera daftar sebelum kuota penuh!',
        type: 'announcement',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        metadata: {'sender_type': 'ukm', 'sender_name': 'UKM Badminton'},
        sender: 'UKM Badminton',
      ),
      UserNotification(
        id: '4',
        title: 'Pengumuman Penting',
        message:
            'Perhatian untuk seluruh anggota UKM. Harap lengkapi data profil Anda paling lambat akhir bulan ini.',
        type: 'announcement',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        metadata: {'sender_type': 'admin', 'sender_name': 'Admin'},
        sender: 'Admin',
      ),
      UserNotification(
        id: '5',
        title: 'Absensi Berhasil Tercatat',
        message:
            'Kehadiran Anda di pertemuan UKM Basket tanggal 15 Januari telah tercatat dalam sistem.',
        type: 'success',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        metadata: {'sender_type': 'system'},
        sender: 'Sistem',
      ),
      UserNotification(
        id: '6',
        title: 'Event Baru dari UKM Musik',
        message:
            'UKM Musik akan mengadakan konser mini di aula kampus. Yuk daftar sekarang!',
        type: 'event',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        metadata: {'sender_type': 'ukm', 'sender_name': 'UKM Musik'},
        sender: 'UKM Musik',
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
