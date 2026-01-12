import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:unit_activity/services/dynamic_qr_service.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';
import 'package:unit_activity/services/dynamic_qr_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPertemuanUKMPage extends StatefulWidget {
  final Map<String, dynamic> pertemuan;

  const DetailPertemuanUKMPage({super.key, required this.pertemuan});

  @override
  State<DetailPertemuanUKMPage> createState() => _DetailPertemuanUKMPageState();
}

class _DetailPertemuanUKMPageState extends State<DetailPertemuanUKMPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _dashboardService = UkmDashboardService();
  late TabController _tabController;

  List<Map<String, dynamic>> _membersList = [];
  List<Map<String, dynamic>> _filteredMembersList = [];
  bool _isLoadingMembers = true;
  final TextEditingController _searchController = TextEditingController();

  // QR Code state
  String? _currentQRCode;
  DateTime? _qrExpiresAt;
  bool _isQRActive = false;
  bool _autoRegenerateQR = true;
  Timer? _qrTimer;

  // Track attendance by user ID
  final Map<String, bool> _attendanceData = {};

  // Check if meeting is completed
  bool get _isMeetingCompleted {
    if (widget.pertemuan['isCompleted'] != null) {
      return widget.pertemuan['isCompleted'] as bool;
    }
    // Fallback: check from tanggalRaw
    final tanggalRaw = widget.pertemuan['tanggalRaw'];
    if (tanggalRaw != null) {
      try {
        final meetingDate = DateTime.parse(tanggalRaw);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final meeting = DateTime(
          meetingDate.year,
          meetingDate.month,
          meetingDate.day,
        );
        return meeting.isBefore(today);
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMembers();
    
    // Start auto-regenerate timer if active
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isQRActive && _autoRegenerateQR && _qrExpiresAt != null) {
        if (DateTime.now().isAfter(_qrExpiresAt!)) {
          _generateQRCode();
        }
      }
    });
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ... (rest of _loadMembers and _filterMembers unchanged) ...

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);

    try {
      final ukmDetails = await _dashboardService.getCurrentUkmDetails();
      if (ukmDetails != null) {
        final ukmId = ukmDetails['id_ukm'];

        // Get members with their details from users table
        final response = await _supabase
            .from('user_halaman_ukm')
            .select('id_user, users(id_user, username, email, nim)')
            .eq('id_ukm', ukmId)
            .or(
              'status.eq.aktif,status.eq.active',
            ); // Accept both 'aktif' and 'active'

        // Also load attendance data for this pertemuan
        final attendanceResponse = await _supabase
            .from('absen_pertemuan')
            .select('id_user')
            .eq('id_pertemuan', widget.pertemuan['id']);

        final attendedUserIds = (attendanceResponse as List)
            .map((e) => e['id_user'] as String)
            .toSet();

        setState(() {
          _membersList = (response as List).map((item) {
            final user = item['users'] as Map<String, dynamic>?;
            final userId = item['id_user'] as String;
            final isPresent = attendedUserIds.contains(userId);
            _attendanceData[userId] = isPresent;
            return {
              'id_user': userId,
              'nim': user?['nim']?.toString() ?? 'N/A',
              'nama': user?['username'] ?? 'Unknown',
              'email': user?['email'] ?? '-',
            };
          }).toList();
          _filteredMembersList = _membersList;
          _isLoadingMembers = false;
        });
      } else {
        setState(() => _isLoadingMembers = false);
      }
    } catch (e) {
      debugPrint('Error loading members: $e');
      setState(() => _isLoadingMembers = false);
    }
  }

  void _filterMembers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMembersList = _membersList;
      } else {
        _filteredMembersList = _membersList.where((m) {
          final nama = m['nama'].toString().toLowerCase();
          final nim = m['nim'].toString().toLowerCase();
          return nama.contains(query.toLowerCase()) ||
              nim.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _generateQRCode() async {
    final qrCode = DynamicQRService.generatePertemuanQR(widget.pertemuan['id']);

    if (mounted) {
      setState(() {
        _currentQRCode = qrCode;
        _qrExpiresAt = DateTime.now().add(Duration(seconds: DynamicQRService.validityWindow));
        _isQRActive = true;
      });
    }
  }

  int get _presentCount => _attendanceData.values.where((v) => v).length;

  int get _absentCount => _attendanceData.values.where((v) => !v).length;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isMobile),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  _buildInfoCard(isMobile),
                  const SizedBox(height: 20),

                  // Stats Cards
                  _buildStatsCards(isMobile),
                  const SizedBox(height: 20),

                  // Tab Bar
                  _buildTabBar(),
                ],
              ),
            ),
          ),

          // Tab View Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [_buildKehadiranTab(isMobile), _buildQRTab(isMobile)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isMobile) {
    return SliverAppBar(
      expandedHeight: isMobile ? 150 : 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF4169E1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Detail Pertemuan',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.event_note_rounded,
                        size: isMobile ? 32 : 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.pertemuan['topik'] ?? 'Pertemuan',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildInfoCard(bool isMobile) {
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Color(0xFF4169E1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Informasi Pertemuan',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Tanggal',
            widget.pertemuan['tanggal'] ?? '-',
            isMobile,
          ),
          _buildInfoRow(
            Icons.access_time_rounded,
            'Waktu',
            '${widget.pertemuan['jamMulai'] ?? '-'} - ${widget.pertemuan['jamAkhir'] ?? '-'}',
            isMobile,
          ),
          _buildInfoRow(
            Icons.location_on_rounded,
            'Lokasi',
            widget.pertemuan['lokasi'] ?? '-',
            isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    bool isMobile,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: isMobile ? 16 : 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Anggota',
            '${_membersList.length}',
            Icons.people_rounded,
            const Color(0xFF4169E1),
            isMobile,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Hadir',
            '$_presentCount',
            Icons.check_circle_rounded,
            Colors.green,
            isMobile,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tidak Hadir',
            '$_absentCount',
            Icons.cancel_rounded,
            Colors.red,
            isMobile,
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: isMobile ? 24 : 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF4169E1),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF4169E1),
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
        tabs: const [
          Tab(text: 'Kehadiran', icon: Icon(Icons.people_rounded, size: 20)),
          Tab(text: 'QR Absensi', icon: Icon(Icons.qr_code_rounded, size: 20)),
        ],
      ),
    );
  }

  Widget _buildKehadiranTab(bool isMobile) {
    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: _filterMembers,
              decoration: InputDecoration(
                hintText: 'Cari nama atau NIM...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4169E1)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Members List
            if (_isLoadingMembers)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredMembersList.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredMembersList.length,
                itemBuilder: (context, index) => _buildMemberCard(
                  _filteredMembersList[index],
                  index,
                  isMobile,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(
    Map<String, dynamic> member,
    int index,
    bool isMobile,
  ) {
    final userId = member['id_user'] as String;
    final isPresent = _attendanceData[userId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
          width: isPresent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: isMobile ? 18 : 22,
            backgroundColor: isPresent
                ? Colors.green.withOpacity(0.1)
                : const Color(0xFF4169E1).withOpacity(0.1),
            child: Text(
              (member['nama'] ?? 'U')[0].toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: isPresent ? Colors.green : const Color(0xFF4169E1),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['nama'] ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIM: ${member['nim']}',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 14,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: isPresent ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPresent ? 'Hadir' : 'Tidak Hadir',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRTab(bool isMobile) {
    // Check if meeting is completed
    if (_isMeetingCompleted) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 32 : 48),
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_clock_rounded,
                  size: 80,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sesi Absen Sudah Ditutup!',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Pertemuan ini telah selesai. QR code absensi tidak dapat dibuat untuk pertemuan yang sudah lewat.',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Lihat data kehadiran pada tab Kehadiran',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Container(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Color(0xFF4169E1),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Code Absensi',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'QR code berganti setiap 10 detik',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isQRActive && _currentQRCode != null) ...[
              // Show QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4169E1), width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: QrImageView(
                        data: _currentQRCode!,
                        version: QrVersions.auto,
                        size: isMobile ? 180 : 220,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'QR Code Aktif',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (_qrExpiresAt != null)
                      TweenAnimationBuilder<int>(
                        key: ValueKey(_currentQRCode),
                        tween: IntTween(begin: 10, end: 0),
                        duration: const Duration(seconds: 10),
                        builder: (context, value, child) {
                          if (value == 0) {
                            Future.microtask(() async {
                              if (mounted && _autoRegenerateQR) {
                                await _generateQRCode();
                              } else {
                                setState(() {
                                  _isQRActive = false;
                                  _currentQRCode = null;
                                  _qrExpiresAt = null;
                                });
                              }
                            });
                          }
                          return Column(
                            children: [
                              const SizedBox(height: 12),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: CircularProgressIndicator(
                                      value: value / 10,
                                      strokeWidth: 6,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        value <= 3
                                            ? Colors.red
                                            : const Color(0xFF4169E1),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$value',
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: value <= 3
                                          ? Colors.red
                                          : const Color(0xFF4169E1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                value <= 3
                                    ? 'QR baru dalam $value detik'
                                    : 'Berlaku $value detik lagi',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: value <= 3
                                      ? Colors.red
                                      : Colors.grey[600],
                                  fontWeight: value <= 3
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isQRActive = false;
                      _currentQRCode = null;
                      _qrExpiresAt = null;
                    });
                  },
                  icon: const Icon(Icons.stop_rounded),
                  label: Text(
                    'Stop QR Code',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Generate button
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Klik tombol di bawah untuk generate QR Code',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateQRCode,
                  icon: const Icon(Icons.qr_code_rounded),
                  label: Text(
                    'Generate QR Code',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Peserta scan QR untuk absensi kehadiran',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada anggota',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anggota yang follow UKM akan muncul di sini',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
