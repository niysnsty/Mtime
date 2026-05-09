import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isObscured = true;

  Future<void> _prosesDaftar() async {
    if (_namaController.text.isNotEmpty && _emailController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nama', _namaController.text);
      await prefs.setString('email', _emailController.text);
      await prefs.setBool('is_logged_in', true); // Penanda akun aktif

      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const MainNavigation())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.favorite, size: 80, color: Color(0xFF9E4770)),
              const SizedBox(height: 40),
              const Text('Buat Akun MTime', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
              const SizedBox(height: 30),
              TextField(controller: _namaController, decoration: InputDecoration(hintText: 'Nama Lengkap', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
              const SizedBox(height: 15),
              TextField(controller: _emailController, decoration: InputDecoration(hintText: 'Email', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
              const SizedBox(height: 15),
              TextField(
                controller: _passController, 
                obscureText: _isObscured,
                decoration: InputDecoration(
                  hintText: 'Password', filled: true, fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  suffixIcon: IconButton(icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isObscured = !_isObscured)),
                )
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _prosesDaftar,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9E4770), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('Daftar Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}