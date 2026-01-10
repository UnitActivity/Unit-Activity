import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';

class SendNotifikasiUKMPage extends StatefulWidget {
  const SendNotifikasiUKMPage({super.key});

  @override
  State<SendNotifikasiUKMPage> createState() => _SendNotifikasiUKMPageState();
}

class _SendNotifikasiUKMPageState extends State<SendNotifikasiUKMPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _dashboardService = UkmDashboardService();

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedType = 'info';
  String? _selectedEventId;
  String _selectedTarget = 'all_members';
  bool _isSending = false;
  bool _isLoading = true;

  String? _currentUkmId;
  String? _currentPeriodeId;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get current UKM
      final ukmDetails = await _dashboardService.getCurrentUkmDetails();
      if (ukmDetails == null) {
        throw Exception('Tidak dapat mengidentifikasi UKM');
      }

      _currentUkmId = ukmDetails['id_ukm'];

      // Get current periode
      final periode = await _dashboardService.getCurrentPeriode(_currentUkmId!);
      _currentPeriodeId = periode?['id_periode'];

      // Get UKM members (followers)
      final membersData = await _supabase
          .from('user_halaman_ukm')
          .select('*, users!inner(id_user, username, email)')
          .eq('id_ukm', _currentUkmId!)
          .eq('status', 'aktif');

      // Get events for this UKM
      final eventsData = await _supabase
          .from('events')
          .select('id_events, nama_event, status')
          .eq('id_ukm', _currentUkmId!)
          .eq('status', true)
          .order('create_at', ascending: false);

      setState(() {
        _members = List<Map<String, dynamic>>.from(membersData);
        _events = List<Map<String, dynamic>>.from(eventsData);
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

    // Validate event selection when type is event
    if (_selectedType == 'event' && _selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih event terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada anggota UKM untuk menerima notifikasi'),
          backgroundColor: Colors.orange,
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
        'id_ukm': _currentUkmId,
        'create_at': DateTime.now().toIso8601String(),
      };

      // Add event ID if type is event
      if (_selectedType == 'event' && _selectedEventId != null) {
        notificationData['id_events'] = _selectedEventId!;
      }

      // Send to all UKM members
      for (var member in _members) {
        await _supabase.from('notification_preference').insert({
          ...notificationData,
          'id_user': member['users']['id_user'],
        });
      }

      setState(() => _isSending = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Notifikasi berhasil dikirim ke ${_members.length} anggota!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error sending notification: $e');
      setState(() => _isSending = false);

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4169E1),
        title: Text(
          'Kirim Notifikasi',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kirim ke Anggota UKM',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                Text(
                                  'Notifikasi akan dikirim ke ${_members.length} anggota aktif',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type Selection
                          Text(
                            'Tipe Notifikasi',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            children: [
                              _buildTypeChip(
                                'info',
                                'Informasi',
                                Icons.info_outline,
                              ),
                              _buildTypeChip(
                                'warning',
                                'Peringatan',
                                Icons.warning_amber_outlined,
                              ),
                              _buildTypeChip(
                                'event',
                                'Event',
                                Icons.event_outlined,
                              ),
                            ],
                          ),

                          // Event Selection (only shown when type is event)
                          if (_selectedType == 'event') ...[
                            const SizedBox(height: 24),
                            Text(
                              'Pilih Event',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedEventId,
                              hint: Text(
                                'Pilih event',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4169E1),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: _events.map((event) {
                                return DropdownMenuItem<String>(
                                  value: event['id_events'],
                                  child: Text(
                                    event['nama_event'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedEventId = value);
                              },
                            ),
                          ],

                          // Target Selection
                          const SizedBox(height: 24),
                          Text(
                            'Kirim Ke',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedTarget,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4169E1),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'all_members',
                                child: Text(
                                  'Semua Anggota (${_members.length})',
                                  style: GoogleFonts.inter(fontSize: 14),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedTarget = value!);
                            },
                          ),

                          const SizedBox(height: 24),

                          // Title Field
                          Text(
                            'Judul Notifikasi',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'Masukkan judul notifikasi',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4169E1),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Judul harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Message Field
                          Text(
                            'Pesan',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Masukkan pesan notifikasi...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4169E1),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Pesan harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSending
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSending
                                      ? null
                                      : _sendNotification,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4169E1),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSending
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Kirim Notifikasi',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
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

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    Color chipColor;

    switch (type) {
      case 'warning':
        chipColor = Colors.orange;
        break;
      case 'event':
        chipColor = Colors.purple;
        break;
      default:
        chipColor = Colors.blue;
    }

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : chipColor,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = type;
          // Reset event selection when type changes
          if (type != 'event') {
            _selectedEventId = null;
          }
        });
      },
      backgroundColor: chipColor.withOpacity(0.1),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? chipColor : chipColor.withOpacity(0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
