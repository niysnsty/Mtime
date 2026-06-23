import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/db_service.dart';

class AnalisisView extends StatefulWidget {
  const AnalisisView({super.key});

  @override
  State<AnalisisView> createState() => _AnalisisViewState();
}

class _AnalisisViewState extends State<AnalisisView> {
  bool _isLoading = true;
  int _siklusTerpendek = 0, _siklusTerpanjang = 0;
  int _haidTerpendek = 0, _haidTerpanjang = 0;
  String _gejalaSering = 'Belum ada gejala tercatat.';
  String _rataSiklusProfil = '28';
  List<FlSpot> _chartDataSiklus = [];
  List<String> _chartLabels = [];

  @override
  void initState() {
    super.initState();
    _kalkulasiAnalisis();
  }

  Future<void> _kalkulasiAnalisis() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await DatabaseService.instance.readAllData();
    _rataSiklusProfil = prefs.getString('rata_siklus') ?? '28';
    
    int minCycle = 999, maxCycle = 0;
    int minHaid = 999, maxHaid = 0;
    Map<String, int> hitungGejala = {};

    for (int i = 0; i < data.length; i++) {
      final tglMulai = DateTime.parse(data[i]['tanggal_mulai']);
      final tglSelesai = data[i]['tanggal_selesai'] != null ? DateTime.parse(data[i]['tanggal_selesai']) : null;
      
      // Hitung Durasi Haid
      if (tglSelesai != null) {
        int durasiHaid = tglSelesai.difference(tglMulai).inDays + 1;
        if (durasiHaid < minHaid) minHaid = durasiHaid;
        if (durasiHaid > maxHaid) maxHaid = durasiHaid;
      }

      // Hitung Durasi Siklus (Sinkron dengan HistoryView)
      int durasiSiklus = int.tryParse(_rataSiklusProfil) ?? 28;
      if (i > 0) { // Hitung jarak dengan bulan sebelumnya
        final nextStart = DateTime.parse(data[i-1]['tanggal_mulai']);
        durasiSiklus = nextStart.difference(tglMulai).inDays;
      }
      
      if (durasiSiklus < minCycle) minCycle = durasiSiklus;
      if (durasiSiklus > maxCycle) maxCycle = durasiSiklus;

      // Hitung Gejala
      String gejalaStr = data[i]['gejala'] ?? '';
      if (gejalaStr.isNotEmpty && gejalaStr != 'Belum ada gejala') {
        for (var g in gejalaStr.split(',')) {
          String bersih = g.trim();
          if (bersih.isNotEmpty) hitungGejala[bersih] = (hitungGejala[bersih] ?? 0) + 1;
        }
      }
    }

    String topGejala = 'Belum ada gejala tercatat.';
    if (hitungGejala.isNotEmpty) {
      var sortedGejala = hitungGejala.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topGejala = sortedGejala.take(3).map((e) => e.key).join(', ');
    }

    // Siapkan data untuk Chart
    List<FlSpot> spots = [];
    List<String> labels = [];
    int count = 0;
    // Ambil maksimal 6 siklus yang sudah selesai (dari i=1 karena i=0 adalah siklus berjalan)
    for (int i = 1; i < data.length && count < 6; i++) {
      final tglMulai = DateTime.parse(data[i]['tanggal_mulai']);
      final nextStart = DateTime.parse(data[i - 1]['tanggal_mulai']);
      int durasi = nextStart.difference(tglMulai).inDays;

      spots.insert(0, FlSpot(0, durasi.toDouble())); // insert di index 0 untuk membalik urutan (terlama ke terbaru)
      labels.insert(0, '${tglMulai.day}/${tglMulai.month}');
      count++;
    }

    // Sesuaikan koordinat X
    for (int j = 0; j < spots.length; j++) {
      spots[j] = FlSpot(j.toDouble(), spots[j].y);
    }

    if (mounted) {
      setState(() {
        _siklusTerpendek = minCycle == 999 ? (int.tryParse(_rataSiklusProfil) ?? 28) : minCycle;
        _siklusTerpanjang = maxCycle == 0 ? (int.tryParse(_rataSiklusProfil) ?? 28) : maxCycle;
        _haidTerpendek = minHaid == 999 ? 7 : minHaid;
        _haidTerpanjang = maxHaid == 0 ? 7 : maxHaid;
        _gejalaSering = topGejala;
        _chartDataSiklus = spots;
        _chartLabels = labels;
        _isLoading = false;
      });
    }
  }

  Widget _buildCardInfo(String title, int min, int max, String subtitle) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Terpendek', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('$min', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF9E4770), height: 1)), const SizedBox(width: 4), const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('hari', style: TextStyle(color: Colors.grey)))]),
                ],
              ),
              Container(height: 40, width: 1, color: Colors.grey.shade300),
              Column(
                children: [
                  const Text('Terpanjang', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('$max', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF9E4770), height: 1)), const SizedBox(width: 4), const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('hari', style: TextStyle(color: Colors.grey)))]),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 10, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF48FB1), Color(0xFFCE93D8)]), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),
          Center(child: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFFFFF7F8), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      appBar: AppBar(title: const Text('MTime', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analisis Kesehatan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
            const SizedBox(height: 8),
            const Text('Lihat perkembangan tubuhmu berdasarkan catatan riwayat.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),

            _buildCardInfo('Durasi Menstruasi', _haidTerpendek, _haidTerpanjang, 'Rentang lama hari Anda mengalami pendarahan.'),
            const SizedBox(height: 20),
            _buildCardInfo('Durasi Siklus', _siklusTerpendek, _siklusTerpanjang, 'Jarak antara hari pertama haid dengan haid berikutnya.'),
            const SizedBox(height: 30),

            _buildChartSiklus(),
            const SizedBox(height: 30),

            const Text('Gejala Paling Sering', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.pink.shade50)),
              child: Text(_gejalaSering, style: const TextStyle(fontSize: 16, color: Color(0xFF9E4770), fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSiklus() {
    if (_chartDataSiklus.isEmpty) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tren Durasi Siklus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
            const SizedBox(height: 20),
            Center(child: Text("Tambahkan lebih banyak riwayat (minimal 2) untuk melihat grafik tren siklus Anda.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400))),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tren Durasi Siklus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < _chartLabels.length) {
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_chartLabels[index], style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartDataSiklus,
                    isCurved: true,
                    color: const Color(0xFFD87093),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFD87093).withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}