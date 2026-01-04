import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:unit_activity/services/event_service.dart';
import 'package:unit_activity/services/auth_service.dart';
import 'package:unit_activity/models/event_model.dart';
import 'package:intl/intl.dart';

class EventUKMPage extends StatefulWidget {
  const EventUKMPage({super.key});

  @override
  State<EventUKMPage> createState() => _EventUKMPageState();
}

class _EventUKMPageState extends State<EventUKMPage> {
  int _currentPage = 1;
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();

  List<EventModel> _eventList = [];
  bool _isLoading = true;

  // Attendance data - store attendance records
  final Map<String, List<Map<String, dynamic>>> _attendanceData = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      // Load all events without UUID filter
      final events = await _eventService.getAllEvents();
      setState(() {
        _eventList = events;
        _isLoading = false;
      });
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    // Get screen height for calculating container height
    final screenHeight = MediaQuery.of(context).size.height;
    final tableHeight = screenHeight - 300; // Account for header, padding, etc.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Event',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddEventDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Tambah Event',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Table Container
        SizedBox(
          height: tableHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Checkbox(
                          value: false,
                          onChanged: (value) {},
                          activeColor: const Color(0xFF4169E1),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Nama',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Jenis Event',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'NIM',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Tanggal',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 140),
                    ],
                  ),
                ),

                // Table Body
                Expanded(
                  child: ListView.builder(
                    itemCount: _eventList.length,
                    itemBuilder: (context, index) {
                      final event = _eventList[index];
                      final tanggalStr = event.tanggalMulai != null
                          ? DateFormat('dd-MM-yyyy').format(event.tanggalMulai!)
                          : '-';
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Checkbox(
                                value: false,
                                onChanged: (value) {},
                                activeColor: const Color(0xFF4169E1),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  event.namaEvent,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  event.tipevent ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  event.lokasi ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  tanggalStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () => _showDetailDialog(event),
                                    icon: const Icon(Icons.visibility_outlined),
                                    color: const Color(0xFF4169E1),
                                    tooltip: 'Lihat Detail',
                                  ),
                                  IconButton(
                                    onPressed: () => _showDeleteDialog(event),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    tooltip: 'Hapus',
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

                // Pagination
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 1
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        color: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$_currentPage',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4169E1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentPage++;
                          });
                        },
                        icon: const Icon(Icons.chevron_right),
                        color: const Color(0xFF4169E1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddEventDialog() {
    final formKey = GlobalKey<FormState>();
    final namaEventController = TextEditingController();
    final tipeController = TextEditingController();
    final nimController = TextEditingController();
    final lokasiController = TextEditingController();
    final tanggalMulaiController = TextEditingController();
    final tanggalAkhirController = TextEditingController();
    final jamMulaiController = TextEditingController();
    final jamAkhirController = TextEditingController();
    final maxPartisipanController = TextEditingController();
    final keteranganController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tambah Event Baru',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormTextField(
                          controller: namaEventController,
                          label: 'Nama Event',
                          hint: 'Masukkan nama event',
                          icon: Icons.event,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama event harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: tipeController,
                          label: 'Tipe Event',
                          hint: 'Latihan/Pertandingan/Workshop',
                          icon: Icons.category,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Tipe event harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: nimController,
                          label: 'NIM Penyelenggara',
                          hint: 'Masukkan NIM penyelenggara',
                          icon: Icons.badge,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'NIM harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: lokasiController,
                          label: 'Lokasi',
                          hint: 'Masukkan lokasi event',
                          icon: Icons.location_on,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lokasi harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormTextField(
                                controller: tanggalMulaiController,
                                label: 'Tanggal Mulai',
                                hint: 'DD-MM-YYYY',
                                icon: Icons.calendar_today,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFormTextField(
                                controller: tanggalAkhirController,
                                label: 'Tanggal Akhir',
                                hint: 'DD-MM-YYYY',
                                icon: Icons.calendar_today,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormTextField(
                                controller: jamMulaiController,
                                label: 'Jam Mulai',
                                hint: 'HH:MM',
                                icon: Icons.access_time,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFormTextField(
                                controller: jamAkhirController,
                                label: 'Jam Akhir',
                                hint: 'HH:MM',
                                icon: Icons.access_time,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: maxPartisipanController,
                          label: 'Max Partisipan',
                          hint: 'Jumlah maksimal peserta',
                          icon: Icons.people,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Max partisipan harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: keteranganController,
                          label: 'Keterangan',
                          hint: 'Deskripsi event (opsional)',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  try {
                                    // Parse date strings to DateTime
                                    final parts1 = tanggalMulaiController.text.split('-');
                                    final tanggalMulai = DateTime(
                                      int.parse(parts1[2]), // year
                                      int.parse(parts1[1]), // month
                                      int.parse(parts1[0]), // day
                                    );
                                    
                                    final parts2 = tanggalAkhirController.text.split('-');
                                    final tanggalAkhir = DateTime(
                                      int.parse(parts2[2]),
                                      int.parse(parts2[1]),
                                      int.parse(parts2[0]),
                                    );

                                    // Create event model
                                    final newEvent = EventModel(
                                      namaEvent: namaEventController.text,
                                      tipevent: tipeController.text,
                                      lokasi: lokasiController.text,
                                      tanggalMulai: tanggalMulai,
                                      tanggalAkhir: tanggalAkhir,
                                      jamMulai: jamMulaiController.text,
                                      jamAkhir: jamAkhirController.text,
                                      idUser: nimController.text,
                                      status: true,
                                      // Note: idUkm and idPeriode should be set by database defaults/triggers
                                    );

                                    // Save to database
                                    await _eventService.createEvent(newEvent);
                                    
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Event berhasil ditambahkan'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    
                                    // Reload data
                                    _loadEvents();
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menambahkan event: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4169E1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Simpan Event',
                                style: GoogleFonts.inter(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }

  void _showDetailDialog(EventModel event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Event',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField('Nama Event', 'Sparing w/ UNKA'),
                      const SizedBox(height: 16),
                      _buildFormField('Tipe', 'Sparing'),
                      const SizedBox(height: 16),
                      _buildFormField('Lokasi', 'Lapangan Basket'),
                      const SizedBox(height: 16),
                      _buildFormField('Tanggal Mulai', '22-12-2025'),
                      const SizedBox(height: 16),
                      _buildFormField('Tanggal Akhir', '22-12-2025'),
                      const SizedBox(height: 16),
                      _buildFormField('Jam Mulai', '17:00'),
                      const SizedBox(height: 16),
                      _buildFormField('Jam Akhir', '20:00'),
                      const SizedBox(height: 16),
                      _buildFormField('Partisipan', '25'),
                      const SizedBox(height: 16),
                      _buildFormField('Max Partisipan', '30'),
                      const SizedBox(height: 16),
                      _buildFormField('Dibuat', '22-12-2025'),
                      const SizedBox(height: 16),
                      _buildFileUploadField('Proposal'),
                      const SizedBox(height: 16),
                      _buildFileUploadField('LPJ'),
                      const SizedBox(height: 16),
                      _buildFileUploadField('Logbook'),
                      const SizedBox(height: 24),
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Proposal',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'LPJ',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[400],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Logbook',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showQRCodeDialog(event);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4169E1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.qr_code, size: 18),
                                label: Text(
                                  'QR Absen',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4169E1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Simpan',
                              style: GoogleFonts.inter(
                                fontSize: 13,
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
    );
  }

  Widget _buildFormField(String label, String value) {
    return Column(
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
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadField(String label) {
    return Column(
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
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Upload File or URL',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  'Choose File',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showQRCodeDialog(EventModel event) {
    // Generate unique event ID for QR code
    final String eventId = '${event.tipevent}_${event.tanggalMulai}'
        .replaceAll(' ', '_');

    // Initialize attendance list if not exists
    if (!_attendanceData.containsKey(eventId)) {
      _attendanceData[eventId] = [];
    }

    // Parse event date and time
    final eventEndTime = event.jamAkhir ?? '23:59';
    final eventDate = DateTime(
      event.tanggalMulai!.year,
      event.tanggalMulai!.month,
      event.tanggalMulai!.day,
      int.parse(eventEndTime.split(':')[0]),
      int.parse(eventEndTime.split(':')[1]),
    );

    // Check if event has ended
    final isEventEnded = DateTime.now().isAfter(eventDate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // QR code state variables
        String qrToken = DateTime.now().millisecondsSinceEpoch.toString();
        Timer? qrTimer;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Start timer for QR code rotation
            if (!isEventEnded && qrTimer == null) {
              qrTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
                setDialogState(() {
                  qrToken = DateTime.now().millisecondsSinceEpoch.toString();
                });
              });
            }

            return WillPopScope(
              onWillPop: () async {
                qrTimer?.cancel();
                return true;
              },
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: 450,
                  constraints: const BoxConstraints(maxHeight: 700),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isEventEnded
                              ? Colors.grey[600]
                              : const Color(0xFF4169E1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isEventEnded
                                      ? Icons.event_busy
                                      : Icons.qr_code_2,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEventEnded
                                          ? 'Acara Selesai'
                                          : 'QR Code Absensi',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      event.tipevent ?? '-',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                qrTimer?.cancel();
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // QR Code Display or Event Ended Message
                              if (isEventEnded)
                                Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Acara Sudah Selesai',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Absensi ditutup pada ${DateFormat('dd-MM-yyyy').format(event.tanggalMulai!)} ${event.jamAkhir ?? ''}',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      QrImageView(
                                        data:
                                            'EVENT_ATTENDANCE:$eventId:$qrToken',
                                        version: QrVersions.auto,
                                        size: 250.0,
                                        backgroundColor: Colors.white,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Scan untuk Absensi',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Kode berubah otomatis setiap 10 detik',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Event ID: $eventId',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
                              // Manual Attendance Input (only if event not ended)
                              if (!isEventEnded)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Input Manual Kehadiran',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              decoration: InputDecoration(
                                                hintText: 'Masukkan NIM',
                                                hintStyle: GoogleFonts.inter(
                                                  fontSize: 13,
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                              ),
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                              ),
                                              onSubmitted: (nim) {
                                                if (nim.isNotEmpty) {
                                                  setDialogState(() {
                                                    _attendanceData[eventId]!
                                                        .add({
                                                          'nim': nim,
                                                          'nama':
                                                              'Peserta $nim',
                                                          'waktu':
                                                              DateTime.now()
                                                                  .toString()
                                                                  .substring(
                                                                    0,
                                                                    19,
                                                                  ),
                                                        });
                                                  });
                                                  setState(
                                                    () {},
                                                  ); // Update main state
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Simulate adding attendance
                                              final nim =
                                                  '215150200111${DateTime.now().millisecond.toString().padLeft(3, '0')}';
                                              setDialogState(() {
                                                _attendanceData[eventId]!.add({
                                                  'nim': nim,
                                                  'nama': 'Peserta $nim',
                                                  'waktu': DateTime.now()
                                                      .toString()
                                                      .substring(0, 19),
                                                });
                                              });
                                              setState(
                                                () {},
                                              ); // Update main state
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF4169E1,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              if (!isEventEnded) const SizedBox(height: 20),
                              // Attendance List
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Daftar Hadir',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF4169E1,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${_attendanceData[eventId]!.length} Hadir',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF4169E1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (_attendanceData[eventId]!.isEmpty)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            'Belum ada yang hadir',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxHeight: 150,
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount:
                                              _attendanceData[eventId]!.length,
                                          itemBuilder: (context, index) {
                                            final attendance =
                                                _attendanceData[eventId]![index];
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.grey[200]!,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[100],
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check,
                                                      size: 16,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          attendance['nama'],
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .grey[800],
                                                              ),
                                                        ),
                                                        Text(
                                                          'NIM: ${attendance['nim']}',
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    attendance['waktu']
                                                        .substring(11, 16),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Footer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                qrTimer?.cancel();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4169E1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                'Tutup',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(EventModel event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Hapus Event',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text('Yakin ingin menghapus event ${event.namaEvent}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _eventService.deleteEvent(event.idEvents!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadEvents(); // Refresh list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
