import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _namaController = TextEditingController();
  final _rataHaidController = TextEditingController();
  final _rataSiklusController = TextEditingController();

  Future<void> _prosesMulai() async {
    if (_namaController.text.isNotEmpty && 
        _rataHaidController.text.isNotEmpty && 
        _rataSiklusController.text.isNotEmpty) {
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nama', _namaController.text);
      await prefs.setString('rata_haid', _rataHaidController.text);
      await prefs.setString('rata_siklus', _rataSiklusController.text);
      
      await prefs.setBool('is_logged_in', true); 

      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const MainNavigation())
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data untuk personalisasi.'), 
          backgroundColor: Colors.red
        )
      );
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
              const Icon(Icons.water_drop, size: 80, color: Color(0xFF9E4770)),
              const SizedBox(height: 30),
              const Text('Selamat Datang di MTime', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
              const SizedBox(height: 10),
              const Text(
                'Mari personalisasi pengalamanmu agar prediksi siklus menjadi lebih akurat.', 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey, fontSize: 14)
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _namaController, 
                decoration: InputDecoration(
                  hintText: 'Siapa nama panggilanmu?', 
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9E4770)),
                  filled: true, fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)
                )
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _rataHaidController, 
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Lama haid (Contoh: 7)', 
                  prefixIcon: const Icon(Icons.opacity, color: Color(0xFF9E4770)),
                  filled: true, fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)
                )
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _rataSiklusController, 
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Jarak siklus (Contoh: 28)', 
                  prefixIcon: const Icon(Icons.sync, color: Color(0xFF9E4770)),
                  filled: true, fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)
                )
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _prosesMulai,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9E4770), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                    shadowColor: Colors.pinkAccent.withOpacity(0.5)
                  ),
                  child: const Text('Mulai Perjalanan MTime', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}