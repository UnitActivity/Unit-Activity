import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/countdown_helper.dart';
import 'add_periode_page.dart';
import 'edit_periode_page.dart';

class PeriodePage extends StatefulWidget {
  const PeriodePage({super.key});

  @override
  State<PeriodePage> createState() => _PeriodePageState();
}

class _PeriodePageState extends State<PeriodePage> {
  final _supabase = Supabase.instance.client;

  final String _sortBy = 'Urutkan';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 8;

  List<Map<String, dynamic>> _allPeriode = [];
  bool _isLoading = true;
  int _totalPeriode = 0;

  @override
  void initState() {
    super.initState();
    _loadPeriode();
  }

  Future<void> _loadPeriode() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('periode_ukm')
          .select('''
            id_periode, nama_periode, semester, tahun, 
            tanggal_awal, tanggal_akhir, status, create_at,
            is_registration_open, registration_start_date, registration_end_date
          ''')
          .order('create_at', ascending: false);

      final allPeriode = List<Map<String, dynamic>>.from(response);

      // Auto-update is_registration_open based on current time
      for (var periode in allPeriode) {
        if (periode['registration_start_date'] != null &&
            periode['registration_end_date'] != null) {
          final regStart = DateTime.parse(periode['registration_start_date']);
          final regEnd = DateTime.parse(periode['registration_end_date']);
          final now = DateTime.now();

          // Calculate current registration status
          final shouldBeOpen = now.isAfter(regStart) && now.isBefore(regEnd);
          final currentStatus = periode['is_registration_open'] ?? false;

          // Update database if status changed
          if (shouldBeOpen != currentStatus) {
            await _supabase
                .from('periode_ukm')
                .update({'is_registration_open': shouldBeOpen})
                .eq('id_periode', periode['id_periode']);

            // Update local data
            periode['is_registration_open'] = shouldBeOpen;
          }
        }
      }

      setState(() {
        _allPeriode = allPeriode;
        _totalPeriode = _allPeriode.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading periode: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredPeriode {
    var periode = _allPeriode.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item['nama_periode'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    return periode;
  }

  int get _totalPages {
    return (_filteredPeriode.length / _itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> get _paginatedPeriode {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredPeriode.sublist(
      startIndex,
      endIndex > _filteredPeriode.length ? _filteredPeriode.length : endIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Modern Header with Gradient
        SizedBox(height: isMobile ? 24 : 24),
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, const Color(0xFF4169E1).withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4169E1).withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periode UKM',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 18 : (isDesktop ? 24 : 20),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      'Kelola periode akademik UKM',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Stats Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 16,
                  vertical: isMobile ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4169E1).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      color: const Color(0xFF4169E1),
                      size: isMobile ? 16 : 18,
                    ),
                    SizedBox(width: isMobile ? 4 : 6),
                    Text(
                      '$_totalPeriode Periode',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4169E1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),

        // Search and Actions Bar
        _buildModernSearchBar(isDesktop, isMobile),
        SizedBox(height: isMobile ? 16 : 24),

        // Loading or Content
        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat data periode...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_filteredPeriode.isEmpty)
          _buildEmptyState()
        else if (isDesktop)
          _buildModernDesktopCards()
        else
          _buildModernMobileCards(),

        const SizedBox(height: 24),

        // Modern Pagination
        if (!_isLoading && _filteredPeriode.isNotEmpty)
          _buildModernPagination(),
      ],
    );
  }

