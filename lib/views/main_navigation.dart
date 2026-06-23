import 'package:flutter/material.dart';
import 'kalender_view.dart';
import 'hari_ini_view.dart';
import 'history_view.dart'; 
import 'analisis_view.dart'; 
import 'profil_view.dart'; 

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HariIniView(),
    const KalenderView(),
    const HistoryView(), 
    const AnalisisView(), 
    const ProfilView(), 
  ];

  @override
  Widget build(BuildContext context) {
    // Membungkus dengan PopScope untuk mengatur perilaku tombol 'Back' di HP
    return PopScope(
      // canPop bernilai true (boleh keluar aplikasi) HANYA jika sedang di tab pertama (index 0)
      canPop: _currentIndex == 0, 
      onPopInvoked: (bool didPop) {
        // Jika didPop bernilai true, berarti Android sudah menutup aplikasinya. Biarkan saja.
        if (didPop) {
          return;
        }
        // Jika didPop false (karena kita di tab lain), cegah keluar dan paksa pindah ke tab 0 (Hari Ini)
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        extendBody: true, // Konten dapat berada di belakang nav bar melayang
        body: _pages[_currentIndex],
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD87093).withOpacity(0.2), 
                  blurRadius: 25, 
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white, 
                selectedItemColor: const Color(0xFFD87093), 
                unselectedItemColor: Colors.grey.shade400,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.2),
                unselectedLabelStyle: const TextStyle(fontSize: 10),
                elevation: 0,
                showUnselectedLabels: true,
                items: const [
                  BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.favorite_border)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.favorite)), label: 'Hari Ini'),
                  BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.calendar_month_outlined)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.calendar_month)), label: 'Kalender'),
                  BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.note_alt_outlined)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.note_alt)), label: 'Catatan'),
                  BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.analytics_outlined)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.analytics)), label: 'Analisis'),
                  BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)), label: 'Profil'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}