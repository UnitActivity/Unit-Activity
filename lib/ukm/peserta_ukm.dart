import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/services/peserta_service.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';
import 'package:unit_activity/ukm/detail_peserta_ukm_page.dart';
import 'package:fl_chart/fl_chart.dart';

class PesertaUKMPage extends StatefulWidget {
  const PesertaUKMPage({super.key});

  @override
  State<PesertaUKMPage> createState() => _PesertaUKMPageState();
}

class _PesertaUKMPageState extends State<PesertaUKMPage> {
  final PesertaService _pesertaService = PesertaService();
  final UkmDashboardService _dashboardService = UkmDashboardService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _pesertaList = [];
  List<Map<String, dynamic>> _filteredPesertaList = [];
  List<Map<String, dynamic>> _allRegisteredUsers = [];
  List<Map<String, dynamic>> _growthData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _ukmId;
  String? _periodeId;
  String? _periodeName;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('========== LOAD PESERTA DATA ==========');

      // Get current UKM ID
      print('Step 1: Getting current UKM ID...');
      _ukmId = await _dashboardService.getCurrentUkmId();
      print('UKM ID: $_ukmId');

      if (_ukmId == null) {
        print('❌ ERROR: Cannot identify UKM');
        setState(() {
          _errorMessage = 'Tidak dapat mengidentifikasi UKM';
          _isLoading = false;
        });
        return;
      }

      // Get current periode
      print('Step 2: Getting current periode for UKM $_ukmId...');
      print('About to call getCurrentPeriode...');
      final periode = await _dashboardService.getCurrentPeriode(_ukmId!);
      print('getCurrentPeriode returned: $periode');
      print('Periode is null: ${periode == null}');

      if (periode != null) {
        _periodeId = periode['id_periode'];
        print('>>> _periodeId set to: $_periodeId');

        // Create readable periode name
        final semester = periode['semester'] ?? '';
        final tahun = periode['tahun'] ?? '';
        _periodeName = 'Periode $semester $tahun';
        print('>>> _periodeName set to: $_periodeName');

        print(
          '✅ Using periode: ${periode['nama_periode']} (${periode['semester']} ${periode['tahun']})',
        );
        print('Periode ID: $_periodeId');
        print('Periode status: ${periode['status']}');
      } else {
        print('❌ No periode found for UKM $_ukmId');
        print('>>> _periodeId remains: $_periodeId');
        print('>>> _periodeName remains: $_periodeName');
      }

      // Load all registered users for autocomplete suggestions
      print('Step 2.5: Loading all registered users for suggestions...');
      try {
        _allRegisteredUsers = await _pesertaService.getAllRegisteredUsers();
        print(
          '✅ Loaded ${_allRegisteredUsers.length} registered users for suggestions',
        );
      } catch (e) {
        print('⚠️ Warning: Could not load registered users: $e');
        _allRegisteredUsers = [];
      }

