import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/services/auth_service.dart';
import 'dart:async';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  // Verification code controllers (6 digits)
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _isCodeSent = false;
  bool _isVerifying = false;
  bool _isEmailVerified = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  // Password validation states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  @override
  void dispose() {
    _fullnameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _codeFocusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 30;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _validatePassword(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSymbol = RegExp(r'[!@#\$%^&*]').hasMatch(password);
    });
  }

  Future<void> _sendVerificationCode() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog('Silakan masukkan email terlebih dahulu');
      return;
    }

    // Validasi format email
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      _showErrorDialog('Format email tidak valid');
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      // Cek apakah email sudah terdaftar
      final checkEmail = await _authService.checkEmailExists(
        _emailController.text.trim(),
      );

      if (checkEmail['exists'] == true) {
        setState(() {
          _isSendingCode = false;
        });
        _showErrorDialog(
          'Email sudah terdaftar. Silakan gunakan email lain atau login.',
        );
        return;
      }

      final result = await _authService.resendVerificationCode(
        _emailController.text.trim(),
      );

      setState(() {
        _isSendingCode = false;
      });

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _isCodeSent = true;
        });

        _startCountdown();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode verifikasi telah dikirim ke email Anda'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorDialog(result['error'] ?? 'Gagal mengirim kode verifikasi');
      }
    } catch (e) {
      setState(() {
        _isSendingCode = false;
      });
      _showErrorDialog('Terjadi kesalahan saat mengirim kode verifikasi');
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();

    if (code.length != 6) {
      _showErrorDialog('Silakan masukkan kode verifikasi 6 digit');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final result = await _authService.verifyEmail(
      _emailController.text.trim(),
      code,
    );

    setState(() {
      _isVerifying = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _isEmailVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email berhasil diverifikasi'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showErrorDialog(result['error'] ?? 'Kode verifikasi tidak valid');
      // Clear code inputs
      for (var controller in _codeControllers) {
        controller.clear();
      }
      _codeFocusNodes[0].requestFocus();
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_isEmailVerified) {
        _showErrorDialog('Silakan verifikasi email terlebih dahulu');
        return;
      }

      // Validasi password dengan pop-up
      final password = _passwordController.text;
      if (password.isEmpty) {
        _showErrorDialog('Silakan masukkan password');
        return;
      }
      if (password.length < 8) {
        _showErrorDialog('Password minimal 8 karakter');
        return;
      }
      if (!RegExp(r'[A-Z]').hasMatch(password)) {
        _showErrorDialog('Password harus mengandung minimal 1 huruf kapital');
        return;
      }
      if (!RegExp(r'[0-9]').hasMatch(password)) {
        _showErrorDialog('Password harus mengandung minimal 1 angka');
        return;
      }
      if (!RegExp(r'[!@#\$%^&*]').hasMatch(password)) {
        _showErrorDialog(
          'Password harus mengandung minimal 1 simbol (!@#\$%^&*)',
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Cek apakah NIM sudah terdaftar
      final checkNim = await _authService.checkNimExists(
        _nimController.text.trim(),
      );

      if (checkNim['exists'] == true) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('NIM sudah terdaftar. Silakan gunakan NIM lain.');
        return;
      }

      final result = await _authService.registerUser(
        username: _fullnameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nim: _nimController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (result['success'] == true) {
        // Langsung redirect ke login tanpa pop-up
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registrasi berhasil! Silakan login untuk melanjutkan.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Redirect ke login setelah 500ms
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context); // Back to login
          }
        });
      } else {
        _showErrorDialog(result['error'] ?? 'Registrasi gagal');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(color: const Color(0xFF4169E1)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogin() {
    Navigator.pop(context);
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: isMet ? Colors.green : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCodeInput(int index) {
    return SizedBox(
      width: 38,
      height: 56,
      child: TextFormField(
        controller: _codeControllers[index],
        focusNode: _codeFocusNodes[index],
        keyboardType: TextInputType.text,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        ],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _codeFocusNodes[index + 1].requestFocus();
          }

          // Auto verify when all 6 digits are filled
          if (index == 5 && value.isNotEmpty) {
            final code = _codeControllers.map((c) => c.text).join();
            if (code.length == 6) {
              _verifyCode();
            }
          }
        },
        onTap: () {
          // Clear the field when tapped
          _codeControllers[index].clear();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Unit Activity Title
                  Text(
                    'UNIT ACTIVITY',
                    style: GoogleFonts.orbitron(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4169E1),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Card Container
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Register Title
                          const Text(
                            'REGISTER',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Fullname Input Field
                          TextFormField(
                            controller: _fullnameController,
                            keyboardType: TextInputType.name,
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4169E1),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Silakan masukkan nama lengkap';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // NIM Input Field
                          TextFormField(
                            controller: _nimController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: 'NIM',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4169E1),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Silakan masukkan NIM';
                              }
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                return 'NIM hanya boleh berisi angka';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Email Input Field with Send Button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !_isEmailVerified,
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                    filled: true,
                                    fillColor: _isEmailVerified
                                        ? Colors.green[50]
                                        : Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: _isEmailVerified
                                            ? Colors.green
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: _isEmailVerified
                                            ? Colors.green
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF4169E1),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    suffixIcon: _isEmailVerified
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Silakan masukkan email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Email tidak valid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      (_countdown > 0 ||
                                          _isEmailVerified ||
                                          _isSendingCode)
                                      ? null
                                      : _sendVerificationCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isEmailVerified
                                        ? Colors.green
                                        : const Color(0xFF4169E1),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  child: _isSendingCode
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _isEmailVerified
                                              ? 'Verified'
                                              : _countdown > 0
                                              ? '${_countdown}s'
                                              : 'Send',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),

                          // Verification Code Input (6 boxes)
                          if (_isCodeSent && !_isEmailVerified)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Masukkan Kode Verifikasi',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      6,
                                      (index) => Flexible(
                                        child: _buildVerificationCodeInput(
                                          index,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isVerifying)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Center(
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Password Input Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onChanged: _validatePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4169E1),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password Requirements
                          Text(
                            'Password harus mengandung:',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRequirement(
                            'Minimal 8 karakter',
                            _hasMinLength,
                          ),
                          _buildRequirement('1 huruf kapital', _hasUppercase),
                          _buildRequirement('1 angka', _hasNumber),
                          _buildRequirement('1 simbol (!@#\$%^&*)', _hasSymbol),
                          const SizedBox(height: 24),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4169E1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'REGISTER',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already Have an Account ? ",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: _handleLogin,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Color(0xFF4169E1),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
