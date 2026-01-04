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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Peserta',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_filteredPesertaList.length} peserta',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  color: const Color(0xFF4169E1),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterPeserta,
                decoration: InputDecoration(
                  hintText: 'Cari peserta berdasarkan nama, email, atau NIM...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                            _filterPeserta('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Content
            SizedBox(height: 500, child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Memuat data peserta...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredPesertaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada peserta yang sesuai dengan pencarian'
                  : 'Belum ada peserta terdaftar',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _filterPeserta('');
                },
                child: Text(
                  'Hapus filter',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF4169E1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
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
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
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
                  flex: 3,
                  child: Text(
                    'Email',
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
                  flex: 2,
                  child: Text(
                    'Tanggal Bergabung',
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
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPesertaList.length,
              itemBuilder: (context, index) {
                final peserta = _filteredPesertaList[index];
                return _buildPesertaRow(peserta, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesertaRow(Map<String, dynamic> peserta, int index) {
    final isEven = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (peserta['nama'] ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4169E1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    peserta['nama'] ?? '-',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              peserta['email'] ?? '-',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              peserta['nim'] ?? '-',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatTanggal(peserta['tanggal']),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTanggal(dynamic tanggal) {
    if (tanggal == null) return '-';
    try {
      final date = DateTime.parse(tanggal.toString());
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return '-';
    }
  }
}
