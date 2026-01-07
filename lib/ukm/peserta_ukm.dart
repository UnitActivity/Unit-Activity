import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/services/peserta_service.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';
import 'package:intl/intl.dart';

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
      final periode = await _dashboardService.getCurrentPeriode(_ukmId!);
      print('Periode data: $periode');

      if (periode != null) {
        _periodeId = periode['id_periode'];
        // Create readable periode name
        final semester = periode['semester'] ?? '';
        final tahun = periode['tahun'] ?? '';
        _periodeName = 'Periode $semester $tahun';
        print(
          '✅ Using periode: ${periode['nama_periode']} (${periode['semester']} ${periode['tahun']})',
        );
        print('Periode ID: $_periodeId');
        print('Periode status: ${periode['status']}');
      } else {
        print('❌ No periode found for UKM $_ukmId');
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
                    Expanded(child: _buildStatCard('Total Pengguna', '${_pesertaList.length}', Icons.people_rounded, const Color(0xFF4169E1))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Periode', _periodeName ?? '-', Icons.calendar_today_rounded, const Color(0xFFF59E0B))),
                  ],
                )
              : Column(
                  children: [
                    _buildStatCard('Total Pengguna', '${_pesertaList.length}', Icons.people_rounded, const Color(0xFF4169E1)),
                    const SizedBox(height: 16),
                    _buildStatCard('Periode', _periodeName ?? '-', Icons.calendar_today_rounded, const Color(0xFFF59E0B)),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
                  Icon(Icons.show_chart, color: const Color(0xFF4169E1), size: 20),
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
            child: Center(
              child: Text(
                'Chart akan ditampilkan di sini (${_pesertaList.length} anggota)',
                style: GoogleFonts.inter(color: Colors.grey[400]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndTable(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with search
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _filterPeserta,
                decoration: InputDecoration(
                  hintText: 'Cari NIM, Username, atau Email...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
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
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur tambah pengguna akan segera hadir')),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Tambah Pengguna',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
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
              Text(_errorMessage!, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
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

  Widget _buildPesertaRow(Map<String, dynamic> peserta, int index, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF4169E1).withOpacity(0.1),
            child: Text(
              (peserta['nama'] ?? 'U')[0].toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4169E1),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peserta['nama'] ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  peserta['email'] ?? '-',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                ),
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
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.visibility_rounded),
                color: const Color(0xFF4169E1),
                tooltip: 'Lihat Detail',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_rounded),
                color: Colors.red,
                tooltip: 'Hapus',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

