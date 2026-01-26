// Push Notification Service - Stubbed
// This service has been disabled as dependencies were removed for Windows build support.
// If push notifications are needed in the future, consider using:
// - Supabase Realtime for real-time updates
// - flutter_local_notifications for local notifications
// - Platform-specific solutions for mobile

import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  // Client kept for potential future use or compilation compatibility if accessed
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize push notifications (stubbed)
  Future<void> initialize() async {
    print('⚠️ Push notifications disabled (Dependency removed)');
    // No-op
  }

  /// Subscribe to admin notifications (stubbed)
  Future<void> subscribeToAdminNotifications() async {
    print('⚠️ Admin notifications disabled (Dependency removed)');
    // No-op
  }

  /// Update user association (stubbed)
  Future<void> updateUserAssociation(String userId) async {
    print('⚠️ User notification association disabled (Dependency removed)');
    // No-op
  }

  /// Unsubscribe from admin notifications (stubbed)
  Future<void> unsubscribeFromAdminNotifications() async {
    // No-op
  }

  /// Clear user association (stubbed)
  Future<void> clearUserAssociation() async {
    // No-op
  }
}
