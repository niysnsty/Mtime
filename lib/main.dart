import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/main_navigation.dart';
import 'views/register_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(MTimeApp(startScreen: isLoggedIn ? const MainNavigation() : const RegisterView()));
}

class MTimeApp extends StatelessWidget {
  final Widget startScreen;
  const MTimeApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MTime',
      theme: ThemeData(primaryColor: const Color(0xFF9E4770)),
      home: startScreen, // Aplikasi akan memilih halaman awal secara otomatis
    );
  }
}