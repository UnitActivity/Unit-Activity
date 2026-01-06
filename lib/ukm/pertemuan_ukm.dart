import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/ukm/detail_pertemuan_ukm.dart';
import 'package:unit_activity/ukm/add_pertemuan_ukm_page.dart';
import 'package:unit_activity/services/pertemuan_service.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';
import 'package:unit_activity/models/pertemuan_model.dart';
import 'package:intl/intl.dart';

class PertemuanUKMPage extends StatefulWidget {
  const PertemuanUKMPage({super.key});

  @override
  State<PertemuanUKMPage> createState() => _PertemuanUKMPageState();
}

class _PertemuanUKMPageState extends State<PertemuanUKMPage> {
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final PertemuanService _pertemuanService = PertemuanService();
  final UkmDashboardService _dashboardService = UkmDashboardService();

  List<PertemuanModel> _pertemuanList = [];
  bool _isLoading = true;

  // Calculate total pages based on data length
  int get _totalPages {
    if (_pertemuanList.isEmpty) return 0;
    return (_pertemuanList.length / _itemsPerPage).ceil();
  }

  // Get paginated data for current page
  List<PertemuanModel> get _paginatedPertemuan {
    if (_pertemuanList.isEmpty) return [];
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex >= _pertemuanList.length) return [];
    return _pertemuanList.sublist(
      startIndex,
      endIndex > _pertemuanList.length ? _pertemuanList.length : endIndex,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPertemuan();
  }

