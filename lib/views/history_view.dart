import 'package:flutter/material.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  // Ini adalah data bohongan (dummy) untuk melihat desain UI-nya saja.
  // Di Step 5, ini akan diganti dengan data dari Database.
  final List<Map<String, dynamic>> _dummyData = const [
    {
      'tanggal': '18 April 2026 - 23 April 2026',
      'durasi': '6 Hari',
      'gejala': 'Kram perut, pusing ringan',
    },
    {
      'tanggal': '20 Maret 2026 - 26 Maret 2026',
      'durasi': '7 Hari',
      'gejala': 'Lemas, nyeri punggung',
    },
    {
      'tanggal': '22 Februari 2026 - 27 Februari 2026',
      'durasi': '6 Hari',
      'gejala': 'Tidak ada gejala berat',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      // ListView.builder sangat efisien untuk menampilkan daftar yang panjang
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _dummyData.length,
        itemBuilder: (context, index) {
          final data = _dummyData[index]; // Mengambil data per baris
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shadowColor: const Color(0xFFF48FB1).withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris pertama: Tanggal dan Durasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data['tanggal'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2), // Ungu pudar
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          data['durasi'],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary, // Teks pink
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Baris kedua: Info Gejala
                  const Text(
                    'Gejala:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['gejala'],
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}