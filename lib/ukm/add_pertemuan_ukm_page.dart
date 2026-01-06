import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/services/pertemuan_service.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';
import 'package:unit_activity/models/pertemuan_model.dart';

class AddPertemuanUKMPage extends StatefulWidget {
  const AddPertemuanUKMPage({super.key});

  @override
  State<AddPertemuanUKMPage> createState() => _AddPertemuanUKMPageState();
}

class _AddPertemuanUKMPageState extends State<AddPertemuanUKMPage> {
  final _formKey = GlobalKey<FormState>();
  final PertemuanService _pertemuanService = PertemuanService();
  final UkmDashboardService _dashboardService = UkmDashboardService();

  final _topiController = TextEditingController();
  final _jamMulaiController = TextEditingController();
  final _jamAkhirController = TextEditingController();
  final _lokasiController = TextEditingController();

  DateTime? _tanggal;
  bool _sendNotification = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _topiController.dispose();
    _jamMulaiController.dispose();
    _jamAkhirController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  Future<void> _sendPertemuanNotification(
    String topik,
    String tanggal,
    String jamMulai,
    String jamAkhir,
    String lokasi,
    String ukmId,
  ) async {
    try {
      debugPrint('=== Starting notification send ===');
      debugPrint('UKM ID: $ukmId');

      final members = await _dashboardService.getUkmMembers(ukmId);
      debugPrint('Members found: ${members.length}');

      if (members.isEmpty) {
        debugPrint('No members found, skipping notification');
        return;
      }

      final now = DateTime.now().toIso8601String();
      final notificationData = members.map((member) {
        return {
          'id_user': member['id_user'],
          'judul': 'Pertemuan Baru: $topik',
          'pesan':
              'Pertemuan baru dijadwalkan pada $tanggal pukul $jamMulai - $jamAkhir di $lokasi',
          'type': 'info',
          'is_read': false,
          'id_ukm': ukmId,
          'create_at': now,
        };
      }).toList();

      debugPrint('Notification data to insert: $notificationData');

      final result = await _dashboardService.supabase
          .from('notification_preference')
          .insert(notificationData)
          .select();

      debugPrint('Insert result: $result');
      debugPrint('=== Notification send completed ===');
    } catch (e) {
      debugPrint('!!! Error sending notification: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tanggal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newPertemuan = PertemuanModel(
        topik: _topiController.text,
        tanggal: _tanggal!,
        jamMulai: _jamMulaiController.text,
        jamAkhir: _jamAkhirController.text,
        lokasi: _lokasiController.text,
      );

      await _pertemuanService.createPertemuan(newPertemuan);

      if (_sendNotification) {
        final userId = _dashboardService.supabase.auth.currentUser?.id;
        if (userId != null) {
          final userUkmResponse = await _dashboardService.supabase
              .from('user_halaman_ukm')
              .select('ukm_id')
              .eq('user_id', userId)
              .eq('is_active', true)
              .maybeSingle();

          if (userUkmResponse != null) {
            final ukmId = userUkmResponse['ukm_id'] as String;
            final formattedDate =
                '${_tanggal!.day}/${_tanggal!.month}/${_tanggal!.year}';
            await _sendPertemuanNotification(
              _topiController.text,
              formattedDate,
              _jamMulaiController.text,
              _jamAkhirController.text,
              _lokasiController.text,
              ukmId,
            );
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pertemuan "${_topiController.text}" berhasil ditambahkan!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan pertemuan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4169E1),
        title: Text(
          'Tambah Pertemuan',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                    _buildFormTextField(
                      controller: _topiController,
                      label: 'Topik Pertemuan',
                      hint: 'Masukkan topik pertemuan',
                      icon: Icons.topic,
                      isMobile: isMobile,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Topik harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildDateField(
                      label: 'Tanggal',
                      value: _tanggal,
                      isMobile: isMobile,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _tanggal ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => _tanggal = date);
                        }
                      },
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormTextField(
                            controller: _jamMulaiController,
                            label: 'Jam Mulai',
                            hint: 'HH:MM',
                            icon: Icons.access_time,
                            isMobile: isMobile,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: isMobile ? 12 : 16),
                        Expanded(
                          child: _buildFormTextField(
                            controller: _jamAkhirController,
                            label: 'Jam Akhir',
                            hint: 'HH:MM',
                            icon: Icons.access_time_filled,
                            isMobile: isMobile,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildFormTextField(
                      controller: _lokasiController,
                      label: 'Lokasi',
                      hint: 'Masukkan lokasi pertemuan',
                      icon: Icons.location_on,
                      isMobile: isMobile,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lokasi harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    CheckboxListTile(
                      title: Text(
                        'Kirim notifikasi ke anggota UKM',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      subtitle: Text(
                        'Notifikasi otomatis akan dikirim ke semua anggota aktif',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      value: _sendNotification,
                      onChanged: (bool? value) {
                        setState(() {
                          _sendNotification = value ?? true;
                        });
                      },
                      activeColor: const Color(0xFF4169E1),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 20 : 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4169E1),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
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
                                fontSize: isMobile ? 13 : 14,
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
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: isMobile ? 18 : 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  value != null
                      ? '${value.day}/${value.month}/${value.year}'
                      : 'Pilih tanggal',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    color: value != null ? Colors.grey[800] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isMobile,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(icon, size: isMobile ? 18 : 20),
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
}
