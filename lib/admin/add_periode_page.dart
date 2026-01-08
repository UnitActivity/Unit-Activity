import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/countdown_helper.dart';

class AddPeriodePage extends StatefulWidget {
  const AddPeriodePage({super.key});

  @override
  State<AddPeriodePage> createState() => _AddPeriodePageState();
}

class _AddPeriodePageState extends State<AddPeriodePage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _namaPeriodeController = TextEditingController();

  // Periode akademik timestamps
  DateTime? _tanggalAwal;
  TimeOfDay? _waktuAwal;
  DateTime? _tanggalAkhir;
  TimeOfDay? _waktuAkhir;

  // Registration timestamps
  DateTime? _registrationStartDate;
  TimeOfDay? _registrationStartTime;
  DateTime? _registrationEndDate;
  TimeOfDay? _registrationEndTime;

  final String _status = 'draft';
  bool _isSaving = false;

  @override
  void dispose() {
    _namaPeriodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, String type) async {
    // Select Date first
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4169E1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    // Select Time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4169E1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      switch (type) {
        case 'periode_start':
          _tanggalAwal = pickedDate;
          _waktuAwal = pickedTime;
          break;
        case 'periode_end':
          _tanggalAkhir = pickedDate;
          _waktuAkhir = pickedTime;
          break;
        case 'reg_start':
          _registrationStartDate = pickedDate;
          _registrationStartTime = pickedTime;
          break;
        case 'reg_end':
          _registrationEndDate = pickedDate;
          _registrationEndTime = pickedTime;
          break;
      }
    });
  }

  String? _validatePeriodeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama periode harus diisi';
    }

    // Validate format: YYYY.N (e.g., 2025.1, 2026.2)
    final regex = RegExp(r'^\d{4}\.[12]$');
    if (!regex.hasMatch(value.trim())) {
      return 'Format harus YYYY.1 atau YYYY.2 (contoh: 2026.1)';
    }

    return null;
  }

  Future<void> _savePeriode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate periode timestamps
    if (_tanggalAwal == null || _waktuAwal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal dan waktu mulai periode harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tanggalAkhir == null || _waktuAkhir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal dan waktu selesai periode harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Combine date and time untuk periode
    final periodeStart = CountdownHelper.combineDateAndTime(
      _tanggalAwal!,
      _waktuAwal!.hour,
      _waktuAwal!.minute,
    );

    final periodeEnd = CountdownHelper.combineDateAndTime(
      _tanggalAkhir!,
      _waktuAkhir!.hour,
      _waktuAkhir!.minute,
    );

    if (periodeEnd.isBefore(periodeStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu selesai tidak boleh sebelum waktu mulai'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Combine registration timestamps (optional)
    DateTime? regStart;
    DateTime? regEnd;
    bool isRegOpen = false;

    if (_registrationStartDate != null && _registrationStartTime != null) {
      regStart = CountdownHelper.combineDateAndTime(
        _registrationStartDate!,
        _registrationStartTime!.hour,
        _registrationStartTime!.minute,
      );
    }

    if (_registrationEndDate != null && _registrationEndTime != null) {
      regEnd = CountdownHelper.combineDateAndTime(
        _registrationEndDate!,
        _registrationEndTime!.hour,
        _registrationEndTime!.minute,
      );
    }

    // Validate registration dates
    if (regStart != null && regEnd != null) {
      if (regEnd.isBefore(regStart)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Waktu tutup pendaftaran tidak boleh sebelum waktu buka',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if registration currently open
      isRegOpen = CountdownHelper.isRegistrationOpen(regStart, regEnd);
    }

    setState(() => _isSaving = true);

    try {
      final namaPeriode = _namaPeriodeController.text.trim();

      // Extract tahun and semester from nama_periode
      final parts = namaPeriode.split('.');
      final tahun = parts[0];
      final semesterNum = parts[1];
      final semester = semesterNum == '1' ? 'Ganjil' : 'Genap';

      // Check for existing active periode
      final activeCheck = await _supabase
          .from('periode_ukm')
          .select('id_periode')
          .eq('status', 'aktif')
          .maybeSingle();

      // Calculate auto-status based on dates
      final now = DateTime.now();
      String finalStatus;

      if (now.isBefore(periodeStart)) {
        finalStatus = 'draft';
      } else if (now.isAfter(periodeEnd)) {
        finalStatus = 'selesai';
      } else {
        finalStatus = 'aktif';
      }

      // Force to draft if there's already an active periode
      bool forcedToDraft = false;
      if (activeCheck != null && finalStatus == 'aktif') {
        finalStatus = 'draft';
        forcedToDraft = true;
      }

      await _supabase.from('periode_ukm').insert({
        'nama_periode': namaPeriode,
        'semester': semester,
        'tahun': tahun,
        'tanggal_awal': periodeStart.toIso8601String(),
        'tanggal_akhir': periodeEnd.toIso8601String(),
        'status': finalStatus,
        'is_registration_open': isRegOpen,
        'registration_start_date': regStart?.toIso8601String(),
        'registration_end_date': regEnd?.toIso8601String(),
        'create_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              forcedToDraft
                  ? 'Periode berhasil ditambahkan sebagai draft karena sudah ada periode aktif'
                  : 'Periode berhasil ditambahkan dengan status $finalStatus!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan periode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
          'Tambah Periode Akademik',
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
      body: Form(
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
                      color: const Color(0xFF4169E1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4169E1).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFF4169E1),
                          size: isMobile ? 20 : 24,
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: Text(
                            'Format nama: YYYY.1 (Ganjil) atau YYYY.2 (Genap)\\nContoh: 2026.1 untuk Semester Ganjil 2026',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 11 : 13,
                              color: const Color(0xFF4169E1),
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama Periode
                        Text(
                          'Nama Periode',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        TextFormField(
                          controller: _namaPeriodeController,
                          validator: _validatePeriodeName,
                          decoration: InputDecoration(
                            hintText: 'Contoh: 2025.1',
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
                              borderSide: const BorderSide(
                                color: Color(0xFF4169E1),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 24),

                        // Tanggal Awal
                        Text(
                          'Tanggal Awal',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        InkWell(
                          onTap: () =>
                              _selectDateTime(context, 'periode_start'),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey[600],
                                  size: isMobile ? 18 : 20,
                                ),
                                SizedBox(width: isMobile ? 8 : 12),
                                Text(
                                  _tanggalAwal == null
                                      ? 'Pilih tanggal awal'
                                      : CountdownHelper.formatDate(
                                          _tanggalAwal!,
                                        ),
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 12 : 14,
                                    color: _tanggalAwal == null
                                        ? Colors.grey[400]
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 24),

                        // Tanggal Akhir
                        Text(
                          'Tanggal Akhir',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        InkWell(
                          onTap: () => _selectDateTime(context, 'periode_end'),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey[600],
                                  size: isMobile ? 18 : 20,
                                ),
                                SizedBox(width: isMobile ? 8 : 12),
                                Text(
                                  _tanggalAkhir == null
                                      ? 'Pilih tanggal akhir'
                                      : CountdownHelper.formatDate(
                                          _tanggalAkhir!,
                                        ),
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 12 : 14,
                                    color: _tanggalAkhir == null
                                        ? Colors.grey[400]
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 24),

                        // Divider
                        Divider(color: Colors.grey[300], thickness: 1),
                        SizedBox(height: isMobile ? 16 : 24),

                        // Section Header - Pendaftaran UKM
                        Row(
                          children: [
                            Icon(
                              Icons.how_to_reg,
                              size: isMobile ? 18 : 20,
                              color: const Color(0xFF4169E1),
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Jadwal Pendaftaran UKM',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 13 : 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        Text(
                          'Opsional - Tentukan waktu buka dan tutup pendaftaran',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        // Tanggal Buka Pendaftaran
                        Text(
                          'Buka Pendaftaran',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        InkWell(
                          onTap: () => _selectDateTime(context, 'reg_start'),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  color: Colors.green[600],
                                  size: isMobile ? 18 : 20,
                                ),
                                SizedBox(width: isMobile ? 8 : 12),
                                Text(
                                  _registrationStartDate == null
                                      ? 'Pilih tanggal buka pendaftaran'
                                      : CountdownHelper.formatDateTime(
                                          CountdownHelper.combineDateAndTime(
                                            _registrationStartDate!,
                                            _registrationStartTime?.hour ?? 0,
                                            _registrationStartTime?.minute ?? 0,
                                          ),
                                        ),
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 12 : 14,
                                    color: _registrationStartDate == null
                                        ? Colors.grey[400]
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 24),

                        // Tanggal Tutup Pendaftaran
                        Text(
                          'Tutup Pendaftaran',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        InkWell(
                          onTap: () => _selectDateTime(context, 'reg_end'),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  color: Colors.red[600],
                                  size: isMobile ? 18 : 20,
                                ),
                                SizedBox(width: isMobile ? 8 : 12),
                                Text(
                                  _registrationEndDate == null
                                      ? 'Pilih tanggal tutup pendaftaran'
                                      : CountdownHelper.formatDateTime(
                                          CountdownHelper.combineDateAndTime(
                                            _registrationEndDate!,
                                            _registrationEndTime?.hour ?? 0,
                                            _registrationEndTime?.minute ?? 0,
                                          ),
                                        ),
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 12 : 14,
                                    color: _registrationEndDate == null
                                        ? Colors.grey[400]
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
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
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _savePeriode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4169E1),
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  height: isMobile ? 18 : 20,
                                  width: isMobile ? 18 : 20,
                                  child: const CircularProgressIndicator(
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
          ),
        ),
      ),
    );
  }
}
