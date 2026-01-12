import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AddPenggunaPage extends StatefulWidget {
  const AddPenggunaPage({super.key});

  @override
  State<AddPenggunaPage> createState() => _AddPenggunaPageState();
}

class _AddPenggunaPageState extends State<AddPenggunaPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nimController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Password validation states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSymbol = RegExp(r'[!@#\$%^&*]').hasMatch(password);
    });
  }

  // Hash password using SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate password requirements
    final password = _passwordController.text;
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 8 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password harus mengandung minimal 1 huruf kapital'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password harus mengandung minimal 1 angka'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!RegExp(r'[!@#\$%^&*]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password harus mengandung minimal 1 simbol (!@#\$%^&*)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final nim = _nimController.text.trim();

      // Check if email already exists
      final existingEmail = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (existingEmail != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email sudah terdaftar'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Check if NIM already exists
      final existingNim = await _supabase
          .from('users')
          .select('nim')
          .eq('nim', nim)
          .maybeSingle();

      if (existingNim != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('NIM sudah terdaftar'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Insert user directly into database (NO Supabase Auth)
      // Password is hashed using SHA256
      await _supabase.from('users').insert({
        'username': username,
        'email': email,
        'password': _hashPassword(password),
        'nim': nim,
        'picture': null,
        'create_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Tambah Pengguna',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Form Card
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Username Field
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username tidak boleh kosong';
                        }
                        final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,}$');
                        if (!usernameRegex.hasMatch(value)) {
                          return 'Username minimal 3 karakter (huruf, angka, underscore)';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: isMobile ? 14 : 20),

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // NIM Field
                    _buildTextField(
                      controller: _nimController,
                      label: 'NIM',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'NIM tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: isMobile ? 16 : 24),

                    // Password Section
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Colors.blue[700],
                                size: isMobile ? 18 : 20,
                              ),
                              SizedBox(width: isMobile ? 6 : 8),
                              Text(
                                'Password',
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 13 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 12 : 16),

                          // Password Field
                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          SizedBox(height: isMobile ? 12 : 16),

                          // Password Requirements
                          Container(
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password harus mengandung:',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 11 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: isMobile ? 6 : 8),
                                _buildPasswordRequirement(
                                  'Minimal 8 karakter',
                                  _hasMinLength,
                                ),
                                _buildPasswordRequirement(
                                  'Minimal 1 huruf kapital',
                                  _hasUppercase,
                                ),
                                _buildPasswordRequirement(
                                  'Minimal 1 angka',
                                  _hasNumber,
                                ),
                                _buildPasswordRequirement(
                                  'Minimal 1 simbol (!@#\$%^&*)',
                                  _hasSymbol,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 20 : 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 16,
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 13 : 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 10 : 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4169E1),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Simpan',
                                    style: GoogleFonts.inter(
                                      fontSize: isMobile ? 13 : 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 14,
            ),
          ),
          style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
            ),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey[600],
              ),
              onPressed: onToggleVisibility,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 14,
            ),
          ),
          style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 3 : 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: isMobile ? 14 : 16,
            color: isMet ? Colors.green : Colors.grey[400],
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 11 : 12,
              color: isMet ? Colors.green[700] : Colors.grey[600],
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
