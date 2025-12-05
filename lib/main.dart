import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:device_preview/device_preview.dart';
import 'package:unit_activity/auth/login.dart';
import 'package:unit_activity/auth/register.dart';
import 'package:unit_activity/auth/forgot_password.dart';
import 'package:unit_activity/user/dashboard_user.dart';
import 'package:unit_activity/user/event.dart';
import 'package:unit_activity/user/profile.dart';
import 'package:unit_activity/admin/dashboard_admin.dart';
import 'package:unit_activity/config/routes.dart';
import 'package:unit_activity/config/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(DevicePreview(enabled: true, builder: (context) => const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unit Activity',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4169E1)),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      routes: {
        // Auth Routes
        AppRoutes.home: (context) => const DashboardUser(),
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.register: (context) => const RegisterPage(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordPage(),

        // User Routes
        AppRoutes.user: (context) => const DashboardUser(),
        AppRoutes.userDashboard: (context) => const DashboardUser(),
        AppRoutes.userEvent: (context) => const UserEventPage(),
        AppRoutes.userUKM: (context) =>
            const DashboardUser(), // Ganti dengan UKMPage jika ada
        AppRoutes.userHistory: (context) =>
            const DashboardUser(), // Ganti dengan HistoryPage jika ada
        AppRoutes.userProfile: (context) => const ProfilePage(),

        // Admin Routes
        AppRoutes.admin: (context) => const DashboardAdminPage(),
        AppRoutes.adminDashboard: (context) => const DashboardAdminPage(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Page not found: ${settings.name}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
