import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';
import 'edit_profil_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'kalender_view.dart'; // Import untuk menggunakan sinyal refresh global

class HariIniView extends StatefulWidget {
  const HariIniView({super.key});

  @override
  State<HariIniView> createState() => _HariIniViewState();
}

class _HariIniViewState extends State<HariIniView> {
  bool _isLoading = true;
  Map<String, dynamic>? _haidAktif; 
  int _hariKe = 0;
  int _sisaHariKeHaid = 0;
  String _rataHaid = '7'; 
  String _rataSiklus = '28'; 
  String _prediksiHaid = '-';
  String _masaSubur = '-';
  String _ovulasi = '-';
  String _namaUser = 'Sarah';
  String _photo = ''; 

  @override
  void initState() {
    super.initState();
    _loadData();
    AppDataNotifier.refreshSignal.addListener(_loadData);
  }

  @override
  void dispose() {
    AppDataNotifier.refreshSignal.removeListener(_loadData);
    super.dispose();
  }

  String _namaBulanSingkat(int month) {
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return bulan[month - 1];
  }

  Future<void> _loadData() async {
    final data = await DatabaseService.instance.readAllData();
    final prefs = await SharedPreferences.getInstance();
    
    String savedNama = prefs.getString('nama') ?? 'Sarah';
    String savedHaid = prefs.getString('rata_haid') ?? '7';
    String savedSiklus = prefs.getString('rata_siklus') ?? '28';
    String savedPhoto = prefs.getString('user_photo') ?? '';

    String validPhoto = '';
    if (!savedPhoto.startsWith('http')) validPhoto = savedPhoto;
    
    Map<String, dynamic>? haidBelumSelesai;
    DateTime? haidTerbaru;

    // --- ALGORITMA "SMART LEARNING" DIMULAI DI SINI ---
    int dynamicAvgHaid = int.tryParse(savedHaid) ?? 7;
    int dynamicAvgSiklus = int.tryParse(savedSiklus) ?? 28;

    if (data.isNotEmpty) {
      // 1. Kalkulasi Rata-rata Durasi Haid Real-time
      int totalHaidDays = 0;
      int completedHaidCount = 0;
      for (var item in data) {
        if (item['tanggal_selesai'] != null) {
          DateTime start = DateTime.parse(item['tanggal_mulai']);
          DateTime end = DateTime.parse(item['tanggal_selesai']);
          totalHaidDays += end.difference(start).inDays + 1;
          completedHaidCount++;
        }
      }
      // Jika sudah ada riwayat haid yang selesai, ganti angka patokan profil dengan angka asli
      if (completedHaidCount > 0) {
        dynamicAvgHaid = (totalHaidDays / completedHaidCount).round();
      }

      // 2. Kalkulasi Rata-rata Durasi Siklus Real-time
      int totalSiklusDays = 0;
      int cycleCount = 0;
      // Butuh minimal 2 bulan data untuk menghitung 1 jarak siklus
      if (data.length >= 2) {
        for (int i = 0; i < data.length - 1; i++) {
          DateTime currentStart = DateTime.parse(data[i]['tanggal_mulai']);
          DateTime prevStart = DateTime.parse(data[i+1]['tanggal_mulai']);
          totalSiklusDays += currentStart.difference(prevStart).inDays;
          cycleCount++;
        }
        // Jika sudah ada jarak antar bulan, ganti angka patokan profil dengan rata-rata asli
        if (cycleCount > 0) {
          dynamicAvgSiklus = (totalSiklusDays / cycleCount).round();
        }
      }
      // --- ALGORITMA SELESAI ---

      // Cari apakah ada haid yang sedang berjalan (tanggal_selesai == null)
      for (int i = 0; i < data.length; i++) {
        if (data[i]['tanggal_selesai'] == null) {
          haidBelumSelesai = data[i];
          break; 
        }
      }

      haidTerbaru = DateTime.parse(data.first['tanggal_mulai']);
      _hariKe = DateTime.now().difference(haidTerbaru).inDays + 1;
      
      // Hitung prediksi berdasarkan Rata-rata Siklus yang BARU (Dinamis)
      final nextHaid = haidTerbaru.add(Duration(days: dynamicAvgSiklus));
      _prediksiHaid = '${nextHaid.day} ${_namaBulanSingkat(nextHaid.month)}';
      
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime nextHaidDate = DateTime(nextHaid.year, nextHaid.month, nextHaid.day);
      int sisaHari = nextHaidDate.difference(today).inDays;
      
      final ovulasiDate = nextHaid.subtract(const Duration(days: 14));
      _ovulasi = '${ovulasiDate.day} ${_namaBulanSingkat(ovulasiDate.month)}';
      
      final suburMulai = ovulasiDate.subtract(const Duration(days: 4));
      final suburSelesai = ovulasiDate.add(const Duration(days: 1));
      
      if (suburMulai.month == suburSelesai.month) {
        _masaSubur = '${suburMulai.day}-${suburSelesai.day} ${_namaBulanSingkat(suburSelesai.month)}';
      } else {
        _masaSubur = '${suburMulai.day} ${_namaBulanSingkat(suburMulai.month)} - ${suburSelesai.day} ${_namaBulanSingkat(suburSelesai.month)}';
      }
      
      if (mounted) {
        setState(() {
          _sisaHariKeHaid = sisaHari;
        });
      }
    } else {
      _hariKe = 0;
      if (mounted) {
        setState(() {
          _sisaHariKeHaid = 0;
        });
      }
    }

    if (mounted) {
      setState(() {
        _haidAktif = haidBelumSelesai;
        _namaUser = savedNama;
        // Gunakan nilai dinamis untuk ditampilkan di kartu
        _rataHaid = dynamicAvgHaid.toString();       
        _rataSiklus = dynamicAvgSiklus.toString();   
        _photo = validPhoto;         
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
    } else {
      final updateData = Map<String, dynamic>.from(_haidAktif!);
      updateData['tanggal_selesai'] = DateTime.now().toIso8601String();
      await DatabaseService.instance.updateData(updateData);
    }
    
    AppDataNotifier.triggerRefresh();
  }

  Widget _buildAvatar() {
    if (_photo.isEmpty) {
      return CircleAvatar(radius: 20, backgroundColor: Colors.grey.shade300, child: const Icon(Icons.person, size: 24, color: Colors.white));
    } else {
      return CircleAvatar(radius: 20, backgroundImage: FileImage(File(_photo)), backgroundColor: Colors.transparent);
    }
  }

  Widget _buildScrollableCard(String title, String mainValue, String subText, {double? progress, int delayMs = 0}) {
    return Container(
      width: 240, margin: const EdgeInsets.only(right: 20, bottom: 20, top: 10), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35), 
        boxShadow: [
          BoxShadow(color: const Color(0xFFD87093).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))
        ], 
        border: Border.all(color: Colors.white, width: 2)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFD87093)),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Color(0xFF6A304C), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Text(mainValue, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF9E4770), height: 1.2)),
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: const Color(0xFFFCE4EC), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD87093)))),
            const SizedBox(height: 8),
            Text(subText, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          ] else ...[
             const SizedBox(height: 8),
             Text(subText, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ]
        ],
      ),
    ).animate().fade(duration: 600.ms, delay: delayMs.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isSedangHaid = _haidAktif != null;
    double progress = 0.0;
    if (_hariKe > 0 && isSedangHaid) {
      int avgHaid = int.tryParse(_rataHaid) ?? 7;
      progress = (_hariKe / avgHaid).clamp(0.0, 1.0);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF7F8), Color(0xFFFCE4EC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
                      child: Row(
                        children: [
                          GestureDetector(onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView())); _loadData(); }, child: _buildAvatar().animate().scale(delay: 200.ms)),
                          const SizedBox(width: 16),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Halo, $_namaUser', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)), 
                            const Text('Semoga harimu menyenangkan! 🌸', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A304C)))
                          ]).animate().fade(delay: 300.ms).slideX(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      height: 250,
                      child: ListView(
                        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          isSedangHaid
                              ? _buildScrollableCard('Sedang Menstruasi', 'Haid Hari ke-$_hariKe', 'Tetap terhidrasi ya!', progress: progress, delayMs: 100)
                              : _buildScrollableCard('Status Siklus', _sisaHariKeHaid > 0 ? 'Haid $_sisaHariKeHaid hari lagi' : (_sisaHariKeHaid == 0 ? 'Haid hari ini' : 'Terlambat ${_sisaHariKeHaid.abs()} hari'), 'Rata-rata $_rataSiklus Hari', delayMs: 100),
                          _buildScrollableCard('Haid Berikutnya', _prediksiHaid, 'Estimasi kedatangan', delayMs: 200),
                          _buildScrollableCard('Masa Subur', _masaSubur, 'Peluang hamil tinggi', delayMs: 300),
                          _buildScrollableCard('Hari Ovulasi', _ovulasi, 'Puncak masa subur', delayMs: 400),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF48FB1), Color(0xFFD87093)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: const Color(0xFFD87093).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.water_drop, color: Colors.white)), const SizedBox(height: 20), const Text('Rata-rata Haid', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text('$_rataHaid Hari', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))])).animate().fade(delay: 500.ms).slideY(begin: 0.2)),
                          const SizedBox(width: 16),
                          Expanded(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFCA28), Color(0xFFFFA000)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: const Color(0xFFFFA000).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.sync_alt, color: Colors.white)), const SizedBox(height: 20), const Text('Rata-rata Siklus', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text('$_rataSiklus Hari', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))])).animate().fade(delay: 600.ms).slideY(begin: 0.2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), 
                  ],
                ),
              ),

              Positioned(
                bottom: 30, right: 24,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFD87093).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                    ]
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _toggleHaid,
                    icon: Icon(isSedangHaid ? Icons.stop_circle_rounded : Icons.add_circle_rounded, color: Colors.white),
                    label: Text(isSedangHaid ? 'Akhiri Haid' : 'Mulai Haid', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD87093), 
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)), 
                      elevation: 0, 
                    ),
                  ),
                ).animate().fade(delay: 800.ms).scale(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}