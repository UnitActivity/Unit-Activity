import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AkunUKMPage extends StatefulWidget {
  const AkunUKMPage({super.key});

  @override
  State<AkunUKMPage> createState() => _AkunUKMPageState();
}

class _AkunUKMPageState extends State<AkunUKMPage> {
  bool _isEditingPassword = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Profile Page',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Image Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Unit',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Basketball',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Icon(
                        Icons.sports_basketball,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                SizedBox(
                  width: 500,
                  child: Column(
                    children: [
                      _buildProfileField(
                        label: 'Username',
                        value: 'Unit Basket',
                        hasEdit: false,
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Email',
                        value: 'unitbasket@ukdc.ac.id',
                        hasEdit: false,
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'ID UKM',
                        value: '001',
                        hasEdit: false,
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Password',
                        value: '**************',
                        hasEdit: true,
                        onEdit: () {
                          setState(() {
                            _isEditingPassword = !_isEditingPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Password',
                        value: '**************',
                        hasEdit: true,
                        onEdit: () {
                          setState(() {
                            _isEditingPassword = !_isEditingPassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required bool hasEdit,
    VoidCallback? onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[800]),
            ),
          ),
        ),
        if (hasEdit) ...[
          const SizedBox(width: 12),
          InkWell(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.edit, size: 18, color: Colors.grey[600]),
            ),
          ),
        ],
      ],
    );
  }
}
