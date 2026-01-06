import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://rznsjgxqiigzwvnlwkyi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6bnNqZ3hxaWlnend2bmx3a3lpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY0MTI4MTgsImV4cCI6MjA1MTk4ODgxOH0.p4vKVnqE7MBT5pOgMNJdx9VQV-iJlKTfHsGwdRYdFmw',
  );

  final supabase = Supabase.instance.client;

  print('========== TESTING ADMIN LOGIN ==========\n');

  // Test 1: Get all admin records
  print('1. Fetching all admin records...');
  try {
    final admins = await supabase
        .from('admin')
        .select(
          'id_admin, username_admin, email_admin, role, status, password_admin',
        )
        .limit(10);

    print('Found ${admins.length} admin records:');
    for (var admin in admins) {
      print('  - Email: ${admin['email_admin']}');
      print('    Username: ${admin['username_admin']}');
      print('    Role: ${admin['role']}');
      print('    Status: ${admin['status']}');
      print(
        '    Password (first 10 chars): ${admin['password_admin']?.toString().substring(0, 10)}...',
      );
      print(
        '    Password length: ${admin['password_admin']?.toString().length}',
      );
      print('');
    }
  } catch (e) {
    print('Error fetching admins: $e');
  }

  print('\n========== TEST COMPLETED ==========');
}
