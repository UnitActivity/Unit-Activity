import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddPeriodePage extends StatefulWidget {
  const AddPeriodePage({super.key});

  @override
  State<AddPeriodePage> createState() => _AddPeriodePageState();
}

class _AddPeriodePageState extends State<AddPeriodePage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _namaPeriodeController = TextEditingController();
  DateTime? _tanggalAwal;
  DateTime? _tanggalAkhir;
  bool _isSaving = false;

  @override
  void dispose() {
    _namaPeriodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_tanggalAwal ?? DateTime.now())
          : (_tanggalAkhir ?? DateTime.now()),
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
        if (isStartDate) {
          _tanggalAwal = picked;
        } else {
          _tanggalAkhir = picked;
        }
      });
    }
  }

  String? _validatePeriodeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama periode harus diisi';
    }

    // Validate format: YYYY.N (e.g., 2025.1, 2024.2)
    final regex = RegExp(r'^\d{4}\.[12]$');
    if (!regex.hasMatch(value.trim())) {
      return 'Format harus YYYY.1 atau YYYY.2 (contoh: 2025.1)';
    }

    return null;
  }

  Future<void> _savePeriode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tanggalAwal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal awal harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tanggalAkhir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal akhir harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tanggalAkhir!.isBefore(_tanggalAwal!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal akhir harus setelah tanggal awal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final namaPeriode = _namaPeriodeController.text.trim();

      // Extract tahun and semester from nama_periode (e.g., "2025.1")
      final parts = namaPeriode.split('.');
      final tahun = parts[0]; // "2025"
      final semesterNum = parts[1]; // "1" or "2"
      final semester = semesterNum == '1' ? 'Ganjil' : 'Genap';

      // Determine status based on current date
      final now = DateTime.now();
      final status =
          now.isAfter(_tanggalAwal!) || now.isAtSameMomentAs(_tanggalAwal!)
          ? 'Active'
          : 'Non Active';

      await _supabase.from('periode_ukm').insert({
        'nama_periode': namaPeriode,
        'semester': semester,
        'tahun': tahun,
        'tanggal_awal': _tanggalAwal!.toIso8601String(),
        'tanggal_akhir': _tanggalAkhir!.toIso8601String(),
        'status': status,
        'create_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Periode berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
          'Tambah Periode',
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
                            'Format nama periode: YYYY.1 untuk semester ganjil, YYYY.2 untuk semester genap',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 12 : 14,
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
                          onTap: () => _selectDate(context, true),
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
                                      : DateFormat(
                                          'dd-MM-yyyy',
                                        ).format(_tanggalAwal!),
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
                          onTap: () => _selectDate(context, false),
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
                                      : DateFormat(
                                          'dd-MM-yyyy',
                                        ).format(_tanggalAkhir!),
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
