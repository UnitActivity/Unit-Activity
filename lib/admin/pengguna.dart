import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'add_pengguna_page.dart';
import 'edit_pengguna_page.dart';
import 'detail_pengguna_page.dart';

class PenggunaPage extends StatefulWidget {
  const PenggunaPage({super.key});

  @override
  State<PenggunaPage> createState() => _PenggunaPageState();
}

class _PenggunaPageState extends State<PenggunaPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final String _sortBy = 'Urutkan';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  int _totalUsers = 0;

  // Period and growth data
  Map<String, dynamic>? _activePeriode;
  List<Map<String, dynamic>> _growthData = [];

  // Column visibility settings
  final Map<String, bool> _columnVisibility = {
    'picture': true,
    'nim': true,
    'email': false,
    'actions': true,
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadPeriodeAndGrowth();
  }

  Future<void> _loadPeriodeAndGrowth() async {
    try {
      // Load active periode - try different status values
      var periodeResponse = await _supabase
          .from('periode_ukm')
          .select('id_periode, nama_periode, semester, tahun, status')
          .eq('status', 'aktif')
          .limit(1)
          .maybeSingle();

      // If not found, try with capital 'Aktif'
      periodeResponse ??= await _supabase
          .from('periode_ukm')
          .select('id_periode, nama_periode, semester, tahun, status')
          .eq('status', 'Aktif')
          .limit(1)
          .maybeSingle();

      // If still not found, try to get any periode ordered by created date
      if (periodeResponse == null) {
        final allPeriodes = await _supabase
            .from('periode_ukm')
            .select('id_periode, nama_periode, semester, tahun, status')
            .order('tanggal_awal', ascending: false)
            .limit(5);

        print('All available periodes: $allPeriodes');

        // Try to find one with status containing 'aktif' (case insensitive)
        if (allPeriodes.isNotEmpty) {
          periodeResponse = (allPeriodes as List).firstWhere(
            (p) =>
                p['status']?.toString().toLowerCase().contains('aktif') ??
                false,
            orElse: () => allPeriodes.first,
          );
        }
      }

      print('Periode response: $periodeResponse');

      // Load user growth data for the last 6 months
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      final usersResponse = await _supabase
          .from('users')
          .select('create_at')
          .gte('create_at', sixMonthsAgo.toIso8601String());

      // Group users by month
      Map<String, int> monthlyCount = {};
      for (int i = 0; i < 6; i++) {
        final month = DateTime(now.year, now.month - (5 - i), 1);
        final monthKey = DateFormat('MMM').format(month);
        monthlyCount[monthKey] = 0;
      }

      for (var user in usersResponse) {
        final createAt = DateTime.parse(user['create_at']);
        final monthKey = DateFormat('MMM').format(createAt);
        if (monthlyCount.containsKey(monthKey)) {
          monthlyCount[monthKey] = monthlyCount[monthKey]! + 1;
        }
      }

      // Convert to cumulative growth
      List<Map<String, dynamic>> growthList = [];
      int cumulative = 0;
      monthlyCount.forEach((month, count) {
        cumulative += count;
        growthList.add({'month': month, 'count': cumulative});
      });

      setState(() {
        _activePeriode = periodeResponse;
        _growthData = growthList;
      });
    } catch (e) {
      print('Error loading periode and growth: $e');
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var queryBuilder = _supabase
          .from('users')
          .select('id_user, username, email, nim, picture, create_at');

      if (_searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'nim.ilike.%$_searchQuery%,username.ilike.%$_searchQuery%,email.ilike.%$_searchQuery%',
        );
      }

      final List<dynamic> allResponse = await queryBuilder;

      var sortedUsers = List<Map<String, dynamic>>.from(allResponse);
      if (_sortBy == 'NIM') {
        sortedUsers.sort(
          (a, b) => (a['nim'] ?? '').toString().compareTo(
            (b['nim'] ?? '').toString(),
          ),
        );
      } else if (_sortBy == 'Username') {
        sortedUsers.sort(
          (a, b) => (a['username'] ?? '').toString().compareTo(
            (b['username'] ?? '').toString(),
          ),
        );
      } else if (_sortBy == 'Email') {
        sortedUsers.sort(
          (a, b) => (a['email'] ?? '').toString().compareTo(
            (b['email'] ?? '').toString(),
          ),
        );
      } else {
        sortedUsers.sort((a, b) {
          final dateA =
              DateTime.tryParse(a['create_at'] ?? '') ?? DateTime.now();
          final dateB =
              DateTime.tryParse(b['create_at'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
      }

      _totalUsers = sortedUsers.length;

      final startIndex = (_currentPage - 1) * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;
      final paginatedData = sortedUsers.sublist(
        startIndex,
        endIndex > sortedUsers.length ? sortedUsers.length : endIndex,
      );

      setState(() {
        _allUsers = paginatedData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get _totalPages =>
      _totalUsers == 0 ? 1 : (_totalUsers / _itemsPerPage).ceil();

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Header
        _buildModernHeader(isDesktop),
        const SizedBox(height: 24),

        // Stats Cards
        _buildStatsCards(isDesktop),
        const SizedBox(height: 24),

        // Growth Chart
        _buildGrowthChart(isDesktop),
        const SizedBox(height: 24),

        // Search and Actions Bar
        _buildSearchAndFilterBar(isDesktop),
        const SizedBox(height: 20),

        // Content
        if (_isLoading)
          _buildLoadingState()
        else if (_allUsers.isEmpty)
          _buildEmptyState()
        else if (isDesktop || isTablet)
          _buildDesktopTable(isDesktop)
        else
          _buildMobileList(),

        if (!_isLoading && _allUsers.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildPagination(),
        ],
      ],
    );
  }

  Widget _buildModernHeader(bool isDesktop) {
    return const SizedBox.shrink();
  }

  Widget _buildStatsCards(bool isDesktop) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Format periode value untuk mobile
    String getPeriodeValue() {
      if (_activePeriode == null) return 'Tidak Ada Periode Aktif';

      if (isMobile) {
        // Format mobile: tahun.semester (misal: 2025.1)
        final tahun = _activePeriode!['tahun']?.toString() ?? '';
        final semester =
            _activePeriode!['semester']?.toString().toLowerCase() ?? '';
        final semesterNum = semester.contains('ganjil') || semester == '1'
            ? '1'
            : '2';
        return tahun.isNotEmpty ? '$tahun.$semesterNum' : 'N/A';
      } else {
        // Format desktop: nama lengkap atau semester tahun
        return (_activePeriode!['nama_periode']?.toString() ??
                '${_activePeriode!['semester'] ?? ''} ${_activePeriode!['tahun'] ?? ''}')
            .trim();
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Pengguna',
            value: '$_totalUsers',
            icon: Icons.people_outline,
            gradient: const LinearGradient(
              colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
            ),
            isDesktop: isDesktop,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Periode',
            value: getPeriodeValue(),
            icon: Icons.calendar_today_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
            isDesktop: isDesktop,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required bool isDesktop,
  }) {
    final isMobile = !isDesktop && MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : (isMobile ? 12 : 16)),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: isMobile ? 20 : 24),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: isMobile ? 3 : 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 24 : (isMobile ? 16 : 20),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

  Widget _buildGrowthChart(bool isDesktop) {
    if (_growthData.isEmpty) {
      return const SizedBox.shrink();
    }

    final isMobile = !isDesktop && MediaQuery.of(context).size.width < 600;
    final maxValue = _growthData
        .map((e) => e['count']!)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : (isMobile ? 12 : 16)),
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
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: isMobile ? 16 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Pertumbuhan Anggota',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 13 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '6 Bulan Terakhir',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4169E1),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),

          // Line Chart
          SizedBox(
            height: 220,
            child: CustomPaint(
              size: Size.infinite,
              painter: LineChartPainter(data: _growthData, maxValue: maxValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: isMobile ? 300 : 400,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: isMobile ? 40 : 50,
              height: isMobile ? 40 : 50,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
              ),
            ),
            SizedBox(height: isMobile ? 14 : 20),
            Text(
              'Memuat data pengguna...',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: isMobile ? 300 : 400,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 18 : 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: isMobile ? 48 : 64,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: isMobile ? 14 : 20),
            Text(
              _searchQuery.isEmpty ? 'Belum Ada Pengguna' : 'Tidak Ada Hasil',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 15 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Klik tombol Tambah untuk menambah pengguna baru'
                  : 'Coba kata kunci lain untuk pencarian',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isDesktop) {
    final isMobile = !isDesktop && MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : (isMobile ? 12 : 16)),
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
      child: Row(
        children: [
          // Search Bar
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                onChanged: (value) {
                  _searchQuery = value;
                  _currentPage = 1;
                  _loadUsers();
                },
                decoration: InputDecoration(
                  hintText: 'Cari NIM, Username atau Email...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[600],
                    size: isMobile ? 20 : 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                            _loadUsers();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Column Visibility - Desktop only
          if (isDesktop) ...[
            _buildIconButton(
              icon: Icons.view_column_rounded,
              tooltip: 'Tampilkan Kolom',
              onPressed: () => _showColumnVisibilityMenu(context),
            ),
            const SizedBox(width: 8),
          ],

          // Refresh Button
          _buildIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh Data',
            onPressed: _loadUsers,
          ),

          const SizedBox(width: 8),

          // Add Button
          ElevatedButton.icon(
            onPressed: _showAddUserDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16,
                vertical: isDesktop ? 16 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              isDesktop ? 'Tambah Pengguna' : 'Tambah',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: Colors.grey[700],
        tooltip: tooltip,
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  void _showColumnVisibilityMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4169E1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.view_column_rounded,
                      color: Color(0xFF4169E1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pilih Kolom',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ..._columnVisibility.entries.map((entry) {
                return CheckboxListTile(
                  title: Text(
                    _getColumnLabel(entry.key),
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  value: entry.value,
                  activeColor: const Color(0xFF4169E1),
                  onChanged: (value) {
                    setState(() {
                      _columnVisibility[entry.key] = value!;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _getColumnLabel(String key) {
    switch (key) {
      case 'picture':
        return 'Foto & Nama';
      case 'nim':
        return 'NIM';
      case 'email':
        return 'Email';
      case 'actions':
        return 'Actions';
      default:
        return key;
    }
  }

  Widget _buildDesktopTable(bool isDesktop) {
    return Container(
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
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4169E1).withOpacity(0.08),
                  const Color(0xFF4169E1).withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                if (_columnVisibility['picture']!)
                  Expanded(
                    flex: 3,
                    child: Text(
                      'PENGGUNA',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4169E1),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                if (_columnVisibility['nim']!)
                  Expanded(
                    flex: 2,
                    child: Text(
                      'NIM',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4169E1),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                if (_columnVisibility['email']!)
                  Expanded(
                    flex: 3,
                    child: Text(
                      'EMAIL',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4169E1),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                if (_columnVisibility['actions']!)
                  SizedBox(
                    width: 100,
                    child: Text(
                      'AKSI',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4169E1),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          // Table Body
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allUsers.length,
            itemBuilder: (context, index) {
              final user = _allUsers[index];
              final userId = user['id_user'].toString();

              return InkWell(
                onTap: () async {
                  // Navigate to detail page
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPenggunaPage(user: user),
                    ),
                  );

                  // Reload if data changed
                  if (result == true) {
                    _loadUsers();
                  }
                },
                hoverColor: const Color(0xFF4169E1).withOpacity(0.03),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[100]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(
                                  0xFF4169E1,
                                ).withOpacity(0.12),
                                backgroundImage:
                                    user['picture'] != null &&
                                        user['picture'].toString().isNotEmpty
                                    ? NetworkImage(user['picture'])
                                    : null,
                                child:
                                    user['picture'] == null ||
                                        user['picture'].toString().isEmpty
                                    ? Text(
                                        (user['username'] ?? 'U')
                                            .toString()[0]
                                            .toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF4169E1),
                                          fontSize: 16,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                user['username'] ?? '-',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // NIM Column
                      if (_columnVisibility['nim']!)
                        Expanded(
                          flex: 2,
                          child: Text(
                            user['nim'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // Email Column
                      if (_columnVisibility['email']!)
                        Expanded(
                          flex: 3,
                          child: Text(
                            user['email'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      // Actions Column
                      if (_columnVisibility['actions']!)
                        SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                icon: Icons.edit_rounded,
                                color: Colors.blue,
                                onPressed: () => _showEditUserDialog(user),
                                tooltip: 'Edit',
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.delete_rounded,
                                color: Colors.red,
                                onPressed: () => _showDeleteDialog(user),
                                tooltip: 'Hapus',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        return _buildMobileCard(_allUsers[index]);
      },
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> user) {
    final userId = user['id_user'].toString();

    return GestureDetector(
      onTap: () async {
        // Navigate to detail page
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPenggunaPage(user: user),
          ),
        );

        // Reload if data changed
        if (result == true) {
          _loadUsers();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4169E1).withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4169E1).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(
                        0xFF4169E1,
                      ).withOpacity(0.12),
                      backgroundImage:
                          user['picture'] != null &&
                              user['picture'].toString().isNotEmpty
                          ? NetworkImage(user['picture'])
                          : null,
                      child:
                          user['picture'] == null ||
                              user['picture'].toString().isEmpty
                          ? Text(
                              (user['username'] ?? 'U')
                                  .toString()[0]
                                  .toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4169E1),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user['username'] ?? '-',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user['nim'] ?? '-',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Email
                  _buildInfoRow(
                    Icons.email_outlined,
                    'Email',
                    user['email'] ?? '-',
                  ),
                  const SizedBox(height: 12),

                  // Create Date
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    'Bergabung',
                    _formatDate(user['create_at']),
                  ),

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditUserDialog(user),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeleteDialog(user),
                          icon: const Icon(Icons.delete_rounded, size: 18),
                          label: Text(
                            'Hapus',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4169E1).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF4169E1)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
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
              children: [
                // Results Info - mobile
                Text(
                  'Halaman $_currentPage dari $_totalPages',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                // Page Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    _buildPageButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                        _loadUsers();
                      },
                    ),
                    const SizedBox(width: 12),
                    // Page Numbers
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4169E1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next Button
                    _buildPageButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                        });
                        _loadUsers();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Total users info
                Text(
                  '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage) > _totalUsers ? _totalUsers : (_currentPage * _itemsPerPage)} dari $_totalUsers',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Results Info
                Text(
                  'Menampilkan ${(_currentPage - 1) * _itemsPerPage + 1} - ${(_currentPage * _itemsPerPage) > _totalUsers ? _totalUsers : (_currentPage * _itemsPerPage)} dari $_totalUsers pengguna',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),

                // Page Navigation
                Row(
                  children: [
                    // Previous Button
                    _buildPageButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                        _loadUsers();
                      },
                    ),

                    const SizedBox(width: 12),

                    // Page Numbers
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

                    // Next Button
                    _buildPageButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                        });
                        _loadUsers();
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

  void _showDeleteDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Konfirmasi Hapus',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'Apakah Anda yakin ingin menghapus ${user['username']}?',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _performDelete(user['id_user'].toString());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Hapus',
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
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPenggunaPage(user: user)),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  void _showAddUserDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPenggunaPage()),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _performDelete(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id_user', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus pengguna: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Custom Painter for Line Chart
class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxValue;

  LineChartPainter({required this.data, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double leftPadding = 40;
    final double rightPadding = 20;
    final double topPadding = 20;
    final double bottomPadding = 40;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final y = topPadding + (chartHeight / 5) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      // Draw Y-axis labels
      final value = (maxValue * (5 - i) / 5).toInt();
      final textSpan = TextSpan(
        text: value.toString(),
        style: GoogleFonts.inter(
          fontSize: 10,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Calculate data points
    final points = <Offset>[];
    final double stepX = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final count = data[i]['count']!.toDouble();
      final x = leftPadding + stepX * i;
      final y = topPadding + chartHeight - (count / maxValue * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw gradient area under the line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, size.height - bottomPadding);
      path.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final cp1x = points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2;
        final cp1y = points[i - 1].dy;
        final cp2x = points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2;
        final cp2y = points[i].dy;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, points[i].dx, points[i].dy);
      }

      path.lineTo(points.last.dx, size.height - bottomPadding);
      path.close();

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4169E1).withOpacity(0.3),
            const Color(0xFF4169E1).withOpacity(0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, gradientPaint);
    }

    // Draw curved line
    if (points.length > 1) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final cp1x = points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2;
        final cp1y = points[i - 1].dy;
        final cp2x = points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2;
        final cp2y = points[i].dy;

        linePath.cubicTo(cp1x, cp1y, cp2x, cp2y, points[i].dx, points[i].dy);
      }

      final linePaint = Paint()
        ..color = const Color(0xFF4169E1)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Draw data points and values
    for (int i = 0; i < points.length; i++) {
      // Outer circle (white border)
      final outerCirclePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], 6, outerCirclePaint);

      // Inner circle (blue)
      final innerCirclePaint = Paint()
        ..color = const Color(0xFF4169E1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], 4, innerCirclePaint);

      // Draw value above point
      final valueText = TextSpan(
        text: data[i]['count'].toString(),
        style: GoogleFonts.inter(
          fontSize: 11,
          color: const Color(0xFF4169E1),
          fontWeight: FontWeight.w700,
        ),
      );
      final valueTextPainter = TextPainter(
        text: valueText,
        textDirection: ui.TextDirection.ltr,
      );
      valueTextPainter.layout();
      valueTextPainter.paint(
        canvas,
        Offset(points[i].dx - valueTextPainter.width / 2, points[i].dy - 20),
      );

      // Draw month label
      final monthText = TextSpan(
        text: data[i]['month'],
        style: GoogleFonts.inter(
          fontSize: 11,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      );
      final monthTextPainter = TextPainter(
        text: monthText,
        textDirection: ui.TextDirection.ltr,
      );
      monthTextPainter.layout();
      monthTextPainter.paint(
        canvas,
        Offset(
          points[i].dx - monthTextPainter.width / 2,
          size.height - bottomPadding + 10,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}
