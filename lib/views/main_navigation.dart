import 'package:flutter/material.dart';
import 'kalender_view.dart';
import 'hari_ini_view.dart';
import 'history_view.dart'; 
import 'analisis_view.dart'; // Import halaman Analisis yang baru

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Semua 4 Tab sekarang sudah terisi oleh halaman asli!
  final List<Widget> _pages = [
    const HariIniView(),
    const KalenderView(),
    const HistoryView(), 
    const AnalisisView(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Hari Ini'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Kalender'),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: 'Catatan'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analisis'),
        ],
      ),
    );
  }
}