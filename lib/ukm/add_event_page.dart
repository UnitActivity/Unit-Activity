import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:unit_activity/services/event_service_new.dart';
import 'package:unit_activity/services/file_upload_service.dart';
import 'package:unit_activity/services/custom_auth_service.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();
  final FileUploadService _fileUploadService = FileUploadService();
  final CustomAuthService _authService = CustomAuthService();
  final UkmDashboardService _dashboardService = UkmDashboardService();

  // Form controllers
  final _namaEventController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _maxParticipantController = TextEditingController();

  // Form values
  String? _selectedTipeEvent;
  DateTime? _tanggalMulai;
  DateTime? _tanggalAkhir;
  Uint8List? _proposalFileBytes;
  String? _proposalFileName;

  bool _isLoading = false;
  bool _isUploadingFile = false;

  final List<String> _tipeEventOptions = [
    'Internal',
    'Eksternal',
    'Kompetisi',
    'Workshop',
    'Seminar',
    'Gathering',
    'Lainnya',
  ];

  @override
  void dispose() {
    _namaEventController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _maxParticipantController.dispose();
    super.dispose();
  }

  Future<void> _pickProposalFile() async {
    try {
      setState(() => _isUploadingFile = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true, // Important for web platform
      );

      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        // Validate file type
        if (!_fileUploadService.isValidProposalFileName(fileName)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Format file tidak valid. Gunakan PDF, DOC, atau DOCX',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Validate file size (max 10MB)
        final isValidSize = _fileUploadService.isValidFileSizeFromBytes(
          fileBytes,
        );
        if (!isValidSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ukuran file terlalu besar. Maksimal 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _proposalFileBytes = fileBytes;
          _proposalFileName = fileName;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File dipilih: $_proposalFileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tanggalMulai == null || _tanggalAkhir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal mulai dan akhir harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tanggalAkhir!.isBefore(_tanggalMulai!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal akhir tidak boleh sebelum tanggal mulai'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current UKM ID
      final ukmId = await _dashboardService.getCurrentUkmId();
      if (ukmId == null) {
        throw Exception('Tidak dapat mengidentifikasi UKM');
      }

      // Get current periode
      final periode = await _dashboardService.getCurrentPeriode(ukmId);
      if (periode == null) {
        throw Exception('Tidak ada periode aktif');
      }
      final periodeId = periode['id_periode'] as String;

      // Create event
      final event = await _eventService.createEvent(
        namaEvent: _namaEventController.text,
        deskripsi: _deskripsiController.text,
        tanggalMulai: _tanggalMulai!,
        tanggalAkhir: _tanggalAkhir!,
        lokasi: _lokasiController.text,
        maxParticipant: int.parse(_maxParticipantController.text),
        tipevent: _selectedTipeEvent!,
        ukmId: ukmId,
        periodeId: periodeId,
      );

      // Upload proposal if selected
      if (_proposalFileBytes != null && _proposalFileName != null) {
        final eventId = event['id_events'] as String;
        await _fileUploadService.uploadProposalFromBytes(
          fileBytes: _proposalFileBytes!,
          fileName: _proposalFileName!,
          eventId: eventId,
        );

        // Update proposal status
        await _eventService.updateProposalStatus(
          eventId: eventId,
          status: 'menunggu',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error saving event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Tambah Event Baru',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Event
                  _buildTextField(
                    controller: _namaEventController,
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
                  const SizedBox(height: 20),

                  // Deskripsi
                  _buildTextField(
                    controller: _deskripsiController,
                    label: 'Deskripsi',
                    hint: 'Deskripsi event',
                    icon: Icons.description,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Deskripsi harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Tipe Event
                  _buildDropdown(),
                  const SizedBox(height: 20),

                  // Tanggal
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Tanggal Mulai',
                          value: _tanggalMulai,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _tanggalMulai ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() => _tanggalMulai = date);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          label: 'Tanggal Akhir',
                          value: _tanggalAkhir,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  _tanggalAkhir ??
                                  _tanggalMulai ??
                                  DateTime.now(),
                              firstDate: _tanggalMulai ?? DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() => _tanggalAkhir = date);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lokasi
                  _buildTextField(
                    controller: _lokasiController,
                    label: 'Lokasi',
                    hint: 'Lokasi event',
                    icon: Icons.location_on,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lokasi harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Max Participant
                  _buildTextField(
                    controller: _maxParticipantController,
                    label: 'Maksimal Peserta',
                    hint: 'Jumlah maksimal peserta',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Maksimal peserta harus diisi';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Harus berupa angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Upload Proposal
                  _buildFileUpload(),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
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
                        onPressed: _isLoading ? null : _saveEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4169E1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
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
      ),
    );
  }

  Widget _buildTextField({
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipe Event',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedTipeEvent,
          decoration: InputDecoration(
            hintText: 'Pilih tipe event',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
            prefixIcon: Icon(Icons.category, size: 20, color: Colors.grey[600]),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: _tipeEventOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: GoogleFonts.inter(fontSize: 14)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedTipeEvent = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Tipe event harus dipilih';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  value != null
                      ? '${value.day}/${value.month}/${value.year}'
                      : 'Pilih tanggal',
                  style: GoogleFonts.inter(
                    fontSize: 14,
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

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Proposal (Opsional)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isUploadingFile ? null : _pickProposalFile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _proposalFileBytes != null
                    ? const Color(0xFF4169E1)
                    : Colors.grey[300]!,
                width: _proposalFileBytes != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _proposalFileBytes != null
                      ? Icons.check_circle
                      : Icons.upload_file,
                  color: _proposalFileBytes != null
                      ? const Color(0xFF4169E1)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _proposalFileName ?? 'Pilih file PDF, DOC, atau DOCX',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _proposalFileBytes != null
                              ? Colors.grey[800]
                              : Colors.grey[600],
                          fontWeight: _proposalFileBytes != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (_proposalFileBytes == null)
                        Text(
                          'Maksimal 10MB',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_proposalFileBytes != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _proposalFileBytes = null;
                        _proposalFileName = null;
                      });
                    },
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
