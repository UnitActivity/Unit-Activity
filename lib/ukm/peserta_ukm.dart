import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/services/peserta_service.dart';
import 'package:unit_activity/services/auth_service.dart';
import 'package:intl/intl.dart';

class PesertaUKMPage extends StatefulWidget {
  const PesertaUKMPage({super.key});

  @override
  State<PesertaUKMPage> createState() => _PesertaUKMPageState();
}

class _PesertaUKMPageState extends State<PesertaUKMPage> {
  int _currentPage = 1;
  final PesertaService _pesertaService = PesertaService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _pesertaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPeserta();
  }

  Future<void> _loadPeserta() async {
    setState(() => _isLoading = true);
    try {
      // Load all peserta without UUID filter
      final peserta = await _pesertaService.getAllPeserta();
      print('Loaded peserta data: $peserta'); // Debug print
      setState(() {
        _pesertaList = peserta;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading peserta: $e'); // Debug print
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
    // Get screen height for calculating container height
    final screenHeight = MediaQuery.of(context).size.height;
    final tableHeight = screenHeight - 300; // Account for header, padding, etc.

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Peserta',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _loadPeserta,
                    icon: const Icon(Icons.refresh),
                    color: const Color(0xFF4169E1),
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddPesertaDialog,
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
                      'Tambah Peserta',
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
              child: Column(
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
                          width: 40,
                          child: Checkbox(
                            value: false,
                            onChanged: (value) {},
                            activeColor: const Color(0xFF4169E1),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              'Nama',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              'Email',
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
                            child: Text(
                              'NIM',
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
                            child: Text(
                              'Tanggal',
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
                    child: ListView.builder(
                      itemCount: _pesertaList.length,
                      itemBuilder: (context, index) {
                        final peserta = _pesertaList[index];
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
                                width: 40,
                                child: Checkbox(
                                  value: false,
                                  onChanged: (value) {},
                                  activeColor: const Color(0xFF4169E1),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    peserta['nama'] ?? '-',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    peserta['email'] ?? '-',
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
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    peserta['nim'] ?? '-',
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
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    _formatTanggal(peserta['tanggal']),
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
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showEditDialog(peserta),
                                      icon: const Icon(Icons.edit_outlined),
                                      color: const Color(0xFF4169E1),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _showDeleteDialog(peserta),
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
                    ),
                  ),

                  // Pagination
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(width: 16),
                        Text(
                          '$_currentPage',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4169E1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _currentPage++;
                            });
                          },
                          icon: const Icon(Icons.chevron_right),
                          color: const Color(0xFF4169E1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPesertaDialog() {
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController();
    final nimController = TextEditingController();
    final emailController = TextEditingController();
    final teleponController = TextEditingController();
    final alamatController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
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
                    Row(
                      children: [
                        const Icon(Icons.person_add, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Tambah Peserta Baru',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormTextField(
                          controller: namaController,
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: nimController,
                          label: 'NIM',
                          hint: 'Masukkan NIM',
                          icon: Icons.badge,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'NIM harus diisi';
                            }
                            if (value.length < 9) {
                              return 'NIM minimal 9 digit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'nama@student.ukdc.ac.id',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email harus diisi';
                            }
                            if (!value.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: teleponController,
                          label: 'No. Telepon',
                          hint: '08xxxxxxxxxx',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'No. telepon harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: alamatController,
                          label: 'Alamat',
                          hint: 'Masukkan alamat lengkap',
                          icon: Icons.home,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Alamat harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
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
                                  Navigator.pop(context);

                                  try {
                                    // TODO: Get actual id_ukm and id_periode from logged in user
                                    final now = DateTime.now();

                                    // For now, just reload the data
                                    // In real implementation, you would:
                                    // 1. Create user account first via auth
                                    // 2. Get the user id
                                    // 3. Insert into user_halaman_ukm with proper id_ukm and id_periode

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Fitur tambah peserta belum tersedia. Silakan tambahkan peserta melalui registrasi user terlebih dahulu.',
                                          style: GoogleFonts.inter(),
                                        ),
                                        backgroundColor: Colors.orange,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gagal menambahkan: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
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
    );
  }

  Widget _buildFormTextField({
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
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

  void _showEditDialog(Map<String, dynamic> peserta) {
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: peserta['nama']);
    final nimController = TextEditingController(text: peserta['nim']);
    final emailController = TextEditingController(text: peserta['email']);
    final teleponController = TextEditingController(text: '081234567890');
    final alamatController = TextEditingController(text: 'Jl. Contoh No. 123');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Edit Data Peserta',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormTextField(
                          controller: namaController,
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: nimController,
                          label: 'NIM',
                          hint: 'Masukkan NIM',
                          icon: Icons.badge,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'NIM harus diisi';
                            }
                            if (value.length < 10) {
                              return 'NIM minimal 10 digit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'nama@student.ukdc.ac.id',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email harus diisi';
                            }
                            if (!value.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: teleponController,
                          label: 'No. Telepon',
                          hint: '08xxxxxxxxxx',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'No. telepon harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormTextField(
                          controller: alamatController,
                          label: 'Alamat',
                          hint: 'Masukkan alamat lengkap',
                          icon: Icons.home,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Alamat harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
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
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  // Update to database (currently using local list)
                                  setState(() {
                                    peserta['nama'] = namaController.text;
                                    peserta['email'] = emailController.text;
                                    peserta['nim'] = nimController.text;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Data "${namaController.text}" berhasil diupdate!',
                                        style: GoogleFonts.inter(),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
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
                                'Update',
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
    );
  }

  void _showDeleteDialog(Map<String, dynamic> peserta) {
    print('Delete dialog for peserta: $peserta'); // Debug print

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Hapus Peserta',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text('Yakin ingin menghapus ${peserta['nama']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate id_follow
              final idFollow = peserta['id_follow'];
              print(
                'id_follow value: $idFollow, type: ${idFollow.runtimeType}',
              ); // Debug print

              if (idFollow == null) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: ID peserta tidak ditemukan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              Navigator.pop(context);

              try {
                print(
                  'Calling removePeserta with id: $idFollow',
                ); // Debug print
                // Call service to remove peserta (soft delete)
                await _pesertaService.removePeserta(
                  idFollow.toString(),
                  'Dihapus oleh admin UKM',
                );
                print('Delete successful!'); // Debug print
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Peserta berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadPeserta(); // Refresh list
                }
              } catch (e) {
                print('Delete error: $e'); // Debug print
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

  String _formatTanggal(dynamic tanggal) {
    if (tanggal == null) return '-';

    try {
      // If it's already a DateTime object
      if (tanggal is DateTime) {
        return DateFormat('dd-MM-yyyy').format(tanggal);
      }

      // If it's a string
      String tanggalStr = tanggal.toString();

      // Try to parse ISO format (2026-01-03 or 2026-01-03T00:00:00)
      if (tanggalStr.contains('-') && tanggalStr.indexOf('-') > 2) {
        DateTime dt = DateTime.parse(tanggalStr);
        return DateFormat('dd-MM-yyyy').format(dt);
      }

      // If it's already in dd-MM-yyyy format, return as is
      if (tanggalStr.contains('-') && tanggalStr.length >= 8) {
        final parts = tanggalStr.split('-');
        if (parts.length == 3 && parts[0].length <= 2) {
          // Pad day and month with leading zeros if needed
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          final year = parts[2];
          return '$day-$month-$year';
        }
      }

      return tanggalStr;
    } catch (e) {
      print('Error formatting date: $e, value: $tanggal');
      return tanggal.toString();
    }
  }
}
