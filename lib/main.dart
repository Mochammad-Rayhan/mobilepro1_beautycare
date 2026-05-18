import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/sign_in_screen.dart';

import 'package:beautycare/database/db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ambil dan print semua user di console untuk melihat email dan password
  final dbHelper = DBHelper();
  final users = await dbHelper.getAllUsers();
  print('=== DATA USER TERDAFTAR ===');
  for (var user in users) {
    print('Nama: ${user.name}, Email: ${user.email}, Password: ${user.password}');
  }
  print('===========================');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beautycare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SignInScreen(),
    );
  }
}
