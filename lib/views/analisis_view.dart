import 'package:flutter/material.dart';
import 'dart:math'; 
import '../services/db_service.dart';

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

      
      for (int i = 0; i < data.length - 1; i++) {
        final currentStart = DateTime.parse(data[i]['tanggal_mulai']);
        final previousStart = DateTime.parse(data[i+1]['tanggal_mulai']);
        int diff = currentStart.difference(previousStart).inDays;
        if (diff > 0) cycleLengths.add(diff);
      }

      if (cycleLengths.isNotEmpty) {
        _siklusTerpanjang = cycleLengths.reduce(max);
        _siklusTerpendek = cycleLengths.reduce(min);
      }

      
      
      for (var item in data) {
        String gejalaRaw = item['gejala'] ?? '';
        if (gejalaRaw.isNotEmpty && 
            gejalaRaw.toLowerCase() != 'belum ada gejala' && 
            gejalaRaw.toLowerCase() != 'tidak ada gejala') {
          
          List<String> listGejala = gejalaRaw.split(',');
          for (var g in listGejala) {
            String kata = g.trim().toLowerCase();
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

    setState(() {
      _totalSiklus = data.length;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _totalSiklus < 2 
              
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      Icon(Icons.analytics_outlined, size: 80, color: Colors.pink[200]),
                      const SizedBox(height: 16),
                      const Text('Data Belum Cukup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Catat minimal 2 siklus haid untuk\nmelihat analisis kesehatanmu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Laporan Kesehatanmu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Berdasarkan data yang kamu catat, ini adalah pola siklus tubuhmu.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 30),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.pink[50], shape: BoxShape.circle),
                                  child: const Icon(Icons.show_chart, color: Colors.pink),
                                ),
                                const SizedBox(width: 15),
                                const Text('Variasi Siklus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('Terpendek', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text('$_siklusTerpendek Hari', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ],
                                ),
                                Container(height: 40, width: 1, color: Colors.grey[300]),
                                Column(
                                  children: [
                                    const Text('Terpanjang', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text('$_siklusTerpanjang Hari', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text('Gejala Paling Sering', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _topGejala.isEmpty
                      ? const Text('Belum ada pola gejala yang tercatat.', style: TextStyle(color: Colors.grey))
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _topGejala.map((gejala) {
                            return Chip(
                              label: Text(gejala, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.purple[300],
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
                            );
                          }).toList(),
                        ),
                  ],
                ),
          ),
    );
  }
}