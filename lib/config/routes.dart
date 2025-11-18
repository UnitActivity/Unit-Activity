import 'package:flutter/material.dart';

class AppRoutes {
  // Auth Routes
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Admin Routes
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';

  // Navigation Helper Methods
  static void navigateToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, login);
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.pushNamed(context, register);
  }

  static void navigateToForgotPassword(BuildContext context) {
    Navigator.pushNamed(context, forgotPassword);
  }

  static void navigateToAdmin(BuildContext context) {
    Navigator.pushReplacementNamed(context, admin);
  }

  static void navigateToAdminDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, adminDashboard);
  }
}
