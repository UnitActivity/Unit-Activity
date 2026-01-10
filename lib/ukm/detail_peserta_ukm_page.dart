import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DetailPesertaUKMPage extends StatefulWidget {
  final Map<String, dynamic> peserta;
  final String ukmId;
  final String periodeId;

  const DetailPesertaUKMPage({
    super.key,
    required this.peserta,
    required this.ukmId,
    required this.periodeId,
  });

  @override
  State<DetailPesertaUKMPage> createState() => _DetailPesertaUKMPageState();
}

class _DetailPesertaUKMPageState extends State<DetailPesertaUKMPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _attendanceHistory = [];
  Map<String, dynamic>? _attendanceStats;

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() => _isLoadingHistory = true);

    try {
      final userId = widget.peserta['id_user'];

      // PERBAIKAN 1: Ambil total pertemuan dan event yang TERJADWAL di UKM ini terlebih dahulu
      // Ini menjadi angka "penyebut" (contoh: angka 4 di 0/4)
      
      // Ambil total pertemuan UKM
      final totalPertemuanUKMResponse = await _supabase
          .from('pertemuan') // Pastikan nama tabel ini sesuai di DB Anda (misal 'pertemuans' atau 'pertemuan')
          .select('id_pertemuan')
          .eq('id_ukm', widget.ukmId)
          .eq('id_periode', widget.periodeId);

      // Ambil total event UKM
      final totalEventUKMResponse = await _supabase
          .from('events') // Menggunakan 'events' sesuai perbaikan error sebelumnya
          .select('id_events')
          .eq('id_ukm', widget.ukmId);

      final totalPertemuanUKM = (totalPertemuanUKMResponse as List).length;
      final totalEventUKM = (totalEventUKMResponse as List).length;

      // PERBAIKAN 2: Load attendance history untuk user ini
      // Ini menjadi angka "pembilang" (berapa kali dia hadir)
      
      final pertemuanResponse = await _supabase
          .from('absen_pertemuan')
          .select('id_pertemuan, id_user, jam')
          .eq('id_user', userId);

      final eventResponse = await _supabase
          .from('absen_event')
          .select('id_event, id_user, jam')
          .eq('id_user', userId);

      final List<Map<String, dynamic>> combinedHistory = [];

      // Add pertemuan with details
      for (var item in pertemuanResponse as List) {
        try {
          final pertemuanId = item['id_pertemuan'];
          final pertemuanDetail = await _supabase
              .from('pertemuan')
              .select('judul, tanggal, deskripsi')
              .eq('id_pertemuan', pertemuanId)
              .maybeSingle();
          
          if (pertemuanDetail != null) {
            combinedHistory.add({
              'type': 'Pertemuan',
              'judul': pertemuanDetail['judul'] ?? '-',
              'tanggal': pertemuanDetail['tanggal'],
              'deskripsi': pertemuanDetail['deskripsi'],
              'waktu_absen': pertemuanDetail['tanggal'],
              'metode': 'hadir',
              'jam': item['jam'] ?? '-',
            });
          }
        } catch (e) {
          debugPrint('Error loading pertemuan detail: $e');
        }
      }

      // Add events with details
      for (var item in eventResponse as List) {
        try {
          final eventId = item['id_event'];
          final eventDetail = await _supabase
              .from('events')
              .select('nama_event, tanggal_mulai, deskripsi')
              .eq('id_events', eventId)
              .maybeSingle();
          
          if (eventDetail != null) {
            combinedHistory.add({
              'type': 'Event',
              'judul': eventDetail['nama_event'] ?? '-',
              'tanggal': eventDetail['tanggal_mulai'],
              'deskripsi': eventDetail['deskripsi'],
              'waktu_absen': eventDetail['tanggal_mulai'],
              'metode': 'hadir',
              'jam': item['jam'] ?? '-',
            });
          }
        } catch (e) {
          debugPrint('Error loading event detail: $e');
        }
      }

      // Sort by waktu_absen
      combinedHistory.sort((a, b) {
        final aTime = DateTime.parse(a['waktu_absen'].toString());
        final bTime = DateTime.parse(b['waktu_absen'].toString());
        return bTime.compareTo(aTime);
      });

      // Calculate stats
      // Hitung berapa yang DIIKUTI (hanya yang ada di tabel absen)
      final pertemuanDiikuti = (pertemuanResponse as List).length;
      final eventDiikuti = (eventResponse as List).length;
      final totalKehadiran = pertemuanDiikuti + eventDiikuti;

      setState(() {
        _attendanceHistory = combinedHistory;
        _attendanceStats = {
          'total_kehadiran': totalKehadiran,
          'pertemuan_diikuti': pertemuanDiikuti,
          'event_diikuti': eventDiikuti,
          // Gunakan variabel yang diambil di awal (totalPertemuanUKM)
          'total_pertemuan_ukm': totalPertemuanUKM, 
          'total_event_ukm': totalEventUKM,
          // Hitung persentase berdasarkan total yang TERJADWAL
          'persentase_kehadiran': totalPertemuanUKM > 0
              ? ((pertemuanDiikuti / totalPertemuanUKM) * 100).round()
              : 0,
        };
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('Error loading attendance history: $e');
      setState(() => _isLoadingHistory = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat riwayat kehadiran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Detail Peserta',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(isMobile),
              const SizedBox(height: 24),
              _buildStatsCards(isMobile),
              const SizedBox(height: 24),
              _buildLogbookEligibility(isMobile),
              const SizedBox(height: 24),
              _buildAttendanceHistory(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isMobile) {
    final peserta = widget.peserta;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
        children: [
          CircleAvatar(
            radius: isMobile ? 40 : 50,
            backgroundColor: const Color(0xFF4169E1).withOpacity(0.1),
            child: Text(
              (peserta['nama'] ?? 'U')[0].toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: isMobile ? 32 : 40,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4169E1),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            peserta['nama'] ?? '-',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(peserta['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(peserta['status']),
                width: 1,
              ),
            ),
            child: Text(
              peserta['status'] ?? '-',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(peserta['status']),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          _buildDetailGrid(isMobile),
        ],
      ),
    );
  }

  Widget _buildDetailGrid(bool isMobile) {
    final peserta = widget.peserta;

    final details = [
      {
        'icon': Icons.badge,
        'label': 'NIM',
        'value': peserta['nim']?.toString() ?? '-',
      },
      {
        'icon': Icons.email,
        'label': 'Email',
        'value': peserta['email']?.toString() ?? '-',
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Tanggal Bergabung',
        'value': _formatDate(peserta['tanggal']),
      },
      if (peserta['deskripsi'] != null)
        {
          'icon': Icons.description,
          'label': 'Deskripsi',
          'value': peserta['deskripsi'].toString(),
        },
    ];

    return Column(
      children: details.map((detail) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  detail['icon'] as IconData,
                  size: 20,
                  color: const Color(0xFF4169E1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail['value'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCards(bool isMobile) {
    if (_isLoadingHistory || _attendanceStats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _attendanceStats!;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.3 : 1.5,
      children: [
        _buildStatCard(
          'Total Kehadiran',
          stats['total_kehadiran'].toString(),
          Icons.check_circle_outline,
          const Color(0xFF4169E1),
          isMobile,
        ),
        _buildStatCard(
          'Pertemuan',
          '${stats['pertemuan_diikuti']}/${stats['total_pertemuan_ukm']}',
          Icons.groups,
          Colors.green,
          isMobile,
        ),
        _buildStatCard(
          'Event',
          '${stats['event_diikuti']}/${stats['total_event_ukm']}',
          Icons.event,
          Colors.orange,
          isMobile,
        ),
        _buildStatCard(
          'Persentase',
          '${stats['persentase_kehadiran']}%',
          Icons.percent,
          Colors.purple,
          isMobile,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 24),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 10 : 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLogbookEligibility(bool isMobile) {
    if (_isLoadingHistory || _attendanceStats == null) {
      return const SizedBox.shrink();
    }

    final stats = _attendanceStats!;
    final persentase = stats['persentase_kehadiran'] as int;
    final isEligible = persentase >= 80;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEligible
              ? [const Color(0xFF4169E1), const Color(0xFF6B8FFF)]
              : [Colors.grey[400]!, Colors.grey[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isEligible ? const Color(0xFF4169E1) : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEligible ? Icons.check_circle : Icons.lock,
                  color: Colors.white,
                  size: isMobile ? 28 : 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Klaim Logbook',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEligible
                          ? 'Memenuhi syarat untuk klaim logbook'
                          : 'Belum memenuhi syarat klaim logbook',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Persentase Kehadiran',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$persentase%',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: persentase / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isEligible ? Colors.white : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isEligible ? Icons.check_circle : Icons.info,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEligible
                            ? 'Selamat! Anda dapat mengklaim logbook'
                            : 'Minimal 80% kehadiran diperlukan untuk klaim logbook',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.white.withOpacity(0.9),
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
    );
  }

  Widget _buildAttendanceHistory(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          Row(
            children: [
              Icon(
                Icons.history,
                color: const Color(0xFF4169E1),
                size: isMobile ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Riwayat Kehadiran',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_attendanceHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada riwayat kehadiran',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attendanceHistory.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = _attendanceHistory[index];
                return _buildHistoryItem(item, isMobile);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, bool isMobile) {
    final isPertemuan = item['type'] == 'Pertemuan';
    final color = isPertemuan ? const Color(0xFF4169E1) : Colors.orange;
    final icon = isPertemuan ? Icons.groups : Icons.event;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['judul'],
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item['type'],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (item['deskripsi'] != null) ...[
                Text(
                  item['deskripsi'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(item['tanggal']),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(item['waktu_absen']),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (item['metode'] != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      item['metode'] == 'qr'
                          ? Icons.qr_code
                          : Icons.add_box_outlined,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['metode'] == 'qr' ? 'QR Code' : 'Manual',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'aktif':
      case 'active':
        return Colors.green;
      case 'nonaktif':
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final DateTime parsedDate = DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return date.toString();
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '-';
    try {
      final DateTime parsedTime = DateTime.parse(time.toString());
      return DateFormat('HH:mm').format(parsedTime);
    } catch (e) {
      return time.toString();
    }
  }
}