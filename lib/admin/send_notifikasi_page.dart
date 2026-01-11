import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SendNotifikasiPage extends StatefulWidget {
  const SendNotifikasiPage({super.key});

  @override
  State<SendNotifikasiPage> createState() => _SendNotifikasiPageState();
}

class _SendNotifikasiPageState extends State<SendNotifikasiPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _ukmSearchController = TextEditingController();
  final _userSearchController = TextEditingController();

  String _selectedType = 'info';
  String _selectedTarget = 'all_users';
  String? _selectedEventId;
  String? _selectedInfoId;

  final List<String> _selectedUkmIds = [];
  final List<String> _selectedUserIds = [];

  // Data from database
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _informasi = [];
  List<Map<String, dynamic>> _ukm = [];
  List<Map<String, dynamic>> _users = [];

  // Search queries
  String _ukmSearchQuery = '';
  String _userSearchQuery = '';

  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _ukmSearchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load events
      final eventsData = await _supabase
          .from('events')
          .select('id_events, nama_event, status')
          .eq('status', true)
          .order('create_at', ascending: false);

      // Load informasi
      final infoData = await _supabase
          .from('informasi')
          .select('id_informasi, judul, status_aktif')
          .eq('status_aktif', true)
          .order('create_at', ascending: false);

      // Load UKM
      final ukmData = await _supabase
          .from('ukm')
          .select('id_ukm, nama_ukm')
          .order('nama_ukm');

      // Load Users
      final usersData = await _supabase
          .from('users')
          .select('id_user, username, email')
          .order('username');

      setState(() {
        _events = List<Map<String, dynamic>>.from(eventsData);
        _informasi = List<Map<String, dynamic>>.from(infoData);
        _ukm = List<Map<String, dynamic>>.from(ukmData);
        _users = List<Map<String, dynamic>>.from(usersData);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi target selection
    if (_selectedTarget == 'specific_ukm' && _selectedUkmIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 UKM'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTarget == 'specific_user' && _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 pengguna'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Prepare notification data
      final notificationData = {
        'judul': _titleController.text.trim(),
        'pesan': _messageController.text.trim(),
        'type': _selectedType,
        'is_read': false,
        'create_at': DateTime.now().toIso8601String(),
      };

      // Add optional foreign keys
      if (_selectedEventId != null) {
        notificationData['id_events'] = _selectedEventId!;
      }
      if (_selectedInfoId != null) {
        notificationData['id_informasi'] = _selectedInfoId!;
      }

      // Send based on target
      if (_selectedTarget == 'all_users') {
        // Insert SINGLE broadcast notification for all users
        await _supabase.from('notification_preference').insert({
          ...notificationData,
          'is_broadcast': true,
          'target_audience': 'all_users',
          'id_user': null, // No specific user - broadcast to all
        });
      } else if (_selectedTarget == 'all_ukm') {
        // Insert SINGLE broadcast notification for all UKM
        await _supabase.from('notification_preference').insert({
          ...notificationData,
          'is_broadcast': true,
          'target_audience': 'all_ukm',
          'id_ukm': null, // No specific UKM - broadcast to all
        });
      } else if (_selectedTarget == 'specific_ukm') {
        // Insert for selected UKMs - still multiple but intentional
        for (var ukmId in _selectedUkmIds) {
          await _supabase.from('notification_preference').insert({
            ...notificationData,
            'is_broadcast': false,
            'target_audience': 'specific_ukm',
            'id_ukm': ukmId,
          });
        }
      } else if (_selectedTarget == 'specific_user') {
        // Insert for selected users - still multiple but intentional
        for (var userId in _selectedUserIds) {
          await _supabase.from('notification_preference').insert({
            ...notificationData,
            'is_broadcast': false,
            'target_audience': 'specific_user',
            'id_user': userId,
          });
        }
      }

      setState(() => _isSending = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to reload notifications
      }
    } catch (e) {
      setState(() => _isSending = false);
      print('Error sending notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim notifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black87,
            size: isMobile ? 20 : 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kirim Notifikasi',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 800 : double.infinity,
                    ),
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Card
                        Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF4169E1).withValues(alpha: 0.1),
                                const Color(0xFF4169E1).withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4169E1).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.send_rounded,
                                color: const Color(0xFF4169E1),
                                size: isMobile ? 20 : 24,
                              ),
                              SizedBox(width: isMobile ? 8 : 12),
                              Expanded(
                                child: Text(
                                  'Kirim notifikasi ke pengguna atau UKM tertentu',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 12 : 14,
                                    color: const Color(0xFF4169E1),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 24),

                        // Form Card
                        Container(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                'Judul Notifikasi',
                                'Masukkan judul notifikasi',
                                _titleController,
                                isMobile,
                              ),
                              SizedBox(height: isMobile ? 16 : 24),

                              _buildTextField(
                                'Pesan',
                                'Masukkan pesan notifikasi',
                                _messageController,
                                isMobile,
                                maxLines: 4,
                              ),
                              SizedBox(height: isMobile ? 16 : 24),

                              _buildTypeDropdown(isMobile),
                              SizedBox(height: isMobile ? 16 : 24),

                              // Conditional: Event Selection
                              if (_selectedType == 'event') ...[
                                _buildEventDropdown(isMobile),
                                SizedBox(height: isMobile ? 16 : 24),
                              ],

                              // Conditional: Info Selection
                              if (_selectedType == 'info') ...[
                                _buildInfoDropdown(isMobile),
                                SizedBox(height: isMobile ? 16 : 24),
                              ],

                              _buildTargetDropdown(isMobile),
                              SizedBox(height: isMobile ? 16 : 24),

                              // Conditional: UKM Multi-Select
                              if (_selectedTarget == 'specific_ukm')
                                _buildUkmSelection(isMobile),

                              // Conditional: User Multi-Select
                              if (_selectedTarget == 'specific_user')
                                _buildUserSelection(isMobile),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSending
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 12 : 16,
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                            SizedBox(width: isMobile ? 8 : 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSending
                                    ? null
                                    : _sendNotification,
                                icon: Icon(
                                  Icons.send,
                                  size: isMobile ? 16 : 18,
                                ),
                                label: Text(
                                  _isSending ? 'Mengirim...' : 'Kirim',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 13 : 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4169E1),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 12 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    bool isMobile, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label harus diisi';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[400],
            ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipe Notifikasi',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedType,
          decoration: InputDecoration(
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
            contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
          ),
          items: [
            _buildDropdownItem(
              'info',
              Icons.notifications,
              'Info',
              Colors.grey,
              isMobile,
            ),
            _buildDropdownItem(
              'event',
              Icons.event,
              'Event',
              const Color(0xFF4169E1),
              isMobile,
            ),
            _buildDropdownItem(
              'document',
              Icons.description,
              'Dokumen',
              Colors.orange,
              isMobile,
            ),
            _buildDropdownItem(
              'approval',
              Icons.check_circle,
              'Persetujuan',
              Colors.green,
              isMobile,
            ),
            _buildDropdownItem(
              'warning',
              Icons.warning,
              'Peringatan',
              Colors.red,
              isMobile,
            ),
            _buildDropdownItem(
              'user',
              Icons.person,
              'User',
              Colors.purple,
              isMobile,
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
              _selectedEventId = null;
              _selectedInfoId = null;
            });
          },
        ),
      ],
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(
    String value,
    IconData icon,
    String label,
    Color color,
    bool isMobile,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: isMobile ? 18 : 20),
          SizedBox(width: isMobile ? 6 : 8),
          Text(label, style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14)),
        ],
      ),
    );
  }

  Widget _buildEventDropdown(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Event',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedEventId,
          hint: Text(
            'Pilih event (opsional)',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[400],
            ),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
          ),
          items: _events.map((event) {
            return DropdownMenuItem<String>(
              value: event['id_events'],
              child: Text(
                event['nama_event'] ?? '',
                style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedEventId = value);
          },
        ),
      ],
    );
  }

  Widget _buildInfoDropdown(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Informasi',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedInfoId,
          hint: Text(
            'Pilih informasi (opsional)',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[400],
            ),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
          ),
          items: _informasi.map((info) {
            return DropdownMenuItem<String>(
              value: info['id_informasi'],
              child: Text(
                info['judul'] ?? '',
                style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedInfoId = value);
          },
        ),
      ],
    );
  }

  Widget _buildTargetDropdown(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kirim Ke',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedTarget,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
          ),
          items: [
            DropdownMenuItem(
              value: 'all_users',
              child: Text(
                'Semua Pengguna',
                style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
              ),
            ),
            DropdownMenuItem(
              value: 'all_ukm',
              child: Text(
                'Semua UKM',
                style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
              ),
            ),
            DropdownMenuItem(
              value: 'specific_ukm',
              child: Text(
                'Pilih UKM',
                style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
              ),
            ),
            DropdownMenuItem(
              value: 'specific_user',
              child: Text(
                'Pilih Pengguna',
                style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTarget = value!;
              _selectedUkmIds.clear();
              _selectedUserIds.clear();
            });
          },
        ),
      ],
    );
  }

  Widget _buildUkmSelection(bool isMobile) {
    // Filter UKM based on search query
    final filteredUkm = _ukm.where((ukm) {
      final namaUkm = (ukm['nama_ukm'] ?? '').toString().toLowerCase();
      return namaUkm.contains(_ukmSearchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih UKM (${_selectedUkmIds.length} dipilih)',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        // Search Field
        TextField(
          controller: _ukmSearchController,
          onChanged: (value) {
            setState(() {
              _ukmSearchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Cari UKM...',
            hintStyle: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[600],
              size: isMobile ? 18 : 20,
            ),
            suffixIcon: _ukmSearchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: isMobile ? 18 : 20),
                    onPressed: () {
                      setState(() {
                        _ukmSearchController.clear();
                        _ukmSearchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 10 : 12,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Container(
          constraints: BoxConstraints(maxHeight: isMobile ? 180 : 200),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: filteredUkm.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _ukmSearchQuery.isEmpty
                          ? 'Tidak ada UKM'
                          : 'UKM tidak ditemukan',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: filteredUkm.map((ukm) {
                    final isSelected = _selectedUkmIds.contains(ukm['id_ukm']);
                    return CheckboxListTile(
                      title: Text(
                        ukm['nama_ukm'] ?? '',
                        style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedUkmIds.add(ukm['id_ukm']);
                          } else {
                            _selectedUkmIds.remove(ukm['id_ukm']);
                          }
                        });
                      },
                      activeColor: const Color(0xFF4169E1),
                      dense: isMobile,
                    );
                  }).toList(),
                ),
        ),
        SizedBox(height: isMobile ? 16 : 24),
      ],
    );
  }

  Widget _buildUserSelection(bool isMobile) {
    // Filter users based on search query
    final filteredUsers = _users.where((user) {
      final username = (user['username'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final query = _userSearchQuery.toLowerCase();
      return username.contains(query) || email.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Pengguna (${_selectedUserIds.length} dipilih)',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        // Search Field
        TextField(
          controller: _userSearchController,
          onChanged: (value) {
            setState(() {
              _userSearchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Cari pengguna (nama/email)...',
            hintStyle: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[600],
              size: isMobile ? 18 : 20,
            ),
            suffixIcon: _userSearchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: isMobile ? 18 : 20),
                    onPressed: () {
                      setState(() {
                        _userSearchController.clear();
                        _userSearchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 10 : 12,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Container(
          constraints: BoxConstraints(maxHeight: isMobile ? 180 : 200),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: filteredUsers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _userSearchQuery.isEmpty
                          ? 'Tidak ada pengguna'
                          : 'Pengguna tidak ditemukan',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: filteredUsers.map((user) {
                    final isSelected = _selectedUserIds.contains(
                      user['id_user'],
                    );
                    return CheckboxListTile(
                      title: Text(
                        user['username'] ?? '',
                        style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
                      ),
                      subtitle: Text(
                        user['email'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 10 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedUserIds.add(user['id_user']);
                          } else {
                            _selectedUserIds.remove(user['id_user']);
                          }
                        });
                      },
                      activeColor: const Color(0xFF4169E1),
                      dense: isMobile,
                    );
                  }).toList(),
                ),
        ),
        SizedBox(height: isMobile ? 16 : 24),
      ],
    );
  }
}
