import 'package:flutter/material.dart';
// Import package kalender yang baru saja kita install
import 'package:table_calendar/table_calendar.dart'; 
import 'input_data_view.dart';
import 'history_view.dart';
import '../services/db_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // Variabel untuk Kalender
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Variabel untuk Data Siklus
  List<Map<String, dynamic>> _riwayatData = [];
  DateTime? _haidTerakhir;
  DateTime? _prediksiBerikutnya;
  int _hariKe = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Tarik data saat aplikasi pertama kali dibuka
  }

  // Fungsi untuk menarik data dari SQLite dan menghitung prediksi
  Future<void> _loadData() async {
    final data = await DatabaseService.instance.readAllData();
    
    DateTime? haidTerbaru;
    DateTime? prediksi;
    int hariKe = 0;

    if (data.isNotEmpty) {
      // Ambil data paling pertama (terbaru karena diurutkan DESC di SQLite)
      haidTerbaru = DateTime.parse(data.first['tanggal_mulai']);
      
      // Logika Prediksi Sederhana: Tanggal mulai ditambah 28 Hari
      prediksi = haidTerbaru.add(const Duration(days: 28));
      
      // Menghitung siklus hari ke-berapa hari ini
      hariKe = DateTime.now().difference(haidTerbaru).inDays + 1;
    }

    setState(() {
      _riwayatData = data;
      _haidTerakhir = haidTerbaru;
      _prediksiBerikutnya = prediksi;
      _hariKe = hariKe;
      _isLoading = false;
    });
  }

  // Fungsi untuk mengecek apakah suatu tanggal di kalender adalah hari menstruasi
  bool _isHariHaid(DateTime day) {
    for (var item in _riwayatData) {
      final start = DateTime.parse(item['tanggal_mulai']);
      final endStr = item['tanggal_selesai'];
      
      // Jika tanggal selesai belum diisi, anggap masih berlangsung sampai hari ini
      final end = endStr != null ? DateTime.parse(endStr) : DateTime.now();
      
      // Menyamakan format waktu agar perbandingan akurat (hanya tanggal, bulan, tahun)
      final dateToCheck = DateTime(day.year, day.month, day.day);
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);

      // Jika tanggal yang dicek berada di antara tanggal mulai dan selesai
      if (dateToCheck.isAfter(startDate.subtract(const Duration(days: 1))) && 
          dateToCheck.isBefore(endDate.add(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MTime', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              // Navigasi dengan await, agar saat kembali dari Riwayat, dashboard di-refresh
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryView()));
              _loadData(); 
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Halo, cantik! 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Bagaimana kabarmu hari ini?', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 30),

            // 1. Card Info Siklus (Datanya sudah dinamis dari Database!)
            Card(
              elevation: 4,
              shadowColor: const Color(0xFFF48FB1).withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF48FB1), Color(0xFFCE93D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Siklus Saat Ini', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Text(
                      _haidTerakhir != null ? 'Hari Ke-$_hariKe' : 'Belum Ada Data',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _prediksiBerikutnya != null 
                          ? 'Prediksi haid: ${_prediksiBerikutnya!.day}/${_prediksiBerikutnya!.month}/${_prediksiBerikutnya!.year}' 
                          : 'Catat siklus pertamamu!',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. Kalender Menstruasi
            const Text('Kalender Menstruasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Logika visual: Mewarnai tanggal haid dengan warna pink
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      if (_isHariHaid(day)) {
                        return Container(
                          margin: const EdgeInsets.all(6.0),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8BBD0), // Pink muda
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                      return null; // Kembalikan null agar tanggal lain menggunakan gaya bawaan
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 3. Tombol Tambah Data
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Navigasi dengan await, agar saat kembali dari Input Data, dashboard di-refresh otomatis
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const InputDataView()));
                  _loadData(); 
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Catat Gejala / Menstruasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}