import 'package:flutter/material.dart';

class AppRoutes {
  // Auth Routes
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot_password';
  static const String verificationCode = '/verify_reset_code';
  static const String resetPassword = '/reset_password';

  // User Routes
  static const String user = '/user';
  static const String userDashboard = '/user/dashboard';
  static const String userEvent = '/user/event';
  static const String userUKM = '/user/ukm';
  static const String userHistory = '/user/history';
  static const String userProfile = '/user/profile';

  // Admin Routes
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';

  // Error Routes
  static const String pageNotFound = '/404';

  // ==================== AUTH NAVIGATION ====================
  static void navigateToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, login);
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.pushNamed(context, register);
  }

  // ==================== USER NAVIGATION ====================
  static void navigateToUserDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, userDashboard);
  }

  static void navigateToUserEvent(BuildContext context) {
    Navigator.pushNamed(context, userEvent);
  }

  static void navigateToUserUKM(BuildContext context) {
    Navigator.pushNamed(context, userUKM);
  }

  static void navigateToUserHistory(BuildContext context) {
    Navigator.pushNamed(context, userHistory);
  }

  static void navigateToUserProfile(BuildContext context) {
    Navigator.pushNamed(context, userProfile);
  }

  // ==================== LOGOUT ====================
  static void logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }
}