  Future<void> _loadPertemuan() async {
    setState(() => _isLoading = true);
    try {
      // Load all pertemuan without UUID filter
      final pertemuan = await _pertemuanService.getAllPertemuan();
      setState(() {
        _pertemuanList = pertemuan;
        _currentPage = 1; // Reset to first page
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
    final screenHeight = MediaQuery.of(context).size.height;
    final tableHeight = screenHeight - 300;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pertemuan Rutin',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _loadPertemuan,
                        icon: const Icon(Icons.refresh),
                        color: const Color(0xFF4169E1),
                        tooltip: 'Refresh',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToAddPertemuan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4169E1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(
                            'Tambah',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pertemuan Rutin',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _loadPertemuan,
                      icon: const Icon(Icons.refresh),
                      color: const Color(0xFF4169E1),
                      tooltip: 'Refresh',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _navigateToAddPertemuan,
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
                        'Tambah Pertemuan',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                return Column(
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
                            width: 60,
                            child: isMobile
                                ? Icon(
                                    Icons.tag,
                                    size: 18,
                                    color: Colors.grey[700],
                                  )
                                : Text(
                                    'No.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: isMobile
                                  ? Icon(
                                      Icons.event,
                                      size: 18,
                                      color: Colors.grey[700],
                                    )
                                  : Text(
                                      'Pertemuan',
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
                              child: isMobile
                                  ? Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: Colors.grey[700],
                                    )
                                  : Text(
                                      'Tanggal',
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
                              child: isMobile
                                  ? Icon(
                                      Icons.access_time,
                                      size: 18,
                                      color: Colors.grey[700],
                                    )
                                  : Text(
                                      'Jam',
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
                      child: _paginatedPertemuan.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_note,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada pertemuan',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _paginatedPertemuan.length,
                              itemBuilder: (context, index) {
                                final pertemuan = _paginatedPertemuan[index];
                                final actualIndex =
                                    (_currentPage - 1) * _itemsPerPage + index;
                                final tanggalStr = pertemuan.tanggal != null
                                    ? DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(pertemuan.tanggal!)
                                    : '-';

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          '${actualIndex + 1}',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Text(
                                            pertemuan.topik ??
                                                'Pertemuan ${index + 1}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
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
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Text(
                                            '${pertemuan.jamMulai ?? '-'} - ${pertemuan.jamAkhir ?? '-'}',
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                // Convert model to map for detail page
                                                final pertemuanMap = {
                                                  'id': pertemuan.idPertemuan,
                                                  'topik': pertemuan.topik,
                                                  'tanggal': tanggalStr,
                                                  'jamMulai':
                                                      pertemuan.jamMulai,
                                                  'jamAkhir':
                                                      pertemuan.jamAkhir,
                                                  'lokasi': pertemuan.lokasi,
                                                };
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        DetailPertemuanUKMPage(
                                                          pertemuan:
                                                              pertemuanMap,
                                                        ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.visibility_outlined,
                                              ),
                                              color: const Color(0xFF4169E1),
                                              tooltip: 'Lihat Detail',
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _showDeleteDialog(pertemuan),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
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
                    if (_pertemuanList.isNotEmpty && _totalPages > 1)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Menampilkan ${(_currentPage - 1) * _itemsPerPage + 1} - ${(_currentPage * _itemsPerPage) > _pertemuanList.length ? _pertemuanList.length : (_currentPage * _itemsPerPage)} dari ${_pertemuanList.length}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            Row(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF4169E1,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF4169E1,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '$_currentPage / $_totalPages',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF4169E1),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _currentPage < _totalPages
                                      ? () {
                                          setState(() {
                                            _currentPage++;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                  color: const Color(0xFF4169E1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Send notification to all UKM members
  Future<void> _sendPertemuanNotification(
    String topik,
    String tanggal,
    String jamMulai,
    String jamAkhir,
    String lokasi,
    String ukmId,
  ) async {
    try {
      // Get all active UKM members
      final members = await _dashboardService.getUkmMembers(ukmId);

      if (members.isEmpty) return;

      final now = DateTime.now().toIso8601String();
      final notificationData = members.map((member) {
        return {
          'user_id': member['id_user'],
          'judul': 'Pertemuan Baru: $topik',
          'isi':
              'Pertemuan baru dijadwalkan pada $tanggal pukul $jamMulai - $jamAkhir di $lokasi',
          'tipe': 'info',
          'is_read': false,
          'created_at': now,
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

  Future<void> _navigateToAddPertemuan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPertemuanUKMPage()),
    );

    if (result == true) {
      _loadPertemuan();
    }
  }

  void _showAddPertemuanDialog() {
    final formKey = GlobalKey<FormState>();
    final topiController = TextEditingController();
    final tanggalController = TextEditingController();
    final jamMulaiController = TextEditingController();
    final jamAkhirController = TextEditingController();
    final lokasiController = TextEditingController();
    bool sendNotification = true; // Auto-send notification checkbox

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        'Tambah Pertemuan Baru',
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormTextField(
                            controller: topiController,
                            label: 'Topik Pertemuan',
                            hint: 'Pertemuan 1',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Topik harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFormTextField(
                            controller: tanggalController,
                            label: 'Tanggal',
                            hint: 'DD-MM-YYYY',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tanggal harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormTextField(
                                  controller: jamMulaiController,
                                  label: 'Jam Mulai',
                                  hint: 'HH:MM',
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
                            controller: lokasiController,
                            label: 'Lokasi',
                            hint: 'Ruang UKM',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Lokasi harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                            value: sendNotification,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                sendNotification = value ?? true;
                              });
                            },
                            activeColor: const Color(0xFF4169E1),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 24),
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
                                      // Parse date string to DateTime
                                      final parts = tanggalController.text
                                          .split('-');
                                      final tanggal = DateTime(
                                        int.parse(parts[2]), // year
                                        int.parse(parts[1]), // month
                                        int.parse(parts[0]), // day
                                      );

                                      // Create pertemuan model
                                      final newPertemuan = PertemuanModel(
                                        topik: topiController.text,
                                        tanggal: tanggal,
                                        jamMulai: jamMulaiController.text,
                                        jamAkhir: jamAkhirController.text,
                                        lokasi: lokasiController.text,
                                        // Note: idUkm and idPeriode should be set by database defaults/triggers
                                        // or fetched from a proper source with valid UUIDs
                                      );

                                      // Save to database
                                      await _pertemuanService.createPertemuan(
                                        newPertemuan,
                                      );

                                      // Send notification if checkbox is checked
                                      if (sendNotification) {
                                        // Get UKM ID from session
                                        final userId = _dashboardService
                                            .supabase
                                            .auth
                                            .currentUser
                                            ?.id;
                                        if (userId != null) {
                                          final userUkmResponse =
                                              await _dashboardService.supabase
                                                  .from('user_halaman_ukm')
                                                  .select('ukm_id')
                                                  .eq('user_id', userId)
                                                  .eq('is_active', true)
                                                  .maybeSingle();

                                          if (userUkmResponse != null) {
                                            final ukmId =
                                                userUkmResponse['ukm_id']
                                                    as String;
                                            await _sendPertemuanNotification(
                                              topiController.text,
                                              tanggalController.text,
                                              jamMulaiController.text,
                                              jamAkhirController.text,
                                              lokasiController.text,
                                              ukmId,
                                            );
                                          }
                                        }
                                      }

                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Pertemuan "${topiController.text}" berhasil ditambahkan!',
                                            style: GoogleFonts.inter(),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      // Reload data
                                      _loadPertemuan();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gagal menambahkan pertemuan: $e',
                                          ),
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
                                  'Simpan',
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
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
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

  void _showDeleteDialog(PertemuanModel pertemuan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Hapus Pertemuan',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text('Yakin ingin menghapus ${pertemuan.topik}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _pertemuanService.deletePertemuan(pertemuan.idPertemuan!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pertemuan berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadPertemuan(); // Refresh list
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
