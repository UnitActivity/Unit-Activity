import 'package:flutter/material.dart';

class AppRoutes {
  // ==================== AUTH ROUTES ====================
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot_password';
  static const String verificationCode = '/verify_reset_code';
  static const String resetPassword = '/reset_password';

  // ==================== USER ROUTES ====================
  static const String user = '/user';
  static const String userDashboard = '/user/dashboard';
  static const String userEvent = '/user/event';
  static const String userUKM = '/user/ukm';
  static const String userHistory = '/user/history';
  static const String userProfile = '/user/profile';

  // ==================== ADMIN ROUTES ====================
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';

  // ==================== ERROR ROUTES ====================
  static const String pageNotFound = '/404';

  // ==================== AUTH NAVIGATION ====================
  /// Navigate to Login Page
  static void navigateToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, login);
  }

  /// Navigate to Register Page
  static void navigateToRegister(BuildContext context) {
    Navigator.pushNamed(context, register);
  }

  /// Navigate to Forgot Password Page
  static void navigateToForgotPassword(BuildContext context) {
    Navigator.pushNamed(context, forgotPassword);
  }

  /// Navigate to Verification Code Page
  static void navigateToVerificationCode(BuildContext context) {
    Navigator.pushNamed(context, verificationCode);
  }

  /// Navigate to Reset Password Page
  static void navigateToResetPassword(BuildContext context) {
    Navigator.pushNamed(context, resetPassword);
  }

  // ==================== USER NAVIGATION ====================
  /// Navigate to Home/Dashboard
  static void navigateToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, home);
  }

  /// Navigate to User Dashboard
  static void navigateToUserDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, userDashboard);
  }

  /// Navigate to User Event
  static void navigateToUserEvent(BuildContext context) {
    Navigator.pushNamed(context, userEvent);
  }

  /// Navigate to User UKM
  static void navigateToUserUKM(BuildContext context) {
    Navigator.pushNamed(context, userUKM);
  }

  /// Navigate to User History
  static void navigateToUserHistory(BuildContext context) {
    Navigator.pushNamed(context, userHistory);
  }

  /// Navigate to User Profile
  static void navigateToUserProfile(BuildContext context) {
    Navigator.pushNamed(context, userProfile);
  }

  // ==================== ADMIN NAVIGATION ====================
  /// Navigate to Admin Dashboard
  static void navigateToAdminDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, adminDashboard);
  }

  // ==================== AUTH ACTIONS ====================
  /// Logout user and navigate to login
  static void logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }

  /// Clear all routes and navigate to home
  static void clearAllAndNavigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, home, (route) => false);
  }

  // ==================== ERROR NAVIGATION ====================
  /// Navigate to 404 Page Not Found
  static void navigateToPageNotFound(BuildContext context) {
    Navigator.pushNamed(context, pageNotFound);
  }

  /// Safe navigation with error handling
  static void safeNavigate(BuildContext context, String routeName) {
    try {
      Navigator.pushNamed(context, routeName);
    } catch (e) {
      debugPrint('Navigation error: $e');
      navigateToPageNotFound(context);
    }
  }
}
