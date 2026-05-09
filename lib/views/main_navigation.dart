import 'package:flutter/material.dart';
import 'kalender_view.dart';
import 'hari_ini_view.dart';
import 'history_view.dart'; 
import 'analisis_view.dart'; 
import 'profil_view.dart'; // Import halaman Profil!

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Menambahkan Tab Profil menjadi yang ke-5
  final List<Widget> _pages = [
    const HariIniView(),
    const KalenderView(),
    const HistoryView(), 
    const AnalisisView(), 
    const ProfilView(), // Halaman baru!
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white, // Navbar putih bersih
          selectedItemColor: const Color(0xFFF48FB1), // Pink saat aktif
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Hari Ini'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Kalender'),
            BottomNavigationBarItem(icon: Icon(Icons.note_alt_outlined), activeIcon: Icon(Icons.note_alt), label: 'Catatan'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Analisis'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}