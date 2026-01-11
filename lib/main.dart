import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:device_preview/device_preview.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:unit_activity/auth/login.dart';
import 'package:unit_activity/auth/register.dart';
import 'package:unit_activity/auth/forgot_password.dart';
import 'package:unit_activity/admin/dashboard_admin.dart';
import 'package:unit_activity/ukm/dashboard_ukm.dart';
import 'package:unit_activity/user/dashboard_user.dart';
import 'package:unit_activity/config/config.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

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

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

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

  // Disable DevicePreview in release mode for better performance
  // final enableDevicePreview = !kReleaseMode;

  runApp(DevicePreview(enabled: false, builder: (context) => const MyApp()));
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
