import 'package:flutter/material.dart';
import 'kalender_view.dart';

class PlaceholderView extends StatelessWidget {
  final String judul;
  const PlaceholderView({super.key, required this.judul});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Halaman $judul\n(Akan segera dibangun)',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PlaceholderView(judul: 'Hari Ini'),
    const KalenderView(),
    const PlaceholderView(judul: 'Catatan'),
    const PlaceholderView(judul: 'Analisis'),
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