// Main Auth Service - Aggregator untuk semua auth services
import 'register_service.dart';
import 'email_verification_service.dart';
import 'login_service.dart';
import 'password_reset_service.dart';

class AuthService {
  // Service instances
  final _registerService = RegisterService();
  final _emailVerificationService = EmailVerificationService();
  final _loginService = LoginService();
  final _passwordResetService = PasswordResetService();

  // ========== REGISTER METHODS ==========
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
    String? nim,
    String? picture,
  }) {
    return _registerService.registerUser(
      username: username,
      email: email,
      password: password,
      nim: nim,
      picture: picture,
    );
  }

  // ========== EMAIL VERIFICATION METHODS ==========
  Future<Map<String, dynamic>> verifyEmail(String email, String code) {
    return _emailVerificationService.verifyEmail(email, code);
  }

  Future<Map<String, dynamic>> resendVerificationCode(String email) {
    return _emailVerificationService.resendVerificationCode(email);
  }

  Future<Map<String, dynamic>> checkEmailExists(String email) {
    return _registerService.checkEmailExists(email);
  }

  Future<Map<String, dynamic>> checkNimExists(String nim) {
    return _registerService.checkNimExists(nim);
  }

  // ========== LOGIN METHODS ==========
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) {
    return _loginService.loginUser(email: email, password: password);
  }

  Future<Map<String, dynamic>> logoutUser() {
    return _loginService.logoutUser();
  }

  Future<Map<String, dynamic>> getCurrentUser() {
    return _loginService.getCurrentUser();
  }

  // ========== PASSWORD RESET METHODS ==========
  Future<Map<String, dynamic>> requestPasswordReset(String email) {
    return _passwordResetService.requestPasswordReset(email);
  }

  Future<Map<String, dynamic>> verifyResetCode(String email, String code) {
    return _passwordResetService.verifyResetCode(email, code);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _passwordResetService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }
}
