import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/services/auth_service.dart';
import 'dart:async';
import 'reset_password_page.dart';

class VerifyResetCodePage extends StatefulWidget {
  final String email;

  const VerifyResetCodePage({super.key, required this.email});

  @override
  State<VerifyResetCodePage> createState() => _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends State<VerifyResetCodePage> {
  final _authService = AuthService();
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isVerifying = false;
  bool _isResending = false;
  int _countdown = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
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

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();

    if (code.length != 6) {
      _showErrorDialog('Silakan masukkan kode verifikasi 6 karakter');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final result = await _authService.verifyResetCode(widget.email, code);

      setState(() {
        _isVerifying = false;
      });

      if (!mounted) return;

      if (result['success'] == true) {
        // Navigate to reset password page dengan pushReplacement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResetPasswordPage(email: widget.email, code: code),
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
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      _showErrorDialog('Terjadi kesalahan saat verifikasi kode');
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
    });

    try {
      final result = await _authService.requestPasswordReset(widget.email);

      setState(() {
        _isResending = false;
      });

      if (!mounted) return;

      if (result['success'] == true) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode verifikasi baru telah dikirim'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorDialog(result['error'] ?? 'Gagal mengirim ulang kode');
      }
    } catch (e) {
      setState(() {
        _isResending = false;
      });
      _showErrorDialog('Terjadi kesalahan saat mengirim ulang kode');
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

  Widget _buildCodeInput(int index) {
    return SizedBox(
      width: 38,
      height: 56,
      child: TextFormField(
        controller: _codeControllers[index],
        focusNode: _codeFocusNodes[index],
        keyboardType: TextInputType.text,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
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

          // Auto verify when all 6 characters are filled
          if (index == 5 && value.isNotEmpty) {
            final code = _codeControllers.map((c) => c.text).join();
            if (code.length == 6) {
              _verifyCode();
            }
          }
        },
        onTap: () {
          _codeControllers[index].clear();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Mencegah kembali dengan back button, harus klik tombol "Kembali ke Email"
      onWillPop: () async => false,
      child: Scaffold(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          const Text(
                            'VERIFIKASI KODE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Subtitle
                          Text(
                            'Masukkan kode 6 karakter yang telah dikirim ke',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF4169E1),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Code Input Boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) =>
                                  Flexible(child: _buildCodeInput(index)),
                            ),
                          ),

                          if (_isVerifying)
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
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

                          const SizedBox(height: 24),

                          // Resend Code Button
                          TextButton(
                            onPressed: (_countdown > 0 || _isResending)
                                ? null
                                : _resendCode,
                            child: _isResending
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _countdown > 0
                                        ? 'Kirim ulang dalam ${_countdown}s'
                                        : 'Kirim Ulang Kode',
                                    style: TextStyle(
                                      color: _countdown > 0
                                          ? Colors.grey
                                          : const Color(0xFF4169E1),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 16),

                          // Back to Email Button
                          TextButton(
                            onPressed: () {
                              // Navigate back to forgot password dengan pushReplacement
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/forgot-password',
                                (route) => route.settings.name == '/login',
                              );
                            },
                            child: const Text(
                              'Kembali ke Email',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
