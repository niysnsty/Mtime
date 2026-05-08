import 'package:flutter/material.dart';
import '../services/db_service.dart';
import 'input_data_view.dart';

class SiklusSayaView extends StatefulWidget {
  const SiklusSayaView({super.key});

  @override
  State<SiklusSayaView> createState() => _SiklusSayaViewState();
}

class _SiklusSayaViewState extends State<SiklusSayaView> {
  List<Map<String, dynamic>> _riwayatData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseService.instance.readAllData();
    setState(() {
      _riwayatData = data;
      _isLoading = false;
    });
  }

  Widget _buildCustomBar(int haidDays, int cycleDays) {
    if (cycleDays < haidDays) cycleDays = haidDays + 1;
    
    int flexHaid = haidDays;
    int flexJeda1 = 7; 
    int flexOvulasi = 5; 
    int flexJeda2 = cycleDays - (flexHaid + flexJeda1 + flexOvulasi);
    if (flexJeda2 < 0) flexJeda2 = 0;

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: Colors.pink[50], // Latar belakang abu/pink sangat pudar
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 1. Bar Pink (Masa Haid)
          Expanded(
            flex: flexHaid,
            child: Container(
              decoration: BoxDecoration(color: Colors.pinkAccent, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text('$haidDays', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          // 2. Bar Kosong (Jeda 1)
          Expanded(flex: flexJeda1, child: const SizedBox()),
          // 3. Bar Kuning (Masa Ovulasi/Subur)
          Expanded(
            flex: flexOvulasi,
            child: Container(
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Icon(Icons.adjust, color: Colors.white, size: 14)), // Ikon target kecil
            ),
          ),
          // 4. Bar Kosong (Jeda 2)
          Expanded(flex: flexJeda2, child: const SizedBox()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Siklus saya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  const Text('Siklus saya', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${_riwayatData.length} siklus dicatat', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(15)),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(alignment: Alignment.topRight, child: Icon(Icons.water_drop, color: Colors.pink)),
                              SizedBox(height: 8),
                              Text('7 Hari', style: TextStyle(color: Colors.pink, fontSize: 22, fontWeight: FontWeight.bold)),
                              Text('Rata-rata haid', style: TextStyle(color: Colors.pink, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(15)),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(alignment: Alignment.topRight, child: Icon(Icons.pie_chart, color: Colors.amber)),
                              SizedBox(height: 8),
                              Text('28 Hari', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
                              Text('Rata-rata siklus', style: TextStyle(color: Colors.amber, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tombol Tambah Haid
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const InputDataView()));
                        _loadData();
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Tambah Haid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Riwayat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Perkiraan', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Chip(label: const Text('Semua', style: TextStyle(color: Colors.white)), backgroundColor: Colors.pinkAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        const SizedBox(width: 8),
                        Chip(label: const Text('Haid'), backgroundColor: Colors.grey[200], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none)),
                        const SizedBox(width: 8),
                        Chip(label: const Text('Ovulasi'), backgroundColor: Colors.grey[200], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ListView.builder(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _riwayatData.length,
                    itemBuilder: (context, index) {
                      final data = _riwayatData[index];
                      final tglMulai = DateTime.parse(data['tanggal_mulai']);
                      final tglSelesai = data['tanggal_selesai'] != null ? DateTime.parse(data['tanggal_selesai']) : null;
                      
                      int durasiHaid = tglSelesai != null ? tglSelesai.difference(tglMulai).inDays + 1 : 1;
                      int durasiSiklus = 28; 

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tglSelesai != null 
                                      ? '${tglMulai.day} ${_namaBulan(tglMulai.month)} - ${tglSelesai.day} ${_namaBulan(tglSelesai.month)}'
                                      : '${tglMulai.day} ${_namaBulan(tglMulai.month)} - Sekarang',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text('$durasiSiklus', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildCustomBar(durasiHaid, durasiSiklus),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // Fungsi pembantu untuk mengubah angka bulan menjadi teks
  String _namaBulan(int month) {
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return bulan[month - 1];
  }
}