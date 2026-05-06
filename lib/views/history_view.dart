import 'package:flutter/material.dart';
import '../services/db_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView>{
  List<Map<String, dynamic>> _riwayatData = [];
  bool _isloading = true;

  @override
  void initState(){
    super.initState();
    _ambilDataDariDatabase();
  }
  Future<void> _ambilDataDariDatabase() async{
    final data = await DatabaseService.instance.readAllData();
    setState((){
      _riwayatData = data;
      _isloading = false;
    });
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isloading?
      const Center(child: CircularProgressIndicator()):
      _riwayatData.isEmpty? const Center(child: Text('Belum ada Data yang di Catat.')): ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _riwayatData.length,
        itemBuilder: (context, index){
          final data = _riwayatData[index];
          //parsing tanggal dari string Database ke DateTime
          final tglMulai = DateTime.parse(data['tanggal_mulai']);
          final tglSelesai = data['tanggal_selesai'] != null? DateTime.parse(data['tanggal_selesai']) : null;
          //mengatur format teks tanggal
          final teksTanggal = tglSelesai != null?
          '${tglMulai.day}/${tglMulai.month}${tglMulai.year} - ${tglSelesai.day}/${tglSelesai.month}/${tglSelesai.year}'
          : '${tglMulai.day}/${tglMulai.month}${tglMulai.year} - Sekarang';
          //menghitung selisih hari (durasi)
          final teksDurasi = tglSelesai != null?
          '${tglSelesai.difference(tglMulai).inDays + 1} Hari'
          : 'Sedang Berlangsung...';
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shadowColor: const Color(0xFFF48FB1).withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(teksTanggal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          teksDurasi, style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Gejala:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    data['gejala'],
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  //tampilkan Catatan Jika ada
                  if (data['catatan'] != null && data ['catatan'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Catatan:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(data['catatan'], style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  } 
} 