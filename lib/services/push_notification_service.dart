import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Check if current platform supports Firebase Messaging (mobile only)
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (e) {
    return false;
  }
}

/// Service untuk handle push notifications menggunakan Firebase Cloud Messaging
/// Notifikasi akan tetap berfungsi meskipun user logout
/// NOTE: Push notifications only work on mobile platforms (Android/iOS)
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // Only initialize Firebase Messaging on supported platforms
  FirebaseMessaging? get _firebaseMessaging =>
      _isMobilePlatform ? FirebaseMessaging.instance : null;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;

  /// Initialize push notification service
  Future<void> initialize() async {
    // Skip initialization on non-mobile platforms (Windows, macOS, Linux, Web)
    if (!_isMobilePlatform) {
      print(
        '⚠️ Push notifications not supported on this platform, skipping...',
      );
      return;
    }

    if (_isInitialized) return;

    try {
      print('========== INITIALIZING PUSH NOTIFICATIONS ==========');

      // Request permission for iOS
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      // Save token to device storage (persists after logout)
      await _saveTokenToLocalStorage();

      // Register token with backend (if user is logged in)
      await _registerTokenWithBackend();

      _isInitialized = true;
      print('✅ Push notifications initialized successfully');
    } catch (e) {
      print('❌ Error initializing push notifications: $e');
    }
  }

  /// Request notification permission (iOS)
  Future<void> _requestPermission() async {
    if (_firebaseMessaging == null) return;

    final settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications (for foreground notifications)
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'ukm_notifications',
      'UKM Notifications',
      description: 'Notifications for UKM activities and events',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    if (_firebaseMessaging == null) return;

    try {
      _fcmToken = await _firebaseMessaging!.getToken();
      print('FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        _saveTokenToLocalStorage();
        _registerTokenWithBackend();
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  /// Save token to local storage (persists after logout)
  Future<void> _saveTokenToLocalStorage() async {
    if (_fcmToken == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', _fcmToken!);
      await prefs.setString(
        'fcm_token_saved_at',
        DateTime.now().toIso8601String(),
      );
      print('FCM token saved to local storage');
    } catch (e) {
      print('Error saving FCM token to local storage: $e');
    }
  }

  /// Register token with backend (if user is logged in)
  Future<void> _registerTokenWithBackend() async {
    if (_fcmToken == null) return;

    try {
      final userId = _supabase.auth.currentUser?.id;

      // Save to device_tokens table (can be without user_id for anonymous notifications)
      await _supabase.from('device_tokens').upsert({
        'token': _fcmToken,
        'id_user': userId, // Can be null for logged out users
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');

      print('FCM token registered with backend');
    } catch (e) {
      print('Error registering token with backend: $e');
      // Don't throw, token is still saved locally
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    if (_firebaseMessaging == null) return;

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is opened from terminated state
    _firebaseMessaging!.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessage(message);
      }
    });
  }

  /// Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('========== FOREGROUND MESSAGE ==========');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Save notification to database
    await _saveNotificationToDatabase(message);

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle background message
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('========== BACKGROUND MESSAGE ==========');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Save notification to database (important for offline notifications)
    await _saveNotificationToDatabase(message);

    // Handle navigation based on notification data
    final data = message.data;
    if (data.containsKey('screen')) {
      // Navigate to specific screen
      // This will be handled by the app's navigation system
    }
  }

  /// Save notification to database so it's available even when app is closed
  Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final userId = _supabase.auth.currentUser?.id;

      // If no user is logged in, save to anonymous notifications
      // This ensures notifications are never lost

      final notificationData = {
        'judul': notification.title ?? 'Notifikasi',
        'pesan': notification.body ?? '',
        'type': message.data['type'] ?? 'info',
        'is_read': false,
        'create_at': DateTime.now().toIso8601String(),
      };

      if (userId != null) {
        // Save to user-specific notifications
        await _supabase.from('notification_preference').insert({
          ...notificationData,
          'id_user': userId,
        });
        print('✅ Notification saved to database for user: $userId');
      } else {
        // Anonymous notifications not supported without proper table
        print('ℹ️ No user logged in, notification not saved to database');
      }
    } catch (e) {
      print('❌ Error saving notification to database: $e');
      // Don't throw - notification should still be shown
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'ukm_notifications',
      'UKM Notifications',
      channelDescription: 'Notifications for UKM activities and events',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Subscribe to topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    if (_firebaseMessaging == null) return;

    try {
      await _firebaseMessaging!.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_firebaseMessaging == null) return;

    try {
      await _firebaseMessaging!.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe to UKM notifications
  Future<void> subscribeToUkmNotifications(String ukmId) async {
    await subscribeToTopic('ukm_$ukmId');
  }

  /// Unsubscribe from UKM notifications
  Future<void> unsubscribeFromUkmNotifications(String ukmId) async {
    await unsubscribeFromTopic('ukm_$ukmId');
  }

  /// Subscribe to all users notifications (from admin)
  Future<void> subscribeToAdminNotifications() async {
    await subscribeToTopic('all_users');
  }

  /// Update user association when login
  Future<void> updateUserAssociation(String userId) async {
    if (_fcmToken == null) return;

    try {
      await _supabase.from('device_tokens').upsert({
        'token': _fcmToken,
        'id_user': userId,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');

      print('User association updated for FCM token');
    } catch (e) {
      print('Error updating user association: $e');
    }
  }

  /// Clear user association when logout (but keep token for anonymous notifications)
  Future<void> clearUserAssociation() async {
    if (_fcmToken == null) return;

    try {
      // Don't delete the token, just clear user association
      // This allows device to still receive broadcast notifications after logout
      await _supabase
          .from('device_tokens')
          .update({
            'id_user': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('token', _fcmToken!);

      print(
        'User association cleared (token preserved for anonymous notifications)',
      );
    } catch (e) {
      print('Error clearing user association: $e');
    }
  }

  /// Send test notification (for development)
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: 'Test Notification',
          body: 'This is a test notification from UKM app',
        ),
        data: {'test': 'true'},
      ),
    );
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('========== BACKGROUND MESSAGE (TERMINATED) ==========');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}
