// Push Notification Service - Stubbed (Firebase Removed)
// This service has been disabled as Firebase dependencies were removed for Windows build support.
// If push notifications are needed in the future, consider using:
// - Supabase Realtime for real-time updates
// - flutter_local_notifications for local notifications
// - Platform-specific solutions for mobile

import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize push notifications (stubbed - no Firebase)
  Future<void> initialize() async {
    print('⚠️ Push notifications disabled (Firebase removed)');
    // No-op: Firebase has been removed
  }

  /// Subscribe to admin notifications (stubbed)
  Future<void> subscribeToAdminNotifications() async {
    print('⚠️ Admin notifications disabled (Firebase removed)');
    // No-op: Firebase has been removed
  }

  /// Update user association (stubbed)
  Future<void> updateUserAssociation(String userId) async {
    print('⚠️ User notification association disabled (Firebase removed)');
    // No-op: Firebase has been removed
  }

  /// Unsubscribe from admin notifications (stubbed)
  Future<void> unsubscribeFromAdminNotifications() async {
    // No-op: Firebase has been removed
  }

  /// Clear user association (stubbed)
  Future<void> clearUserAssociation() async {
    // No-op: Firebase has been removed
  }
}

// Background message handler stub (no longer used)
// Firebase has been removed - this function is kept for compatibility but does nothing
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  print('⚠️ Background message handler called but Firebase is disabled');
  // No-op: Firebase has been removed
}
