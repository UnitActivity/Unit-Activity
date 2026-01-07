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

  // Activity data
  List<Map<String, dynamic>> _eventAttendance = [];
  List<Map<String, dynamic>> _meetingAttendance = [];
  List<Map<String, dynamic>> _ukmMemberships = [];
  List<Map<String, dynamic>> _activityLogs = [];
  bool _isLoadingActivities = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user['username']);
    _emailController = TextEditingController(text: widget.user['email']);
    _nimController = TextEditingController(text: widget.user['nim']);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoadingActivities = true);

    try {
      final userId = widget.user['id_user'];

      // Load event attendance with event and UKM details
      final eventData = await _supabase
          .from('absen_event')
          .select('''
            *,
            events!absen_event_id_event_fkey(
              id_events,
              nama_event,
              tanggal_mulai,
              jam_mulai,
              ukm(nama_ukm)
            )
          ''')
          .eq('id_user', userId)
          .order('create_at', ascending: false);

      // Load meeting attendance with meeting details
      final meetingData = await _supabase
          .from('absen_pertemuan')
          .select('''
            *,
            pertemuan!absen_pertemuan_id_pertemuan_fkey(
              id_pertemuan,
              topik,
              tanggal_pertemuan,
              jam_mulai,
              ukm(nama_ukm)
            )
          ''')
          .eq('id_user', userId)
          .order('create_at', ascending: false);

      // Load UKM memberships
      final ukmData = await _supabase
          .from('user_halaman_ukm')
          .select('''
            *,
            ukm(nama_ukm, logo, description)
          ''')
          .eq('id_user', userId)
          .order('follow', ascending: false);

      // Build comprehensive activity log
      final logs = <Map<String, dynamic>>[];

      // Add event attendance to logs
      for (var event in (eventData as List)) {
        logs.add({
          'action':
              'Absensi Event: ${event['events']?['nama_event'] ?? 'Event'}',
          'timestamp': event['create_at'],
          'type': 'event',
          'status': event['status'],
          'details': event,
        });
      }

      // Add meeting attendance to logs
      for (var meeting in (meetingData as List)) {
        logs.add({
          'action':
              'Absensi Pertemuan: ${meeting['pertemuan']?['topik'] ?? 'Pertemuan'}',
          'timestamp': meeting['create_at'],
          'type': 'meeting',
          'status': meeting['status'],
          'details': meeting,
        });
      }

      // Add UKM follows/unfollows to logs
      for (var ukm in (ukmData as List)) {
        if (ukm['follow'] != null) {
          logs.add({
            'action': 'Bergabung dengan ${ukm['ukm']?['nama_ukm'] ?? 'UKM'}',
            'timestamp': ukm['follow'],
            'type': 'ukm',
            'status': ukm['status'],
            'details': ukm,
          });
        }
        if (ukm['unfollow'] != null) {
          logs.add({
            'action': 'Keluar dari ${ukm['ukm']?['nama_ukm'] ?? 'UKM'}',
            'timestamp': ukm['unfollow'],
            'type': 'ukm_unfollow',
            'status': ukm['status'],
            'details': ukm,
          });
        }
      }

      // Sort logs by timestamp descending
      logs.sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      setState(() {
        _eventAttendance = List<Map<String, dynamic>>.from(eventData);
        _meetingAttendance = List<Map<String, dynamic>>.from(meetingData);
        _ukmMemberships = List<Map<String, dynamic>>.from(ukmData);
        _activityLogs = logs;
        _isLoadingActivities = false;
      });
    } catch (e) {
      print('Error loading activities: $e');
      setState(() => _isLoadingActivities = false);
    }
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
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_eventAttendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada aktivitas event',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _eventAttendance.length,
      itemBuilder: (context, index) {
        final attendance = _eventAttendance[index];
        final event = attendance['events'] as Map<String, dynamic>?;
        final status = attendance['status']?.toString() ?? '';
        final isPresent = status.toLowerCase() == 'hadir';

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
                      event?['nama_event'] ?? 'Event',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (event?['ukm']?['nama_ukm'] != null) ...[
                          Text(
                            event!['ukm']['nama_ukm'],
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
                        ],
                        Text(
                          _formatDate(event?['tanggal_mulai']),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (attendance['jam'] != null) ...[
                          Text(
                            ' • ',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            attendance['jam'].toString().substring(0, 5),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPresent ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeetingsTab() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_meetingAttendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada aktivitas pertemuan',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final totalPresent = _meetingAttendance
        .where((m) => (m['status']?.toString().toLowerCase() ?? '') == 'hadir')
        .length;

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
                    '$totalPresent',
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
                    '${_meetingAttendance.length}',
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
            itemCount: _meetingAttendance.length,
            itemBuilder: (context, index) {
              final attendance = _meetingAttendance[index];
              final meeting = attendance['pertemuan'] as Map<String, dynamic>?;
              final status = attendance['status']?.toString() ?? '';
              final isPresent = status.toLowerCase() == 'hadir';

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
                            meeting?['topik'] ?? 'Pertemuan',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (meeting?['ukm']?['nama_ukm'] != null) ...[
                                Text(
                                  meeting!['ukm']['nama_ukm'],
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
                              ],
                              Text(
                                _formatDate(meeting?['tanggal_pertemuan']),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (attendance['jam'] != null) ...[
                                Text(
                                  ' • ',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  attendance['jam'].toString().substring(0, 5),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPresent ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ukmMemberships.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum bergabung dengan UKM',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _ukmMemberships.length,
      itemBuilder: (context, index) {
        final membership = _ukmMemberships[index];
        final ukm = membership['ukm'] as Map<String, dynamic>?;
        final status = membership['status']?.toString() ?? '';
        final isActive =
            status.toLowerCase() == 'aktif' || membership['unfollow'] == null;

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
                child:
                    ukm?['logo'] != null && ukm!['logo'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          ukm['logo'],
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.groups,
                            color: isActive
                                ? Colors.green[700]
                                : Colors.red[700],
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.groups,
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
                      ukm?['nama_ukm'] ?? 'UKM',
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
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bergabung: ${_formatDate(membership['follow'])}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (membership['unfollow'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Keluar: ${_formatDate(membership['unfollow'])}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Tidak Aktif',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityLogTab() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activityLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada log aktivitas',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _activityLogs.length,
      itemBuilder: (context, index) {
        final activity = _activityLogs[index];
        final type = activity['type']?.toString() ?? '';

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
                      color: _getActivityColor(type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (index < _activityLogs.length - 1)
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
                            _getActivityIcon(type),
                            size: 16,
                            color: _getActivityColor(type),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activity['action'] ?? 'Aktivitas',
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
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(activity['timestamp']),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (activity['status'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  activity['status'].toString(),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                activity['status'].toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
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

  Color _getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('hadir') || lowerStatus.contains('aktif')) {
      return Colors.green;
    } else if (lowerStatus.contains('tidak')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'ukm':
        return const Color(0xFF4169E1);
      case 'ukm_unfollow':
        return Colors.orange;
      case 'event':
        return Colors.green;
      case 'meeting':
        return Colors.purple;
      case 'profile':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'ukm':
        return Icons.groups;
      case 'ukm_unfollow':
        return Icons.exit_to_app;
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
