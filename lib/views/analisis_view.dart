import 'package:flutter/material.dart';
import 'dart:math';
import '../services/db_service.dart';
import 'edit_profil_view.dart'; // Tambahan untuk navigasi UX

class AnalisisView extends StatefulWidget {
  const AnalisisView({super.key});

  @override
  State<AnalisisView> createState() => _AnalisisViewState();
}

class _AnalisisViewState extends State<AnalisisView> {
  bool _isLoading = true;
  
  int _siklusTerpanjang = 0;
  int _siklusTerpendek = 0;
  int _totalSiklus = 0;
  int _rataSiklus = 0;
  List<String> _topGejala = [];

  @override
  void initState() {
    super.initState();
    _loadDataAnalisis();
  }

  Future<void> _loadDataAnalisis() async {
    final data = await DatabaseService.instance.readAllData();
    
    if (data.length > 1) {
      List<int> cycleLengths = [];
      Map<String, int> frekuensiGejala = {};
      int totalDays = 0;

      for (int i = 0; i < data.length - 1; i++) {
        final currentStart = DateTime.parse(data[i]['tanggal_mulai']);
        final previousStart = DateTime.parse(data[i+1]['tanggal_mulai']);
        int diff = currentStart.difference(previousStart).inDays;
        if (diff > 0) {
          cycleLengths.add(diff);
          totalDays += diff;
        }
      }

      if (cycleLengths.isNotEmpty) {
        _siklusTerpanjang = cycleLengths.reduce(max);
        _siklusTerpendek = cycleLengths.reduce(min);
        _rataSiklus = (totalDays / cycleLengths.length).round();
      }

      for (var item in data) {
        String gejalaRaw = item['gejala'] ?? '';
        if (gejalaRaw.isNotEmpty && 
            gejalaRaw.toLowerCase() != 'belum ada gejala' && 
            gejalaRaw.toLowerCase() != 'tidak ada gejala') {
          
          List<String> listGejala = gejalaRaw.split(',');
          for (var g in listGejala) {
            String kata = g.trim();
            if (kata.length > 2) {
              frekuensiGejala[kata] = (frekuensiGejala[kata] ?? 0) + 1;
            }
          }
        }
      }

      var sortedGejala = frekuensiGejala.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topGejala = sortedGejala.take(3).map((e) => e.key).toList();
    }

    if (mounted) {
      setState(() {
        _totalSiklus = data.length;
        _isLoading = false;
      });
    }
  }

  Widget _buildSymptomChip(String label) {
    Color bgColor;
    Color textColor;
    IconData icon;

    String lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('kram')) {
      bgColor = const Color(0xFFFCE4EC); 
      textColor = const Color(0xFF9E4770); 
      icon = Icons.water_drop_outlined;
    } else if (lowerLabel.contains('lelah') || lowerLabel.contains('kelelahan')) {
      bgColor = const Color(0xFFF3E5F5); 
      textColor = const Color(0xFF8E24AA); 
      icon = Icons.battery_alert_outlined;
    } else if (lowerLabel.contains('jerawat')) {
      bgColor = const Color(0xFFE8F5E9); 
      textColor = const Color(0xFF2E7D32); 
      icon = Icons.face_outlined;
    } else {
      bgColor = Colors.grey.shade100;
      textColor = const Color(0xFF6A304C);
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: textColor, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFFFFF7F8), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      appBar: AppBar(
        title: const Text('MTime', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        // --- UX: FOTO PROFIL BISA DIKLIK ---
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView()));
            },
            child: const CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5')),
          ),
        ),
        // --- UX: IKON PENGATURAN BISA DIKLIK ---
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined), 
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView()));
            }
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analisis Kesehatan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text('Lihat perkembangan tubuhmu bulan ini.', style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 30),

            if (_totalSiklus < 2) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.pink.shade100, width: 2, style: BorderStyle.solid))),
                        Container(width: 110, height: 110, decoration: const BoxDecoration(color: Color(0xFFFCE4EC), shape: BoxShape.circle)),
                        const Icon(Icons.insert_chart_outlined, size: 60, color: Color(0xFFD87093)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text('Data belum cukup.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    const Text('Catat setidaknya 2 siklus untuk\nmelihat laporan mendalam.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15)),
                    const SizedBox(height: 40),
                    // --- UX: TOMBOL MULAI CATAT BERFUNGSI ---
                    ElevatedButton(
                      onPressed: () {
                        // Mengingatkan user untuk pindah ke tab Beranda/Hari Ini
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Silakan pindah ke tab "Hari Ini" untuk mulai mencatat siklus haidmu.'),
                            backgroundColor: Color(0xFF9E4770),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9E4770),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Mulai Catat Sekarang', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              )
            ] else ...[
              const Text('Variasi Siklus', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Siklus Terpendek', style: TextStyle(color: Colors.grey, fontSize: 14)), const SizedBox(height: 8), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('$_siklusTerpendek', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF9E4770), height: 1)), const SizedBox(width: 6), const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('hari', style: TextStyle(color: Colors.grey)))])])),
                        Container(width: 1, height: 50, color: Colors.grey.shade200), 
                        const SizedBox(width: 20),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Siklus Terpanjang', style: TextStyle(color: Colors.grey, fontSize: 14)), const SizedBox(height: 8), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('$_siklusTerpanjang', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF8E4473), height: 1)), const SizedBox(width: 6), const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('hari', style: TextStyle(color: Colors.grey)))])])),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: const LinearGradient(colors: [Color(0xFFF8BBD0), Color(0xFF9E4770), Color(0xFFCE93D8)], stops: [0.0, 0.5, 1.0]))),
                    const SizedBox(height: 16),
                    Text('Rata-rata siklus Anda adalah $_rataSiklus hari.', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text('Gejala Paling Sering', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _topGejala.isEmpty
                  ? const Text('Belum ada gejala tercatat.', style: TextStyle(color: Colors.grey))
                  : Wrap(spacing: 12, runSpacing: 12, children: _topGejala.map((g) => _buildSymptomChip(g)).toList()),
            ],
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }
}