import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DetailPertemuanUKMPage extends StatefulWidget {
  final Map<String, dynamic> pertemuan;

  const DetailPertemuanUKMPage({super.key, required this.pertemuan});

  @override
  State<DetailPertemuanUKMPage> createState() => _DetailPertemuanUKMPageState();
}

class _DetailPertemuanUKMPageState extends State<DetailPertemuanUKMPage> {
  // Sample members data - replace with API data from user_halaman_ukm
  final List<Map<String, dynamic>> _membersList = [
    {'nim': '123456789', 'nama': 'Ahmad Rizki', 'status': 'Tidak Hadir'},
    {'nim': '987654321', 'nama': 'Siti Nurhaliza', 'status': 'Tidak Hadir'},
    {'nim': '456789123', 'nama': 'Budi Santoso', 'status': 'Tidak Hadir'},
    {'nim': '789123456', 'nama': 'Dewi Lestari', 'status': 'Tidak Hadir'},
    {'nim': '321654987', 'nama': 'Eko Prasetyo', 'status': 'Tidak Hadir'},
  ];

  // Track attendance by NIM
  final Map<String, bool> _attendanceData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4169E1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Pertemuan',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pertemuan['topik'],
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.pertemuan['tanggal'],
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.pertemuan['jamMulai']} - ${widget.pertemuan['jamAkhir']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.pertemuan['lokasi'],
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showQRCodeDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4169E1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.qr_code, size: 20),
                        label: Text(
                          'Tampilkan QR',
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

            const SizedBox(height: 24),

            // Attendance List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Daftar Kehadiran Anggota',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
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
                          child: Text(
                            'NIM',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Nama',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Status',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table Body
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _membersList.length,
                    itemBuilder: (context, index) {
                      final member = _membersList[index];
                      final isPresent = _attendanceData[member['nim']] ?? false;
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
                              width: 60,
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                member['nim'],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                member['nama'],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isPresent
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPresent ? 'Hadir' : 'Tidak Hadir',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isPresent
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog() {
    Timer? timer;
    String currentQRData = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Function to generate new QR code
            void generateNewQRCode() {
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final random = Random().nextInt(999999);
              final token = '$timestamp-$random';
              currentQRData =
                  'MEETING_ATTENDANCE:${widget.pertemuan['id']}:$token';
              setDialogState(() {});

              // Simulate attendance scanning - update after dialog state
              if (Random().nextDouble() > 0.7 && _membersList.isNotEmpty) {
                final unscannedMembers = _membersList
                    .where((m) => !(_attendanceData[m['nim']] ?? false))
                    .toList();
                if (unscannedMembers.isNotEmpty) {
                  final randomMember =
                      unscannedMembers[Random().nextInt(
                        unscannedMembers.length,
                      )];
                  // Use WidgetsBinding to schedule setState after build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _attendanceData[randomMember['nim']] = true;
                      });
                    }
                  });
                }
              }
            }

            // Check if meeting has ended
            bool isMeetingEnded() {
              try {
                final tanggal = widget.pertemuan['tanggal'].split('-');
                final jamAkhir = widget.pertemuan['jamAkhir'].split(':');

                final endDateTime = DateTime(
                  int.parse(tanggal[2]), // year
                  int.parse(tanggal[1]), // month
                  int.parse(tanggal[0]), // day
                  int.parse(jamAkhir[0]), // hour
                  int.parse(jamAkhir[1]), // minute
                );

                return DateTime.now().isAfter(endDateTime);
              } catch (e) {
                return false;
              }
            }

            // Initialize QR code
            if (currentQRData.isEmpty) {
              generateNewQRCode();
            }

            // Start timer to refresh QR code
            timer ??= Timer.periodic(const Duration(seconds: 10), (timer) {
              if (!isMeetingEnded()) {
                generateNewQRCode();
              }
            });

            final meetingEnded = isMeetingEnded();

            return WillPopScope(
              onWillPop: () async {
                timer?.cancel();
                return true;
              },
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'QR Code Absensi',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              timer?.cancel();
                              Navigator.pop(dialogContext);
                            },
                            icon: const Icon(Icons.close),
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // QR Code or Ended Message
                      if (meetingEnded)
                        Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red[200]!,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.red[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Pertemuan Sudah Selesai',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'QR Code tidak dapat ditampilkan',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.red[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: QrImageView(
                            data: currentQRData,
                            version: QrVersions.auto,
                            size: 300,
                            backgroundColor: Colors.white,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Info
                      if (!meetingEnded) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'QR Code akan berganti setiap 10 detik',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${widget.pertemuan['topik']}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${widget.pertemuan['tanggal']} • ${widget.pertemuan['jamMulai']} - ${widget.pertemuan['jamAkhir']}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      timer?.cancel();
    });
  }
}
