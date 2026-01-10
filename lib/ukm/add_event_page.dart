import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:unit_activity/services/event_service_new.dart';
import 'package:unit_activity/services/file_upload_service.dart';
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
  final UkmDashboardService _dashboardService = UkmDashboardService();

  // Form controllers
  final _namaEventController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _maxParticipantController = TextEditingController();

  // Form values
  String? _selectedTipeEvent;
  String? _selectedTipeAkses = 'anggota'; // 'umum' or 'anggota'
  DateTime? _tanggalMulai;
  DateTime? _tanggalAkhir;
  bool _sendNotification = true; // Auto-send notification checkbox

  // Image file
  Map<String, dynamic>? _gambarFile; // {bytes: Uint8List, name: String}
  
  // Multiple proposal files support
  final List<Map<String, dynamic>> _proposalFiles = [];
  // Each item: {bytes: Uint8List, name: String, isSubmitted: bool}

  bool _isLoading = false;
  bool _isUploadingFile = false;

  // Send notification to all UKM members
  Future<void> _sendEventNotification(String eventId, String ukmId) async {
    try {
      // Get all active UKM members
      final members = await _dashboardService.getUkmMembers(ukmId);

      if (members.isEmpty) return;

      final now = DateTime.now().toIso8601String();
      final notificationData = members.map((member) {
        return {
          'id_user': member['id_user'],
          'judul': 'Event Baru: ${_namaEventController.text}',
          'pesan':
              'Event baru telah dibuat. Deskripsi: ${_deskripsiController.text}',
          'type': 'event',
          'is_read': false,
          'id_ukm': ukmId,
          'create_at': now,
        };
      }).toList();

      // Batch insert notifications
      await _dashboardService.supabase
          .from('notification_preference')
          .insert(notificationData);
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

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

  Future<void> _pickGambarFile() async {
    try {
      setState(() => _isUploadingFile = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _gambarFile = {
            'bytes': file.bytes,
            'name': file.name,
          };
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gambar "${file.name}" berhasil dipilih'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _pickProposalFile() async {
    try {
      setState(() => _isUploadingFile = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
        allowMultiple: true, // Allow multiple files
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.bytes == null) continue;

          final fileBytes = file.bytes!;
          final fileName = file.name;

          // Validate file type
          if (!_fileUploadService.isValidProposalFileName(fileName)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Format file $fileName tidak valid. Gunakan PDF, DOC, atau DOCX',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue;
          }

          // Validate file size (max 10MB)
          final isValidSize = _fileUploadService.isValidFileSizeFromBytes(
            fileBytes,
          );
          if (!isValidSize) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File $fileName terlalu besar. Maksimal 10MB'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue;
          }

          // Add to list
          setState(() {
            _proposalFiles.add({
              'bytes': fileBytes,
              'name': fileName,
              'isSubmitted': false,
            });
          });
        }

        if (mounted && _proposalFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.files.length} file berhasil ditambahkan'),
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

  Future<void> _removeFile(int index) async {
    setState(() {
      _proposalFiles.removeAt(index);
    });
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

      // Upload gambar if selected
      String? gambarUrl;
      if (_gambarFile != null) {
        try {
          gambarUrl = await _fileUploadService.uploadImageFromBytes(
            fileBytes: _gambarFile!['bytes'],
            fileName: _gambarFile!['name'],
            folder: 'events',
          );
        } catch (e) {
          print('Error uploading image: $e');
          // Continue without image if upload fails
        }
      }

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
        gambar: gambarUrl,
        tipeAkses: _selectedTipeAkses,
      );

      final eventId = event['id_events'] as String;

      // Send notification if checkbox is checked
      if (_sendNotification && mounted) {
        await _sendEventNotification(eventId, ukmId);
      }

      // Check if there are files to submit
      if (_proposalFiles.isNotEmpty) {
        // Update proposal status to 'draft' since files are added but not submitted yet
        await _eventService.updateProposalStatus(
          eventId: eventId,
          status: 'draft',
        );

        // Show dialog to submit files now or later
        if (mounted) {
          final submitNow = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4169E1)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Event Berhasil Dibuat',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apakah Anda ingin mengajukan dokumen proposal sekarang?',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber[800],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_proposalFiles.length} dokumen siap diajukan',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.amber[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Nanti Saja',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Ya, Ajukan Sekarang',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (submitNow == true) {
            // Upload all files
            int successCount = 0;
            for (var file in _proposalFiles) {
              try {
                await _fileUploadService.uploadProposalFromBytes(
                  fileBytes: file['bytes'],
                  fileName: file['name'],
                  eventId: eventId,
                );
                successCount++;
              } catch (e) {
                print('Error uploading ${file['name']}: $e');
              }
            }

            if (successCount > 0) {
              await _eventService.updateProposalStatus(
                eventId: eventId,
                status: 'menunggu',
              );
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Event berhasil dibuat. $successCount dari ${_proposalFiles.length} dokumen berhasil diajukan',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Event berhasil dibuat. Anda dapat mengajukan dokumen nanti di halaman detail event',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
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

                  // Tipe Akses
                  _buildTipeAksesDropdown(),
                  const SizedBox(height: 20),

                  // Gambar Event
                  _buildImageUpload(),
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

                  // Send Notification Checkbox
                  CheckboxListTile(
                    title: Text(
                      'Kirim notifikasi ke anggota UKM',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    subtitle: Text(
                      'Notifikasi otomatis akan dikirim ke semua anggota aktif',
                      style: GoogleFonts.inter(
                        fontSize: 12,
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
          initialValue: _selectedTipeEvent,
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

  Widget _buildTipeAksesDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipe Akses Event',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedTipeAkses,
          decoration: InputDecoration(
            hintText: 'Pilih tipe akses',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
            prefixIcon: Icon(Icons.public, size: 20, color: Colors.grey[600]),
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
          items: [
            DropdownMenuItem(
              value: 'anggota',
              child: Text('Khusus Anggota UKM', style: GoogleFonts.inter(fontSize: 14)),
            ),
            DropdownMenuItem(
              value: 'umum',
              child: Text('Terbuka untuk Umum', style: GoogleFonts.inter(fontSize: 14)),
            ),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _selectedTipeAkses = newValue;
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedTipeAkses == 'umum'
                    ? 'Event dapat dilihat dan diikuti oleh semua user'
                    : 'Hanya anggota UKM yang dapat melihat dan mengikuti event ini',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gambar Event (Opsional)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        if (_gambarFile != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.image, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _gambarFile!['name'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Gambar siap diupload',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () {
                    setState(() {
                      _gambarFile = null;
                    });
                  },
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _isUploadingFile ? null : _pickGambarFile,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Klik untuk upload gambar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Format: JPG, PNG (Maks. 5MB)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upload Proposal (Opsional)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (_proposalFiles.isNotEmpty)
              Text(
                '${_proposalFiles.length} file',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF4169E1),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Upload button
        InkWell(
          onTap: _isUploadingFile ? null : _pickProposalFile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _proposalFiles.isNotEmpty
                    ? const Color(0xFF4169E1)
                    : Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.upload_file,
                  color: _proposalFiles.isNotEmpty
                      ? const Color(0xFF4169E1)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _proposalFiles.isEmpty
                            ? 'Pilih file PDF, DOC, atau DOCX'
                            : 'Tambah file lainnya',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _proposalFiles.isNotEmpty
                              ? const Color(0xFF4169E1)
                              : Colors.grey[600],
                          fontWeight: _proposalFiles.isNotEmpty
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        'Maksimal 10MB per file • Bisa pilih beberapa file sekaligus',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: _proposalFiles.isNotEmpty
                      ? const Color(0xFF4169E1)
                      : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),

        // List of selected files
        if (_proposalFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(_proposalFiles.length, (index) {
            final file = _proposalFiles[index];
            final isSubmitted = file['isSubmitted'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSubmitted ? Colors.green[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSubmitted ? Colors.green[200]! : Colors.blue[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSubmitted ? Icons.check_circle : Icons.description,
                    color: isSubmitted ? Colors.green[700] : Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file['name'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSubmitted ? 'Sudah diajukan' : 'Belum diajukan',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isSubmitted
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSubmitted) ...[
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeFile(index),
                      color: Colors.grey[600],
                      tooltip: 'Hapus file',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            );
          }),

          // Info text
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[800], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'File akan diajukan setelah event dibuat. Anda juga bisa mengajukan nanti.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