      // Load peserta for this UKM and periode
      if (_periodeId != null) {
        print(
          'Step 3: Loading peserta for UKM $_ukmId and periode $_periodeId...',
        );
        final peserta = await _pesertaService.getPesertaByUkm(
          _ukmId!,
          _periodeId!,
        );
        print('✅ Loaded ${peserta.length} peserta');

        // Load growth data
        await _loadGrowthData();

        setState(() {
          _pesertaList = peserta;
          _filteredPesertaList = peserta;
          _isLoading = false;
        });
      } else {
        print('⚠️ WARNING: No periode ID available, cannot load peserta');
        setState(() {
          _errorMessage = 'Tidak ada periode aktif untuk UKM ini';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ ERROR loading peserta data: $e');
      setState(() {
        _errorMessage = 'Gagal memuat data peserta: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterPeserta(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPesertaList = _pesertaList;
      } else {
        _filteredPesertaList = _pesertaList.where((peserta) {
          final nama = peserta['nama']?.toString().toLowerCase() ?? '';
          final email = peserta['email']?.toString().toLowerCase() ?? '';
          final nim = peserta['nim']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return nama.contains(searchLower) ||
              email.contains(searchLower) ||
              nim.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadGrowthData() async {
    if (_ukmId == null || _periodeId == null) {
      return;
    }

    try {
      // Get all peserta with their join dates for this UKM
      final allPeserta = await _pesertaService.getPesertaByUkm(
        _ukmId!,
        _periodeId!,
      );

      // Calculate growth for last 6 months
      final now = DateTime.now();
      final List<Map<String, dynamic>> monthlyData = [];

      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);

        // Count peserta who joined up to this month
        int count = allPeserta.where((peserta) {
          if (peserta['tanggal'] == null) return false;
          try {
            final joinDate = DateTime.parse(peserta['tanggal'].toString());
            return joinDate.isBefore(monthEnd) ||
                joinDate.isAtSameMomentAs(monthEnd);
          } catch (e) {
            return false;
          }
        }).length;

        // Get month name
        final monthName = _getMonthName(monthDate.month);

        monthlyData.add({
          'month': monthName,
          'count': count,
          'monthNumber': monthDate.month,
        });
      }

      setState(() {
        _growthData = monthlyData;
      });
    } catch (e) {
      print('Error loading growth data: $e');
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards Row
          isDesktop
              ? Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Pengguna',
                        '${_pesertaList.length}',
                        Icons.people_rounded,
                        const Color(0xFF4169E1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Periode',
                        _periodeName ?? '-',
                        Icons.calendar_today_rounded,
                        const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildStatCard(
                      'Total Pengguna',
                      '${_pesertaList.length}',
                      Icons.people_rounded,
                      const Color(0xFF4169E1),
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Periode',
                      _periodeName ?? '-',
                      Icons.calendar_today_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ],
                ),
          const SizedBox(height: 24),

          // Chart Pertumbuhan Anggota
          _buildGrowthChart(),
          const SizedBox(height: 24),

          // Search Bar and Table
          _buildSearchAndTable(isDesktop),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    color: const Color(0xFF4169E1),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pertumbuhan Anggota',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                '6 Bulan Terakhir',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: _growthData.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada data pertumbuhan',
                      style: GoogleFonts.inter(color: Colors.grey[400]),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 16, top: 16),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[200]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < _growthData.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _growthData[value.toInt()]['month'],
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: _getYInterval(),
                              reservedSize: 42,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        minX: 0,
                        maxX: (_growthData.length - 1).toDouble(),
                        minY: 0,
                        maxY: _getMaxY(),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _growthData.asMap().entries.map((entry) {
                              return FlSpot(
                                entry.key.toDouble(),
                                entry.value['count'].toDouble(),
                              );
                            }).toList(),
                            isCurved: true,
                            color: const Color(0xFF4169E1),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: const Color(0xFF4169E1),
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF4169E1).withOpacity(0.1),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) =>
                                const Color(0xFF4169E1),
                            tooltipRoundedRadius: 8,
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((
                                LineBarSpot touchedSpot,
                              ) {
                                return LineTooltipItem(
                                  '${_growthData[touchedSpot.x.toInt()]['month']}\n${touchedSpot.y.toInt()} anggota',
                                  GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (_growthData.isEmpty) return 10;
    final maxCount = _growthData
        .map((d) => d['count'] as int)
        .reduce((a, b) => a > b ? a : b);
    // Add 20% padding to max value
    return (maxCount * 1.2).ceilToDouble();
  }

  double _getYInterval() {
    final maxY = _getMaxY();
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return 50;
  }

  Widget _buildSearchAndTable(bool isDesktop) {
    final isMobile = !isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with search - responsive layout
        if (isMobile) ...[
          // Mobile: Stack vertically
          TextField(
            controller: _searchController,
            onChanged: _filterPeserta,
            decoration: InputDecoration(
              hintText: 'Cari NIM, Username, atau Email...',
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddPesertaDialog,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Tambah Pengguna',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ] else ...[
          // Desktop: Row layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterPeserta,
                  decoration: InputDecoration(
                    hintText: 'Cari NIM, Username, atau Email...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[400],
                    ),
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
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showAddPesertaDialog,
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  'Tambah Pengguna',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),

        // Table
        _buildPesertaTable(isDesktop),
      ],
    );
  }

  Widget _buildPesertaTable(bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredPesertaList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Tidak ada peserta yang cocok'
                    : 'Belum ada peserta',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Table Content
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredPesertaList.length,
            itemBuilder: (context, index) {
              final peserta = _filteredPesertaList[index];
              return _buildPesertaRow(peserta, index, isDesktop);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPesertaRow(
    Map<String, dynamic> peserta,
    int index,
    bool isDesktop,
  ) {
    final isMobile = !isDesktop;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: isMobile ? 16 : 20,
            backgroundColor: const Color(0xFF4169E1).withOpacity(0.1),
            child: Text(
              (peserta['nama'] ?? 'U')[0].toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4169E1),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peserta['nama'] ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  peserta['email'] ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : 13,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isMobile && peserta['nim'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'NIM: ${peserta['nim']}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isDesktop) ...[
            SizedBox(
              width: 100,
              child: Text(
                peserta['nim'] ?? '-',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showDetailPesertaDialog(peserta),
                icon: Icon(Icons.visibility_rounded, size: isMobile ? 20 : 24),
                color: const Color(0xFF4169E1),
                tooltip: 'Lihat Detail',
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                constraints: isMobile ? const BoxConstraints() : null,
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmDialog(peserta),
                icon: Icon(Icons.delete_rounded, size: isMobile ? 20 : 24),
                color: Colors.red,
                tooltip: 'Hapus',
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                constraints: isMobile ? const BoxConstraints() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPesertaDialog() {
    final nimController = TextEditingController();
    List<Map<String, dynamic>> suggestions = [];
    Map<String, dynamic>? selectedUser;
    bool isSearching = false;
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void searchUsers(String query) async {
            if (query.length < 2) {
              setDialogState(() {
                suggestions = [];
                selectedUser = null;
              });
              return;
            }

            setDialogState(() {
              isSearching = true;
            });

            // Filter from preloaded users
            final queryLower = query.toLowerCase();
            final filtered = _allRegisteredUsers
                .where((user) {
                  final nim = user['nim']?.toString().toLowerCase() ?? '';
                  final username =
                      user['username']?.toString().toLowerCase() ?? '';
                  return nim.contains(queryLower) ||
                      username.contains(queryLower);
                })
                .take(8)
                .toList();

            setDialogState(() {
              suggestions = filtered;
              isSearching = false;
            });
          }

          void selectUser(Map<String, dynamic> user) {
            setDialogState(() {
              selectedUser = user;
              nimController.text = user['nim'] ?? '';
              suggestions = [];
            });
          }

          Future<void> addPeserta() async {
            if (nimController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('NIM tidak boleh kosong'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (_ukmId == null || _periodeId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('UKM atau Periode tidak tersedia'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            setDialogState(() {
              isAdding = true;
            });

            try {
              await _pesertaService.addPesertaByNim(
                nim: nimController.text.trim(),
                idUkm: _ukmId!,
                idPeriode: _periodeId!,
              );

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Berhasil menambahkan peserta dengan NIM: ${nimController.text}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );

              // Refresh data setelah menambahkan
              _loadData();
            } catch (e) {
              setDialogState(() {
                isAdding = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Gagal menambahkan peserta: ${e.toString().replaceFirst('Exception: ', '')}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person_add, color: const Color(0xFF4169E1)),
                const SizedBox(width: 8),
                Text(
                  'Tambah Peserta',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masukkan NIM mahasiswa yang ingin ditambahkan:',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nimController,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedUser = null;
                      });
                      searchUsers(value);
                    },
                    decoration: InputDecoration(
                      labelText: 'NIM',
                      hintText: 'Ketik NIM untuk mencari...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.badge),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : selectedUser != null
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final user = suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(
                                0xFF4169E1,
                              ).withOpacity(0.1),
                              child: Text(
                                (user['username'] ?? 'U')[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4169E1),
                                ),
                              ),
                            ),
                            title: Text(
                              user['nim'] ?? '-',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              user['username'] ?? '-',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            trailing: Text(
                              user['email']?.toString().split('@').first ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () => selectUser(user),
                          );
                        },
                      ),
                    ),
                  ],
                  if (selectedUser != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(
                              0xFF4169E1,
                            ).withOpacity(0.1),
                            child: Text(
                              (selectedUser!['username'] ?? 'U')[0]
                                  .toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4169E1),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedUser!['username'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  selectedUser!['email'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.check_circle, color: Colors.green[700]),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Tip: Ketik minimal 2 karakter untuk melihat rekomendasi',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isAdding ? null : () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: isAdding ? null : addPeserta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                ),
                child: isAdding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Tambah', style: GoogleFonts.inter()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetailPesertaDialog(Map<String, dynamic> peserta) {
    // Navigate to detail page instead of showing dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPesertaUKMPage(
          peserta: peserta,
          ukmId: _ukmId!,
          periodeId: _periodeId!,
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> peserta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 8),
            Text(
              'Hapus Peserta',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus peserta ini?',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF4169E1).withOpacity(0.1),
                    child: Text(
                      (peserta['nama'] ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4169E1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          peserta['nama'] ?? '-',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'NIM: ${peserta['nim'] ?? '-'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePeserta(peserta);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Hapus', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePeserta(Map<String, dynamic> peserta) async {
    try {
      final idFollow = peserta['id_follow'];
      if (idFollow == null) {
        throw Exception('ID peserta tidak valid');
      }

      await _pesertaService.deletePeserta(idFollow);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menghapus peserta: ${peserta['nama']}'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh data
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus peserta: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
