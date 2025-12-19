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
  Set<String> _selectedUsers = {};

  // Column visibility settings
  final Map<String, bool> _columnVisibility = {
    'picture': true,
    'nim': true,
    'email': false,
    'role': true,
    'joinAt': false,
    'actions': true,
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
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

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedUsers = _allUsers.map((u) => u['id_user'].toString()).toSet();
      } else {
        _selectedUsers.clear();
      }
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '',
              style: GoogleFonts.inter(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (_selectedUsers.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: const Color(0xFF4169E1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedUsers.length} dipilih',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4169E1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _showDeleteConfirmation,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red,
                      tooltip: 'Hapus pengguna',
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        _buildSearchAndFilterBar(isDesktop),
        const SizedBox(height: 20),

        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: CircularProgressIndicator(color: Color(0xFF4169E1)),
            ),
          )
        else if (_allUsers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Belum ada pengguna'
                        : 'Tidak ada hasil pencarian',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
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

  Widget _buildSearchAndFilterBar(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 400 : double.infinity,
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
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
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
                  borderSide: const BorderSide(
                    color: Color(0xFF4169E1),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),

        // Column Visibility Dropdown - only show on desktop
        if (isDesktop) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_column, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Kolom',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                ],
              ),
              tooltip: 'Pilih kolom yang ditampilkan',
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'Tampilkan Kolom',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'picture',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['picture'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('Name', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'nim',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['nim'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('NIM', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'email',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['email'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('Email', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'role',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['role'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('Role', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'joinAt',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['joinAt'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('Join At', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'actions',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _columnVisibility['actions'],
                        onChanged: null,
                        activeColor: const Color(0xFF4169E1),
                      ),
                      const SizedBox(width: 8),
                      Text('Actions', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                setState(() {
                  _columnVisibility[value] = !_columnVisibility[value]!;
                });
              },
            ),
          ),
        ],

        // Add User Button
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPenggunaPage()),
            );
            // Refresh list if user was added
            if (result == true) {
              _loadUsers();
            }
          },
          icon: const Icon(Icons.add, size: 20),
          label: Text(
            'Tambah Pengguna',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4169E1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Checkbox(
                    value:
                        _selectedUsers.length == _allUsers.length &&
                        _allUsers.isNotEmpty,
                    onChanged: _toggleSelectAll,
                    activeColor: const Color(0xFF4169E1),
                  ),
                ),
                if (_columnVisibility['picture']!)
                  Expanded(
                    flex: 3,
                    child: Text(
                      'NAME',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                if (_columnVisibility['nim']!)
                  Expanded(
                    flex: 2,
                    child: Text(
                      'NIM',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                if (_columnVisibility['email']!)
                  Expanded(
                    flex: 3,
                    child: Text(
                      'EMAIL',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                if (_columnVisibility['role']!)
                  Expanded(
                    flex: 2,
                    child: Text(
                      'ROLE',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                if (_columnVisibility['joinAt']!)
                  Expanded(
                    flex: 2,
                    child: Text(
                      'JOIN AT',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                if (_columnVisibility['actions']!)
                  SizedBox(
                    width: 120,
                    child: Text(
                      'ACTIONS',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allUsers.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final user = _allUsers[index];
              final userId = user['id_user'].toString();
              final isSelected = _selectedUsers.contains(userId);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                color: isSelected
                    ? const Color(0xFF4169E1).withOpacity(0.05)
                    : null,
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleUserSelection(userId),
                        activeColor: const Color(0xFF4169E1),
                      ),
                    ),
                    // Name & Picture Column
                    if (_columnVisibility['picture']!)
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(
                                0xFF4169E1,
                              ).withOpacity(0.1),
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
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF4169E1),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
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
                            color: Colors.black87,
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
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Role Column
                    if (_columnVisibility['role']!)
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4169E1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'User',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF4169E1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Join At Column
                    if (_columnVisibility['joinAt']!)
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(user['create_at']),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    // Actions Column
                    if (_columnVisibility['actions']!)
                      SizedBox(
                        width: 80,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _viewUserDetail(user),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 20,
                              ),
                              color: Colors.grey[700],
                              tooltip: 'View',
                            ),
                            IconButton(
                              onPressed: () => _deleteUser(userId),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: Colors.red[700],
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        final user = _allUsers[index];
        final userId = user['id_user'].toString();
        final isSelected = _selectedUsers.contains(userId);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      const Color(0xFF4169E1).withOpacity(0.05),
                      const Color(0xFF4169E1).withOpacity(0.02),
                    ]
                  : [Colors.white, Colors.grey[50]!],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF4169E1) : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF4169E1).withOpacity(0.1)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Section with Gradient
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
                    // Checkbox with custom styling
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleUserSelection(userId),
                        activeColor: const Color(0xFF4169E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar with border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4169E1).withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4169E1).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(
                          0xFF4169E1,
                        ).withOpacity(0.1),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4169E1),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // User Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4169E1),
                                      Color(0xFF5B7FE8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4169E1,
                                      ).withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'USER',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
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
              // Divider with gradient
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey[300]!,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Info Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMobileInfoRow(
                      Icons.email_rounded,
                      user['email'] ?? '-',
                    ),
                    const SizedBox(height: 12),
                    _buildMobileInfoRow(
                      Icons.access_time_rounded,
                      'Bergabung: ${_formatDate(user['create_at'])}',
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons with modern design
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.visibility_rounded,
                            label: 'View',
                            color: const Color(0xFF6B7280),
                            onPressed: () => _viewUserDetail(user),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey[300],
                          ),
                          _buildActionButton(
                            icon: Icons.delete_rounded,
                            label: 'Hapus',
                            color: const Color(0xFFEF4444),
                            onPressed: () => _deleteUser(userId),
                          ),
                        ],
                      ),
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

  Widget _buildMobileInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF4169E1).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF4169E1)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                  _loadUsers();
                }
              : null,
          icon: const Icon(Icons.chevron_left),
          color: const Color(0xFF4169E1),
          disabledColor: Colors.grey[400],
        ),

        const SizedBox(width: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Halaman $_currentPage dari $_totalPages',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),

        const SizedBox(width: 16),

        IconButton(
          onPressed: _currentPage < _totalPages
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                  _loadUsers();
                }
              : null,
          icon: const Icon(Icons.chevron_right),
          color: const Color(0xFF4169E1),
          disabledColor: Colors.grey[400],
        ),
      ],
    );
  }

  Future<void> _viewUserDetail(Map<String, dynamic> user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailPenggunaPage(user: user)),
    );

    // Refresh if user was updated
    if (result == true) {
      _loadUsers();
    }
  }

  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Hapus',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengguna ini?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Hapus',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${_selectedUsers.length} pengguna yang dipilih?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performBulkDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Hapus Semua',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id_user', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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

  Future<void> _performBulkDelete() async {
    try {
      for (String userId in _selectedUsers) {
        await _supabase.from('users').delete().eq('id_user', userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedUsers.length} pengguna berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedUsers.clear();
        });
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
