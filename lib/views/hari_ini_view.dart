import 'package:flutter/material.dart';
import '../services/db_service.dart';
import 'siklus_saya_view.dart'; 

class HariIniView extends StatefulWidget {
  const HariIniView({super.key});

  @override
  State<HariIniView> createState() => _HariIniViewState();
}

class _HariIniViewState extends State<HariIniView> {
  bool _isLoading = true;
  Map<String, dynamic>? _haidAktif; 
  
  int _hariKe = 0;
  String _prediksiHaid = '-';
  String _masaSubur = '-';
  String _ovulasi = '-';
  
  String _rataHaid = '...'; 
  String _rataSiklus = '...'; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseService.instance.readAllData();
    
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
      
      final hariIni = DateTime.now();
      _hariKe = hariIni.difference(haidTerbaru).inDays + 1;
      
      int avgCycle = validCycleCount > 0 ? (totalCycleDays / validCycleCount).round() : 28;
      int avgHaid = validHaidCount > 0 ? (totalHaidDays / validHaidCount).round() : 7;
      
      _rataHaid = '$avgHaid Hari';
      _rataSiklus = '$avgCycle Hari';

      final nextHaid = haidTerbaru.add(Duration(days: avgCycle));
      _prediksiHaid = '${nextHaid.day}/${nextHaid.month}/${nextHaid.year}';
      
      final ovulasiDate = nextHaid.subtract(const Duration(days: 14));
      _ovulasi = '${ovulasiDate.day}/${ovulasiDate.month}';
      
      final suburMulai = ovulasiDate.subtract(const Duration(days: 4));
      final suburSelesai = ovulasiDate.add(const Duration(days: 1));
      _masaSubur = '${suburMulai.day}/${suburMulai.month} - ${suburSelesai.day}/${suburSelesai.month}';
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

  Widget _buildInfoBox(String title, String value, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isSedangHaid = _haidAktif != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Hari Ini', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan Siklus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoBox('Siklus Saat Ini', _hariKe == 0 ? '-' : 'Hari Ke-$_hariKe', Colors.pink),
                  _buildInfoBox('Haid Berikutnya', _prediksiHaid, Colors.purple),
                  _buildInfoBox('Masa Subur', _masaSubur, Colors.orange),
                  _buildInfoBox('Hari Ovulasi', _ovulasi, Colors.orange[800]!),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text('Siklus Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Ketuk untuk melihat detail grafik riwayat', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SiklusSayaView()));
              },
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.water_drop, color: Colors.pink),
                          const SizedBox(height: 12),
                          Text(_rataHaid, style: const TextStyle(color: Colors.pink, fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('Rata-rata haid', style: TextStyle(color: Colors.pink, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.pie_chart, color: Colors.orange),
                          const SizedBox(height: 12),
                          Text(_rataSiklus, style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('Rata-rata siklus', style: TextStyle(color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _toggleHaid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSedangHaid ? Colors.purple[300] : Colors.pinkAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isSedangHaid ? Icons.check_circle : Icons.add, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      isSedangHaid ? 'Akhiri Haid' : 'Mulai Haid',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}