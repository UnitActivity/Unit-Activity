import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/countdown_helper.dart';

class EditPeriodePage extends StatefulWidget {
  final Map<String, dynamic> periode;

  const EditPeriodePage({super.key, required this.periode});

  @override
  State<EditPeriodePage> createState() => _EditPeriodePageState();
}

class _EditPeriodePageState extends State<EditPeriodePage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  late TextEditingController _namaPeriodeController;
  late TextEditingController _semesterController;
  late TextEditingController _tahunController;

  // Periode timestamps
  DateTime? _tanggalAwal;
  TimeOfDay? _waktuAwal;
  DateTime? _tanggalAkhir;
  TimeOfDay? _waktuAkhir;

  // Registration timestamps
  bool _isRegistrationOpen = false;
  DateTime? _registrationStartDate;
  TimeOfDay? _registrationStartTime;
  DateTime? _registrationEndDate;
  TimeOfDay? _registrationEndTime;

  String _status = 'draft';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _namaPeriodeController = TextEditingController(
      text: widget.periode['nama_periode'] ?? '',
    );
    _semesterController = TextEditingController(
      text: widget.periode['semester'] ?? '',
    );
    _tahunController = TextEditingController(
      text: widget.periode['tahun'] ?? '',
    );

    // Parse periode timestamps (tanggal_awal is timestamp not date)
    if (widget.periode['tanggal_awal'] != null) {
      final dt = DateTime.parse(widget.periode['tanggal_awal']);
      _tanggalAwal = dt;
      _waktuAwal = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (widget.periode['tanggal_akhir'] != null) {
      final dt = DateTime.parse(widget.periode['tanggal_akhir']);
      _tanggalAkhir = dt;
      _waktuAkhir = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }

    // Parse registration timestamps
    _isRegistrationOpen = widget.periode['is_registration_open'] ?? false;

    if (widget.periode['registration_start_date'] != null) {
      final dt = DateTime.parse(widget.periode['registration_start_date']);
      _registrationStartDate = dt;
      _registrationStartTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (widget.periode['registration_end_date'] != null) {
      final dt = DateTime.parse(widget.periode['registration_end_date']);
      _registrationEndDate = dt;
      _registrationEndTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }

    _status = widget.periode['status'] ?? 'draft';
  }

  @override
  void dispose() {
    _namaPeriodeController.dispose();
    _semesterController.dispose();
    _tahunController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime? initialDate;
    switch (type) {
      case 'periode_start':
        initialDate = _tanggalAwal ?? DateTime.now();
        break;
      case 'periode_end':
        initialDate = _tanggalAkhir ?? DateTime.now();
        break;
      case 'reg_start':
        initialDate = _registrationStartDate ?? DateTime.now();
        break;
      case 'reg_end':
        initialDate = _registrationEndDate ?? DateTime.now();
        break;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate!,
      firstDate: DateTime(2020),
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

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'periode_start':
            _tanggalAwal = picked;
            break;
          case 'periode_end':
            _tanggalAkhir = picked;
            break;
          case 'reg_start':
            _registrationStartDate = picked;
            break;
          case 'reg_end':
            _registrationEndDate = picked;
            break;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    TimeOfDay? initialTime;
    switch (type) {
      case 'periode_start':
        initialTime = _waktuAwal ?? TimeOfDay.now();
        break;
      case 'periode_end':
        initialTime = _waktuAkhir ?? TimeOfDay.now();
        break;
      case 'reg_start':
        initialTime = _registrationStartTime ?? TimeOfDay.now();
        break;
      case 'reg_end':
        initialTime = _registrationEndTime ?? TimeOfDay.now();
        break;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime!,
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

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'periode_start':
            _waktuAwal = picked;
            break;
          case 'periode_end':
            _waktuAkhir = picked;
            break;
          case 'reg_start':
            _registrationStartTime = picked;
            break;
          case 'reg_end':
            _registrationEndTime = picked;
            break;
        }
      });
    }
  }

  Future<void> _updatePeriode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
    if (regStart != null && regEnd != null && regEnd.isBefore(regStart)) {
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

    setState(() => _isSaving = true);

    try {
      // Calculate is_registration_open based on current time
      bool isRegOpen = false;
      if (regStart != null && regEnd != null) {
        final now = DateTime.now();
        isRegOpen = now.isAfter(regStart) && now.isBefore(regEnd);
      }

      final updateData = {
        'nama_periode': _namaPeriodeController.text.trim(),
        'semester': _semesterController.text.trim(),
        'tahun': _tahunController.text.trim(),
        'tanggal_awal': periodeStart.toIso8601String(),
        'tanggal_akhir': periodeEnd.toIso8601String(),
        'status': _status,
        'is_registration_open': isRegOpen,
        'registration_start_date': regStart?.toIso8601String(),
        'registration_end_date': regEnd?.toIso8601String(),
      };

      await _supabase
          .from('periode_ukm')
          .update(updateData)
          .eq('id_periode', widget.periode['id_periode']);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Periode berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui periode: $e'),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Edit Periode',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Nama Periode
            TextFormField(
              controller: _namaPeriodeController,
              decoration: InputDecoration(
                labelText: 'Nama Periode',
                hintText: 'Contoh: 2025.1',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama periode harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Semester & Tahun
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _semesterController,
                    decoration: InputDecoration(
                      labelText: 'Semester',
                      hintText: 'Ganjil/Genap',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tahunController,
                    decoration: InputDecoration(
                      labelText: 'Tahun',
                      hintText: '2025',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tanggal Awal & Waktu
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, 'periode_start'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Awal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      child: Text(
                        _tanggalAwal != null
                            ? CountdownHelper.formatDate(_tanggalAwal!)
                            : 'Pilih tanggal',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, 'periode_start'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Waktu Awal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(
                        _waktuAwal != null
                            ? _waktuAwal!.format(context)
                            : 'Pilih waktu',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tanggal Akhir & Waktu
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, 'periode_end'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Akhir',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      child: Text(
                        _tanggalAkhir != null
                            ? CountdownHelper.formatDate(_tanggalAkhir!)
                            : 'Pilih tanggal',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, 'periode_end'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Waktu Akhir',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(
                        _waktuAkhir != null
                            ? _waktuAkhir!.format(context)
                            : 'Pilih waktu',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Divider
            const Divider(thickness: 1),
            const SizedBox(height: 16),

            // Section Header - Pendaftaran UKM
            Row(
              children: [
                const Icon(
                  Icons.how_to_reg,
                  size: 20,
                  color: Color(0xFF4169E1),
                ),
                const SizedBox(width: 8),
                Text(
                  'Jadwal Pendaftaran UKM',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Opsional - Tentukan waktu buka dan tutup pendaftaran',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Tanggal Buka Pendaftaran
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, 'reg_start'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Buka',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.event_available,
                          color: Colors.green,
                        ),
                      ),
                      child: Text(
                        _registrationStartDate != null
                            ? CountdownHelper.formatDate(
                                _registrationStartDate!,
                              )
                            : 'Pilih tanggal',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, 'reg_start'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Waktu Buka',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(
                        _registrationStartTime != null
                            ? _registrationStartTime!.format(context)
                            : 'Pilih waktu',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tanggal Tutup Pendaftaran
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, 'reg_end'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Tutup',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.event_busy,
                          color: Colors.red,
                        ),
                      ),
                      child: Text(
                        _registrationEndDate != null
                            ? CountdownHelper.formatDate(_registrationEndDate!)
                            : 'Pilih tanggal',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, 'reg_end'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Waktu Tutup',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(
                        _registrationEndTime != null
                            ? _registrationEndTime!.format(context)
                            : 'Pilih waktu',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Dropdown
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Status Periode',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF4169E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4169E1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updatePeriode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
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
                            'Simpan Perubahan',
                            style: GoogleFonts.inter(
                              fontSize: 16,
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
    );
  }
}
