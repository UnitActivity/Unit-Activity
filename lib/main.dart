import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:device_preview/device_preview.dart';
import 'package:unit_activity/auth/login.dart';
import 'package:unit_activity/auth/register.dart';
import 'package:unit_activity/auth/forgot_password.dart';
import 'package:unit_activity/admin/dashboard_admin.dart';
import 'package:unit_activity/ukm/dashboard_ukm.dart';
import 'package:unit_activity/user/dashboard_user.dart';
import 'package:unit_activity/config/config.dart';
import 'package:unit_activity/services/custom_auth_service.dart';
import 'package:unit_activity/services/push_notification_service.dart';
import 'package:unit_activity/widgets/auth_guard.dart';

/// Check if current platform supports Firebase Messaging (mobile only)
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (e) {
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remove # from URL (for web only)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    // Continue without .env - use fallback values in config
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Firebase Messaging background handler (mobile only - not supported on Windows/macOS/Linux)
  if (_isMobilePlatform) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Initialize CustomAuthService and restore session
  print('========== INITIALIZING AUTH SERVICE ==========');
  final authService = CustomAuthService();
  await authService.initialize();
  print('Auth service initialized. Logged in: ${authService.isLoggedIn}');
  if (authService.isLoggedIn) {
    print(
      'Current user: ${authService.currentUserRole} - ${authService.currentUser?['name']}',
    );
  }

  // Initialize Push Notifications (mobile only - not supported on desktop)
  if (_isMobilePlatform) {
    print('========== INITIALIZING PUSH NOTIFICATIONS ==========');
    final pushNotificationService = PushNotificationService();
    await pushNotificationService.initialize();

    // Subscribe to admin broadcast notifications
    await pushNotificationService.subscribeToAdminNotifications();
    print('Subscribed to admin notifications');

    // If user is logged in, update token association
    if (authService.isLoggedIn && authService.currentUserId != null) {
      await pushNotificationService.updateUserAssociation(
        authService.currentUserId!,
      );
    }
  }

  // Disable DevicePreview in release mode for better performance
  final enableDevicePreview = !kReleaseMode;

  runApp(
    DevicePreview(
      enabled: enableDevicePreview,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    final authService = CustomAuthService();
    String initialRoute = '/login';

    if (authService.isLoggedIn) {
      final role = authService.currentUserRole;
      if (role == 'admin') {
        initialRoute = '/admin';
      } else if (role == 'ukm') {
        initialRoute = '/ukm';
      } else {
        initialRoute = '/user';
      }
      print('User already logged in, redirecting to: $initialRoute');
    }

    return MaterialApp(
      title: 'Unit Activity',
      debugShowCheckedModeBanner: false,
      // Konfigurasi untuk Device Preview
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4169E1)),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const LoginPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/admin': (context) => const DashboardAdminPage(),
        '/admin/dashboard': (context) => const DashboardAdminPage(),
        '/ukm': (context) => const DashboardUKMPage(),
        '/ukm/dashboard': (context) => const DashboardUKMPage(),
        '/user': (context) => const DashboardUser(),
        '/user/dashboard': (context) => const DashboardUser(),
      },
    );
  }
}

/// Background message handler untuk notifikasi saat app tertutup
/// CRITICAL: Function ini harus top-level function (tidak boleh di dalam class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Supabase for background context
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  print('========== BACKGROUND MESSAGE (APP CLOSED) ==========');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');

  // Save notification to database
  try {
    final supabase = Supabase.instance.client;
    final notification = message.notification;

    if (notification != null) {
      final userId = supabase.auth.currentUser?.id;

      final notificationData = {
        'judul': notification.title ?? 'Notifikasi',
        'pesan': notification.body ?? '',
        'type': message.data['type'] ?? 'info',
        'is_read': false,
        'create_at': DateTime.now().toIso8601String(),
      };

      if (userId != null) {
        // Save to user-specific notifications
        await supabase.from('notification_preference').insert({
          ...notificationData,
          'id_user': userId,
        });
        print('✅ Background notification saved for user: $userId');
      } else {
        // Anonymous notifications not supported without proper table
        print('ℹ️ No user logged in, background notification not saved');
      }
    }
  } catch (e) {
    print('❌ Error saving background notification: $e');
  }
}
