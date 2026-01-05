import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPenggunaPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const DetailPenggunaPage({super.key, required this.user});

  @override
  State<DetailPenggunaPage> createState() => _DetailPenggunaPageState();
}

class _DetailPenggunaPageState extends State<DetailPenggunaPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _changePassword = false;

  // Controllers for edit mode
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _nimController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user['username']);
    _emailController = TextEditingController(text: widget.user['email']);
    _nimController = TextEditingController(text: widget.user['nim']);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return null; // Optional if not changing
    if (password.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password harus mengandung huruf besar';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password harus mengandung huruf kecil';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password harus mengandung angka';
    }
    return null;
  }

  Future<void> _saveChanges() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _nimController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password if changing
    if (_changePassword) {
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password tidak boleh kosong'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final passwordError = _validatePassword(_passwordController.text);
      if (passwordError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(passwordError), backgroundColor: Colors.red),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password dan konfirmasi password tidak sama'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      // Update user data
      final updateData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'nim': _nimController.text.trim(),
      };

      await _supabase
          .from('users')
          .update(updateData)
          .eq('id_user', widget.user['id_user']);

      // Update password if changed
      if (_changePassword && _passwordController.text.isNotEmpty) {
        await _supabase.auth.admin.updateUserById(
          widget.user['id_user'],
          attributes: AdminUserAttributes(password: _passwordController.text),
        );
      }

      // Update local data
      widget.user['username'] = _usernameController.text.trim();
      widget.user['email'] = _emailController.text.trim();
      widget.user['nim'] = _nimController.text.trim();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _changePassword
                  ? 'Data dan password berhasil diperbarui'
                  : 'Data berhasil diperbarui',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditMode = false;
          _isSaving = false;
          _changePassword = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelEdit() {
    // Reset controllers to original values
    _usernameController.text = widget.user['username'] ?? '';
    _emailController.text = widget.user['email'] ?? '';
    _nimController.text = widget.user['nim'] ?? '';
    _passwordController.clear();
    _confirmPasswordController.clear();

    setState(() {
      _isEditMode = false;
      _changePassword = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context, _isEditMode ? null : true),
        ),
        title: Text(
          _isEditMode ? 'Edit Pengguna' : 'Detail Pengguna',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: _isEditMode
            ? [
                // Cancel button
                TextButton(
                  onPressed: _isSaving ? null : _cancelEdit,
                  child: Text(
                    'Batal',
                    style: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Save button
                TextButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Simpan',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4169E1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF4169E1)),
                  onPressed: () {
                    setState(() => _isEditMode = true);
                  },
                  tooltip: 'Edit Pengguna',
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Combined Profile & Information Card
                _buildProfileInfoCard(isDesktop),
                const SizedBox(height: 24),

                // Activity Card
                _buildActivityCard(isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard(bool isDesktop) {
    final isMobile = !isDesktop && MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : (isMobile ? 16 : 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture - Centered
          CircleAvatar(
            radius: isDesktop ? 60 : (isMobile ? 45 : 50),
            backgroundImage:
                widget.user['picture'] != null &&
                    widget.user['picture'].isNotEmpty
                ? NetworkImage(widget.user['picture'])
                : null,
            backgroundColor: const Color(0xFF4169E1),
            child:
                widget.user['picture'] == null || widget.user['picture'].isEmpty
                ? Text(
                    _getInitials(_usernameController.text),
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 32 : (isMobile ? 22 : 28),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Username - Centered (Editable in edit mode)
          if (_isEditMode)
            SizedBox(
              width: 300,
              child: TextField(
                controller: _usernameController,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 24 : (isMobile ? 16 : 20),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
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
                    borderSide: const BorderSide(color: Color(0xFF4169E1)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            )
          else
            Text(
              _usernameController.text,
              style: GoogleFonts.inter(
                fontSize: isDesktop ? 24 : (isMobile ? 16 : 20),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          const SizedBox(height: 8),

          // Role Badge - Centered
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4169E1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Mahasiswa',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4169E1),
              ),
            ),
          ),

          SizedBox(height: isMobile ? 20 : 32),

          // Divider
          Divider(color: Colors.grey[300]),

          SizedBox(height: isMobile ? 16 : 24),

          // Information Section Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Informasi Pengguna',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 15 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Information Rows (Editable in edit mode)
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'NIM',
            value: _nimController.text,
            isDesktop: isDesktop,
            controller: _nimController,
          ),
          const Divider(height: 32),

          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _emailController.text,
            isDesktop: isDesktop,
            controller: _emailController,
          ),
          const Divider(height: 32),

          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Bergabung Pada',
            value: _formatDate(widget.user['create_at']),
            isDesktop: isDesktop,
            controller: null, // Not editable
          ),

          // Password Change Section (only in edit mode)
          if (_isEditMode) ...[
            const Divider(height: 32),

            // Change Password Checkbox
            Row(
              children: [
                Checkbox(
                  value: _changePassword,
                  onChanged: (value) {
                    setState(() {
                      _changePassword = value ?? false;
                      if (!_changePassword) {
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      }
                    });
                  },
                  activeColor: const Color(0xFF4169E1),
                ),
                Text(
                  'Ubah Password',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            // Password Fields (shown when checkbox is checked)
            if (_changePassword) ...[
              const SizedBox(height: 16),

              // New Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                  hintText: 'Minimal 8 karakter, huruf besar, kecil, dan angka',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF4169E1),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
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
                    borderSide: const BorderSide(color: Color(0xFF4169E1)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                  hintText: 'Masukkan ulang password baru',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF4169E1),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
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
                    borderSide: const BorderSide(color: Color(0xFF4169E1)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),

              // Password Requirements Info
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Persyaratan Password:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildPasswordRequirement('Minimal 8 karakter'),
                    _buildPasswordRequirement('Mengandung huruf besar (A-Z)'),
                    _buildPasswordRequirement('Mengandung huruf kecil (a-z)'),
                    _buildPasswordRequirement('Mengandung angka (0-9)'),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.blue[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(bool isDesktop) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return DefaultTabController(
      length: 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Tabs
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivitas Pengguna',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    labelColor: const Color(0xFF4169E1),
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: const Color(0xFF4169E1),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: isMobile
                        ? const [
                            Tab(icon: Icon(Icons.event, size: 20)),
                            Tab(icon: Icon(Icons.meeting_room, size: 20)),
                            Tab(icon: Icon(Icons.groups, size: 20)),
                            Tab(icon: Icon(Icons.history, size: 20)),
                          ]
                        : const [
                            Tab(text: 'Event'),
                            Tab(text: 'Pertemuan'),
                            Tab(text: 'UKM'),
                            Tab(text: 'Log Aktivitas'),
                          ],
                  ),
                ],
              ),
            ),

            // Tab Content
            SizedBox(
              height: 400,
              child: TabBarView(
                children: [
                  _buildEventsTab(),
                  _buildMeetingsTab(),
                  _buildUKMTab(),
                  _buildActivityLogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    // Dummy events data
    final events = [
      {
        'nama': 'Sparing w/ UWIKA',
        'tanggal': '22 Des 2024',
        'status': 'Hadir',
        'ukm': 'Basket',
      },
      {
        'nama': 'Friendly Match Futsal',
        'tanggal': '15 Des 2024',
        'status': 'Hadir',
        'ukm': 'Futsal',
      },
      {
        'nama': 'Mini Tournament Badminton',
        'tanggal': '10 Des 2024',
        'status': 'Tidak Hadir',
        'ukm': 'Badminton',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isPresent = event['status'] == 'Hadir';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPresent
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPresent
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPresent
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event,
                  color: isPresent ? Colors.green[700] : Colors.red[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['nama']!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          event['ukm']!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          ' • ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          event['tanggal']!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeetingsTab() {
    // Dummy meetings data
    final meetings = [
      {
        'judul': 'Pertemuan Rutin Basket',
        'tanggal': '20 Des 2024',
        'waktu': '16:00',
        'status': 'Hadir',
      },
      {
        'judul': 'Rapat Koordinasi UKM',
        'tanggal': '18 Des 2024',
        'waktu': '14:00',
        'status': 'Hadir',
      },
      {
        'judul': 'Evaluasi Bulanan',
        'tanggal': '15 Des 2024',
        'waktu': '15:00',
        'status': 'Tidak Hadir',
      },
    ];

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4169E1).withOpacity(0.1),
                const Color(0xFF4169E1).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4169E1).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${meetings.where((m) => m['status'] == 'Hadir').length}',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4169E1),
                    ),
                  ),
                  Text(
                    'Hadir',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 50, color: Colors.grey[300]),
              Column(
                children: [
                  Text(
                    '${meetings.length}',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Meetings List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              final isPresent = meeting['status'] == 'Hadir';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPresent
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPresent
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isPresent
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.meeting_room,
                        color: isPresent ? Colors.green[700] : Colors.red[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meeting['judul']!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${meeting['tanggal']} • ${meeting['waktu']}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUKMTab() {
    // Dummy UKM data
    final ukmList = [
      {
        'nama': 'UKM Basket',
        'status': 'Aktif',
        'bergabung': '20 Nov 2024',
        'posisi': 'Anggota',
        'icon': Icons.sports_basketball,
        'color': Colors.orange,
      },
      {
        'nama': 'UKM Futsal',
        'status': 'Aktif',
        'bergabung': '15 Nov 2024',
        'posisi': 'Anggota',
        'icon': Icons.sports_soccer,
        'color': Colors.green,
      },
      {
        'nama': 'UKM Badminton',
        'status': 'Tidak Aktif',
        'bergabung': '10 Nov 2024',
        'posisi': 'Anggota',
        'icon': Icons.sports_tennis,
        'color': Colors.blue,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: ukmList.length,
      itemBuilder: (context, index) {
        final ukm = ukmList[index];
        final isActive = ukm['status'] == 'Aktif';
        final color = ukm['color'] as Color;
        final icon = ukm['icon'] as IconData;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.green[700] : Colors.red[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ukm['nama'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ukm['posisi'].toString(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          ' • ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ukm['bergabung'].toString(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityLogTab() {
    // Dummy activity log data
    final activities = [
      {
        'action': 'Mendaftar UKM Basket',
        'timestamp': '20 Nov 2024, 10:30',
        'type': 'ukm',
      },
      {
        'action': 'Mengikuti Event Sparing',
        'timestamp': '22 Des 2024, 17:00',
        'type': 'event',
      },
      {
        'action': 'Hadir Pertemuan Rutin',
        'timestamp': '20 Des 2024, 16:00',
        'type': 'meeting',
      },
      {
        'action': 'Unfollow UKM Futsal',
        'timestamp': '15 Des 2024, 14:20',
        'type': 'ukm',
      },
      {
        'action': 'Mengupdate Profil',
        'timestamp': '10 Des 2024, 09:15',
        'type': 'profile',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dot
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getActivityColor(activity['type']!),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (index < activities.length - 1)
                    Container(width: 2, height: 60, color: Colors.grey[300]),
                ],
              ),
              const SizedBox(width: 16),

              // Activity content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getActivityIcon(activity['type']!),
                            size: 16,
                            color: _getActivityColor(activity['type']!),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activity['action']!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activity['timestamp']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'ukm':
        return const Color(0xFF4169E1);
      case 'event':
        return Colors.orange;
      case 'meeting':
        return Colors.green;
      case 'profile':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'ukm':
        return Icons.groups;
      case 'event':
        return Icons.event;
      case 'meeting':
        return Icons.meeting_room;
      case 'profile':
        return Icons.person;
      default:
        return Icons.info;
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDesktop,
    TextEditingController? controller,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4169E1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF4169E1), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (_isEditMode && controller != null)
                TextField(
                  controller: controller,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: label,
                    hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
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
                      borderSide: const BorderSide(color: Color(0xFF4169E1)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
