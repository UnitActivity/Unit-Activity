import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotifikasiUKMPage extends StatefulWidget {
  const NotifikasiUKMPage({super.key});

  @override
  State<NotifikasiUKMPage> createState() => _NotifikasiUKMPageState();
}

class _NotifikasiUKMPageState extends State<NotifikasiUKMPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifikasi',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Halaman Notifikasi - Dalam Pengembangan',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