  Widget _buildModernSearchBar(bool isDesktop, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 1;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari periode...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Add Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPeriodePage(),
                      ),
                    );
                    if (result == true) {
                      _loadPeriode();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Tambah Periode',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari periode...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[400],
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPeriodePage(),
                        ),
                      );
                      if (result == true) {
                        _loadPeriode();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Tambah Periode',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum Ada Periode'
                  : 'Periode Tidak Ditemukan',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Silakan tambah periode UKM baru'
                  : 'Coba kata kunci lain',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDesktopCards() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.8,
      ),
      itemCount: _paginatedPeriode.length,
      itemBuilder: (context, index) {
        final periode = _paginatedPeriode[index];
        return _buildPeriodeCard(periode, true);
      },
    );
  }

  Widget _buildModernMobileCards() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedPeriode.length,
      itemBuilder: (context, index) {
        final periode = _paginatedPeriode[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPeriodeCard(periode, false),
        );
      },
    );
  }

  Widget _buildPeriodeCard(Map<String, dynamic> periode, bool isDesktop) {
    final statusStr = periode['status']?.toString().toLowerCase() ?? 'draft';
    final isActive = statusStr == 'aktif';
    final isDraft = statusStr == 'draft';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isDraft) {
      statusColor = Colors.grey;
      statusText = 'Draft';
      statusIcon = Icons.edit_note;
    } else if (isActive) {
      statusColor = Colors.green;
      statusText = 'Aktif';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.grey;
      statusText = 'Selesai';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      constraints: BoxConstraints(
        minHeight: isDesktop ? 320 : 350, // TAMBAHKAN MINIMUM HEIGHT
      ),
      padding: EdgeInsets.all(isDesktop ? 20 : 16),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, statusColor.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isDesktop ? 8 : 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withOpacity(0.8),
                                statusColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: isDesktop ? 18 : 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            periode['nama_periode'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: isDesktop ? 18 : 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            statusText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action Buttons
              if (isDesktop)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start Button (for draft or selesai)
                    if (!isActive && periode['status'] != 'selesai')
                      IconButton(
                        onPressed: () => _startPeriode(periode),
                        icon: const Icon(Icons.play_circle_outlined),
                        color: Colors.green[700],
                        tooltip: 'Mulai Periode',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green[50],
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    if (!isActive && periode['status'] != 'selesai')
                      const SizedBox(width: 8),
                    // Stop Button (only for aktif)
                    if (isActive)
                      IconButton(
                        onPressed: () => _stopPeriode(periode),
                        icon: const Icon(Icons.stop_circle_outlined),
                        color: Colors.orange[700],
                        tooltip: 'Hentikan Periode',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange[50],
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    if (isActive) const SizedBox(width: 8),
                    // Edit Button
                    IconButton(
                      onPressed: () => _editPeriode(periode),
                      icon: const Icon(Icons.edit_outlined),
                      color: const Color(0xFF4169E1),
                      tooltip: 'Edit Periode',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    IconButton(
                      onPressed: () => _deletePeriode(periode),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: Colors.red[400],
                      tooltip: 'Hapus Periode',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                )
              else
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'start':
                        _startPeriode(periode);
                        break;
                      case 'stop':
                        _stopPeriode(periode);
                        break;
                      case 'edit':
                        _editPeriode(periode);
                        break;
                      case 'delete':
                        _deletePeriode(periode);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isActive && periode['status'] != 'selesai')
                      PopupMenuItem(
                        value: 'start',
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outlined,
                              size: 18,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            const Text('Mulai Periode'),
                          ],
                        ),
                      ),
                    if (isActive)
                      PopupMenuItem(
                        value: 'stop',
                        child: Row(
                          children: [
                            Icon(
                              Icons.stop_circle_outlined,
                              size: 18,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 8),
                            const Text('Hentikan Periode'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF4169E1),
                          ),
                          const SizedBox(width: 8),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 8),
                          const Text('Hapus'),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 12),

          // Period Details
          _buildInfoChip(
            icon: Icons.event_outlined,
            label: 'Semester',
            value: '${periode['semester'] ?? '-'} ${periode['tahun'] ?? '-'}',
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.play_arrow_rounded,
                  label: 'Mulai',
                  value: _formatDate(periode['tanggal_awal']),
                  isDesktop: isDesktop,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.stop_rounded,
                  label: 'Selesai',
                  value: _formatDate(periode['tanggal_akhir']),
                  isDesktop: isDesktop,
                ),
              ),
            ],
          ),

          // Countdown Pendaftaran UKM
          if (periode['registration_start_date'] != null &&
              periode['registration_end_date'] != null) ...[
            const SizedBox(height: 12),
            _buildCountdownSection(periode, isDesktop),
          ],
          // const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildCountdownSection(Map<String, dynamic> periode, bool isDesktop) {
    final regStart = periode['registration_start_date'] != null
        ? DateTime.parse(periode['registration_start_date'])
        : null;
    final regEnd = periode['registration_end_date'] != null
        ? DateTime.parse(periode['registration_end_date'])
        : null;

    if (regStart == null || regEnd == null) {
      return const SizedBox.shrink();
    }

    final status = CountdownHelper.getRegistrationStatus(regStart, regEnd);

    Color statusColor;
    String statusText;
    String countdownMessage;
    IconData statusIcon;

    switch (status) {
      case RegistrationStatus.belumDibuka:
        statusColor = const Color(0xFF4169E1); // Royal Blue tema
        statusText = 'Belum Dibuka';
        final countdown = CountdownHelper.getCountdownText(regStart);
        countdownMessage = 'Pendaftaran akan dibuka dalam $countdown';
        statusIcon = Icons.schedule;
        break;
      case RegistrationStatus.dibuka:
        statusColor = Colors.green[600]!;
        statusText = 'Dibuka';
        final countdown = CountdownHelper.getCountdownText(regEnd);
        countdownMessage = 'Pendaftaran akan berakhir dalam $countdown';
        statusIcon = Icons.check_circle;
        break;
      case RegistrationStatus.ditutup:
        statusColor = Colors.grey[600]!;
        statusText = 'Ditutup';
        countdownMessage = 'Pendaftaran telah ditutup';
        statusIcon = Icons.cancel;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: isDesktop ? 18 : 16, color: statusColor),
              const SizedBox(width: 8),
              Text(
                'Pendaftaran UKM',
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 12 : 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 10 : 8,
              vertical: isDesktop ? 5 : 4,
            ),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: isDesktop ? 14 : 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 11 : 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Countdown Message
          Text(
            countdownMessage,
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 12 : 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          // Tanggal Buka & Tutup
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buka',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      CountdownHelper.formatDateTimeShort(regStart),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tutup',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      CountdownHelper.formatDateTimeShort(regEnd),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    bool isDesktop = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: isDesktop ? 18 : 16, color: const Color(0xFF4169E1)),
          SizedBox(width: isDesktop ? 10 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 12 : 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isDesktop ? 3 : 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedPeriode.length,
      itemBuilder: (context, index) {
        final periode = _paginatedPeriode[index];
        final isActive = periode['status'] == 'Active';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left: Periode Info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${periode['semester'] ?? '-'} ${periode['tahun'] ?? '-'}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? Colors.green : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isActive ? 'Aktif' : 'Selesai',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${periode['nama_periode'] ?? '-'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Middle: Dates
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDateInfo(
                        'Tanggal Awal',
                        _formatDate(periode['tanggal_awal']),
                        Icons.calendar_today,
                        const Color(0xFF4169E1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateInfo(
                        'Tanggal Akhir',
                        _formatDate(periode['tanggal_akhir']),
                        Icons.event,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Created & Actions
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Dibuat',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(periode['create_at']),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _deletePeriode(periode),
                      icon: const Icon(Icons.delete_outline),
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
    );
  }

  Widget _buildDateInfo(String label, String date, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedPeriode.length,
      itemBuilder: (context, index) {
        final periode = _paginatedPeriode[index];
        final isActive = periode['status'] == 'Active';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with checkbox and title
              Row(
                children: [
                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${periode['semester'] ?? '-'} ${periode['tahun'] ?? '-'}',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'Aktif' : 'Selesai',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // More button
                  IconButton(
                    onPressed: () => _deletePeriode(periode),
                    icon: const Icon(Icons.more_vert),
                    color: Colors.grey[400],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Dates section
              Row(
                children: [
                  // Tanggal Awal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Awal',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: const Color(0xFF4169E1),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _formatDate(periode['tanggal_awal']),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Tanggal Akhir
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Akhir',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _formatDate(periode['tanggal_akhir']),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
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
              const SizedBox(height: 16),

              // Footer
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'Dibuat: ${_formatDate(periode['create_at'])}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ID: ${periode['nama_periode'] ?? '-'}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
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
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Results Info - Mobile
                Text(
                  'Hal $_currentPage dari $_totalPages',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Page Navigation - Mobile
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPageButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4169E1).withOpacity(0.1),
                            const Color(0xFF4169E1).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4169E1).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4169E1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPageButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Results Info - Desktop
                Text(
                  'Menampilkan ${(_currentPage - 1) * _itemsPerPage + 1} - ${(_currentPage * _itemsPerPage) > _filteredPeriode.length ? _filteredPeriode.length : (_currentPage * _itemsPerPage)} dari ${_filteredPeriode.length} Periode',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                // Page Navigation - Desktop
                Row(
                  children: [
                    _buildPageButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4169E1).withOpacity(0.1),
                            const Color(0xFF4169E1).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4169E1).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4169E1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPageButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFF4169E1).withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? const Color(0xFF4169E1).withOpacity(0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        color: enabled ? const Color(0xFF4169E1) : Colors.grey[400],
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return CountdownHelper.formatDateTime(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _editPeriode(Map<String, dynamic> periode) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPeriodePage(periode: periode),
      ),
    );

    if (result == true) {
      _loadPeriode();
    }
  }

  Future<void> _stopPeriode(Map<String, dynamic> periode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.stop_circle, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Text(
              'Hentikan Periode',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghentikan periode ${periode['nama_periode']}? Status akan diubah menjadi "Selesai".',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Hentikan', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase
            .from('periode_ukm')
            .update({'status': 'selesai'})
            .eq('id_periode', periode['id_periode']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Periode berhasil dihentikan'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPeriode();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghentikan periode: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _startPeriode(Map<String, dynamic> periode) async {
    // Check if there's already an active periode
    try {
      final activeCheck = await _supabase
          .from('periode_ukm')
          .select('id_periode, nama_periode')
          .eq('status', 'aktif')
          .maybeSingle();

      if (activeCheck != null) {
        // Show dialog asking if user wants to stop the active periode first
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Periode Aktif Sudah Ada',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              'Sudah ada periode aktif: ${activeCheck['nama_periode']}.\n\nHentikan periode tersebut terlebih dahulu sebelum mengaktifkan periode baru.',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'OK',
                  style: GoogleFonts.inter(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        );
        return;
      }

      // No active periode, proceed to start
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_circle, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Text(
                'Mulai Periode',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin mengaktifkan periode ${periode['nama_periode']}? Status akan diubah menjadi "Aktif".',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Mulai', style: GoogleFonts.inter()),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _supabase
            .from('periode_ukm')
            .update({'status': 'aktif'})
            .eq('id_periode', periode['id_periode']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Periode berhasil diaktifkan'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPeriode();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengaktifkan periode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePeriode(Map<String, dynamic> periode) async {
    try {
      // Check if this is the only active periode
      final totalPeriode = await _supabase
          .from('periode_ukm')
          .select('id_periode')
          .count(CountOption.exact);

      final isLastPeriode = totalPeriode.count == 1;
      final isActivePeriode = periode['status'] == 'aktif';

      // Show warning if deleting the last active periode
      if (isLastPeriode || isActivePeriode) {
        final warningConfirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Peringatan',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              isLastPeriode
                  ? 'Ini adalah satu-satunya periode yang tersedia. Jika dihapus, seluruh UKM dan User tidak dapat melanjutkan aktivitas.\n\nApakah Anda yakin ingin menghapus periode ini?'
                  : 'Periode ini sedang aktif. Jika dihapus, UKM dan User yang terkait tidak dapat melanjutkan aktivitas.\n\nApakah Anda yakin ingin menghapus periode ini?',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.inter(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Lanjutkan', style: GoogleFonts.inter()),
              ),
            ],
          ),
        );

        if (warningConfirm != true) return;
      }

      // Proceed with normal delete confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Text(
                'Hapus Periode',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus periode ${periode['nama_periode']}? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Hapus', style: GoogleFonts.inter()),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _supabase
            .from('periode_ukm')
            .delete()
            .eq('id_periode', periode['id_periode']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Periode berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPeriode();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
