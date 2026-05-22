import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';
import 'edit_profil_view.dart';

class HariIniView extends StatefulWidget {
  const HariIniView({super.key});

  @override
  State<HariIniView> createState() => _HariIniViewState();
}

class _HariIniViewState extends State<HariIniView> {
  bool _isLoading = true;
  Map<String, dynamic>? _haidAktif; 
  
  int _hariKe = 0;
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

    if (data.isNotEmpty) {
      for (int i = 0; i < data.length; i++) {
        if (data[i]['tanggal_selesai'] == null) {
          haidBelumSelesai = data[i];
          break; 
        }
      }

      haidTerbaru = DateTime.parse(data.first['tanggal_mulai']);
      _hariKe = DateTime.now().difference(haidTerbaru).inDays + 1;
      
      int cycleDays = int.tryParse(savedSiklus) ?? 28;
      final nextHaid = haidTerbaru.add(Duration(days: cycleDays));
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
      _hariKe = 0;
    }

    if (mounted) {
      setState(() {
        _haidAktif = haidBelumSelesai;
        _namaUser = savedNama;
        _rataHaid = savedHaid;       
        _rataSiklus = savedSiklus;   
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Haid dimulai!'), backgroundColor: Colors.pink));
    } else {
      final updateData = Map<String, dynamic>.from(_haidAktif!);
      updateData['tanggal_selesai'] = DateTime.now().toIso8601String();
      await DatabaseService.instance.updateData(updateData);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Haid diakhiri.'), backgroundColor: Colors.purple));
    }
    _loadData(); 
  }

  Widget _buildAvatar() {
    if (_photo.isEmpty) {
      return CircleAvatar(radius: 20, backgroundColor: Colors.grey.shade300, child: const Icon(Icons.person, size: 24, color: Colors.white));
    } else {
      return CircleAvatar(radius: 20, backgroundImage: FileImage(File(_photo)), backgroundColor: Colors.transparent);
    }
  }

  Widget _buildScrollableCard(String title, String mainValue, String subText, {double? progress}) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16, bottom: 10, top: 5),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
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
    if (_hariKe > 0 && isSedangHaid) {
      int avgHaid = int.tryParse(_rataHaid) ?? 7;
      progress = (_hariKe / avgHaid).clamp(0.0, 1.0);
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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        GestureDetector(onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView())); _loadData(); }, child: _buildAvatar()),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Halo, $_namaUser', style: const TextStyle(fontSize: 12, color: Colors.grey)), const Text('MTime', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6A304C)))]),
                      ],
                    ),
                  ),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // LOGIKA BARU KARTU STATUS
                        isSedangHaid
                            ? _buildScrollableCard('Sedang Menstruasi', 'Haid Hari ke-$_hariKe', 'Tetap terhidrasi', progress: progress)
                            : _buildScrollableCard('Status Siklus', 'Selesai Haid', 'Rata-rata $_rataSiklus Hari'),
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
                        Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF48FB1), borderRadius: BorderRadius.circular(25)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.water_drop_outlined, color: Color(0xFF6A304C)), const SizedBox(height: 16), const Text('Rata-rata Haid', style: TextStyle(color: Color(0xFF6A304C), fontSize: 13)), const SizedBox(height: 4), Text('$_rataHaid Hari', style: const TextStyle(color: Color(0xFF6A304C), fontSize: 24, fontWeight: FontWeight.bold))]))),
                        const SizedBox(width: 16),
                        Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFFFCA28), borderRadius: BorderRadius.circular(25)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.sync_alt, color: Color(0xFF6A304C)), const SizedBox(height: 16), const Text('Rata-rata Siklus', style: TextStyle(color: Color(0xFF6A304C), fontSize: 13)), const SizedBox(height: 4), Text('$_rataSiklus Hari', style: const TextStyle(color: Color(0xFF6A304C), fontSize: 24, fontWeight: FontWeight.bold))]))),
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