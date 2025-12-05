import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController(
    text: 'Adent',
  );
  final TextEditingController _npmController = TextEditingController(
    text: '2170001',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'Adent**@gmail.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '••••••••••••',
  );
  final TextEditingController _tanggalLahirController = TextEditingController(
    text: '01/01/2002',
  );

  bool _isEditingUsername = false;
  bool _isEditingNpm = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;
  bool _isEditingTanggalLahir = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _npmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tanggalLahirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title: const Text(
          'Unit Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blue[700]),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Card Profile
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Username
                      _buildProfileField(
                        label: 'USERNAME',
                        controller: _usernameController,
                        isEditing: _isEditingUsername,
                        onEditPressed: () {
                          setState(() {
                            _isEditingUsername = !_isEditingUsername;
                          });
                        },
                      ),

                      // NPM
                      _buildProfileField(
                        label: 'NPM',
                        controller: _npmController,
                        isEditing: _isEditingNpm,
                        onEditPressed: () {
                          setState(() {
                            _isEditingNpm = !_isEditingNpm;
                          });
                        },
                      ),

                      // Email
                      _buildProfileField(
                        label: 'EMAIL',
                        controller: _emailController,
                        isEditing: _isEditingEmail,
                        icon: Icons.email_outlined,
                        onEditPressed: () {
                          setState(() {
                            _isEditingEmail = !_isEditingEmail;
                          });
                        },
                      ),

                      // Password
                      _buildProfileField(
                        label: 'PASSWORD',
                        controller: _passwordController,
                        isEditing: _isEditingPassword,
                        icon: Icons.lock_outline,
                        obscureText: true,
                        onEditPressed: () {
                          setState(() {
                            _isEditingPassword = !_isEditingPassword;
                          });
                        },
                      ),

                      // Tanggal Lahir
                      _buildProfileField(
                        label: 'TANGGAL LAHIR',
                        controller: _tanggalLahirController,
                        isEditing: _isEditingTanggalLahir,
                        icon: Icons.calendar_today_outlined,
                        onEditPressed: () {
                          setState(() {
                            _isEditingTanggalLahir = !_isEditingTanggalLahir;
                          });
                        },
                      ),

                      // Save Button (show when any field is being edited)
                      if (_isEditingUsername ||
                          _isEditingNpm ||
                          _isEditingEmail ||
                          _isEditingPassword ||
                          _isEditingTanggalLahir)
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditingUsername = false;
                                  _isEditingNpm = false;
                                  _isEditingEmail = false;
                                  _isEditingPassword = false;
                                  _isEditingTanggalLahir = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Perubahan berhasil disimpan',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle logout
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Apakah Anda yakin ingin keluar?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Perform logout
                              Navigator.pop(context);
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditPressed,
    IconData? icon,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: controller,
                        obscureText: obscureText && isEditing,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue[700]!),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blue[700]!,
                              width: 2,
                            ),
                          ),
                        ),
                        autofocus: true,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.text,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(height: 1, color: Colors.grey[300]),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEditPressed,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.grey[600],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
