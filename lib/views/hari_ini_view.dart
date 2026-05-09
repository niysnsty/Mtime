import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahan untuk memori
import '../services/db_service.dart';
import 'edit_profil_view.dart'; // Tambahan untuk navigasi ke Edit Profil

class HariIniView extends StatefulWidget {
  const HariIniView({super.key});

  @override
  State<HariIniView> createState() => _HariIniViewState();
}

class _HariIniViewState extends State<HariIniView> {
  bool _isLoading = true;
  Map<String, dynamic>? _haidAktif; 
  
  int _hariKe = 0;
  String _rataHaid = '...'; 
  String _rataSiklus = '...'; 
  
  String _prediksiHaid = '-';
  String _masaSubur = '-';
  String _ovulasi = '-';

  // UX: Variabel dinamis untuk nama pengguna
  String _namaUser = 'Sarah';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _namaBulanSingkat(int month) {
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return bulan[month - 1];
  }

  Future<void> _loadData() async {
    final data = await DatabaseService.instance.readAllData();
    
    // --- UX: Mengambil nama pengguna dari memori HP ---
    final prefs = await SharedPreferences.getInstance();
    final namaTersimpan = prefs.getString('nama');
    if (namaTersimpan != null && namaTersimpan.isNotEmpty) {
      _namaUser = namaTersimpan;
    }
    
    Map<String, dynamic>? haidBelumSelesai;
    DateTime? haidTerbaru;
    
    int totalHaidDays = 0;
    int validHaidCount = 0;
    int totalCycleDays = 0;
    int validCycleCount = 0;

    if (data.isNotEmpty) {
      for (int i = 0; i < data.length; i++) {
        if (data[i]['tanggal_selesai'] == null) {
          haidBelumSelesai = data[i];
        } else {
          final start = DateTime.parse(data[i]['tanggal_mulai']);
          final end = DateTime.parse(data[i]['tanggal_selesai']);
          totalHaidDays += end.difference(start).inDays + 1;
          validHaidCount++;
        }

        if (i < data.length - 1) {
          final currentStart = DateTime.parse(data[i]['tanggal_mulai']);
          final previousStart = DateTime.parse(data[i+1]['tanggal_mulai']);
          totalCycleDays += currentStart.difference(previousStart).inDays;
          validCycleCount++;
        }
      }

      haidTerbaru = DateTime.parse(data.first['tanggal_mulai']);
      _hariKe = DateTime.now().difference(haidTerbaru).inDays + 1;
      
      int avgCycle = validCycleCount > 0 ? (totalCycleDays / validCycleCount).round() : 28;
      int avgHaid = validHaidCount > 0 ? (totalHaidDays / validHaidCount).round() : 5;
      
      _rataHaid = '$avgHaid Hari';
      _rataSiklus = '$avgCycle Hari';

      final nextHaid = haidTerbaru.add(Duration(days: avgCycle));
      _prediksiHaid = '${nextHaid.day} ${_namaBulanSingkat(nextHaid.month)}';
      
      final ovulasiDate = nextHaid.subtract(const Duration(days: 14));
      _ovulasi = '${ovulasiDate.day} ${_namaBulanSingkat(ovulasiDate.month)}';
      
      final suburMulai = ovulasiDate.subtract(const Duration(days: 4));
      final suburSelesai = ovulasiDate.add(const Duration(days: 1));
      
      if (suburMulai.month == suburSelesai.month) {
        _masaSubur = '${suburMulai.day}-${suburSelesai.day} ${_namaBulanSingkat(suburSelesai.month)}';
      } else {
        _masaSubur = '${suburMulai.day} ${_namaBulanSingkat(suburMulai.month)} - ${suburSelesai.day} ${_namaBulanSingkat(suburSelesai.month)}';
      }

    } else {
      _rataHaid = '0 Hari';
      _rataSiklus = '0 Hari';
    }

    if (mounted) {
      setState(() {
        _haidAktif = haidBelumSelesai;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleHaid() async {
    setState(() => _isLoading = true);

    if (_haidAktif == null) {
      final newData = {
        'tanggal_mulai': DateTime.now().toIso8601String(),
        'tanggal_selesai': null,
        'gejala': 'Belum ada gejala',
        'catatan': '',
      };
      await DatabaseService.instance.insertData(newData);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Haid dimulai!'), backgroundColor: Colors.pink));
    } else {
      final updateData = Map<String, dynamic>.from(_haidAktif!);
      updateData['tanggal_selesai'] = DateTime.now().toIso8601String();
      await DatabaseService.instance.updateData(updateData);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Haid diakhiri.'), backgroundColor: Colors.purple));
    }
    _loadData(); 
  }

  Widget _buildScrollableCard(String title, String mainValue, String subText, {double? progress}) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16, bottom: 10, top: 5),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.pink.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF6A304C), fontSize: 14)),
          const SizedBox(height: 8),
          Text(mainValue, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF9E4770))),
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: const Color(0xFFFCE4EC), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD87093)))),
          ] else ...[
             const SizedBox(height: 16),
             Text(subText, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isSedangHaid = _haidAktif != null;
    double progress = 0.0;
    if (_rataSiklus != '0 Hari' && _rataSiklus != '...') {
      int avg = int.tryParse(_rataSiklus.split(' ')[0]) ?? 28;
      progress = (_hariKe / avg).clamp(0.0, 1.0);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- UX: HEADER SEKARANG INTERAKTIF & DINAMIS ---
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                // UX: Klik foto profil langsung buka menu edit profil
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView()));
                                _loadData(); // Muat ulang data kalau namanya diganti
                              },
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // NAMA SEKARANG OTOMATIS SESUAI PROFIL!
                                Text('Halo, $_namaUser', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const Text('MTime', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Color(0xFF6A304C)), 
                          onPressed: () async {
                            // UX: Klik ikon setting juga membuka edit profil
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView()));
                            _loadData();
                          }
                        ),
                      ],
                    ),
                  ),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildScrollableCard('Siklus Saat Ini', 'Hari ke-$_hariKe', '', progress: progress),
                        _buildScrollableCard('Haid Berikutnya', _prediksiHaid, 'Estimasi kedatangan'),
                        _buildScrollableCard('Masa Subur', _masaSubur, 'Peluang hamil tinggi'),
                        _buildScrollableCard('Hari Ovulasi', _ovulasi, 'Puncak masa subur'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF48FB1), borderRadius: BorderRadius.circular(25)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.water_drop_outlined, color: Color(0xFF6A304C)), const SizedBox(height: 16), const Text('Rata-rata Haid', style: TextStyle(color: Color(0xFF6A304C), fontSize: 13)), const SizedBox(height: 4), Text(_rataHaid, style: const TextStyle(color: Color(0xFF6A304C), fontSize: 24, fontWeight: FontWeight.bold))]))),
                        const SizedBox(width: 16),
                        Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFFFCA28), borderRadius: BorderRadius.circular(25)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.sync_alt, color: Color(0xFF6A304C)), const SizedBox(height: 16), const Text('Rata-rata Siklus', style: TextStyle(color: Color(0xFF6A304C), fontSize: 13)), const SizedBox(height: 4), Text(_rataSiklus, style: const TextStyle(color: Color(0xFF6A304C), fontSize: 24, fontWeight: FontWeight.bold))]))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Insight Kesehatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.pink.withOpacity(0.2))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.lightbulb_outline, color: Color(0xFFAB47BC))),
                              const SizedBox(width: 16),
                              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tips Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A304C), fontSize: 14)), SizedBox(height: 4), Text('Minum air putih lebih banyak untuk mengurangi kembung saat fase luteal.', style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5))])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), 
                ],
              ),
            ),

            Positioned(
              bottom: 20, right: 20,
              child: ElevatedButton.icon(
                onPressed: _toggleHaid,
                icon: Icon(isSedangHaid ? Icons.stop_circle_outlined : Icons.add_circle_outline, color: const Color(0xFF6A304C)),
                label: Text(isSedangHaid ? 'Akhiri Haid' : 'Mulai Haid', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6A304C))),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF48FB1), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 5, shadowColor: Colors.pinkAccent.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}