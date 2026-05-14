import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import '../services/db_service.dart';

class KalenderView extends StatefulWidget {
  const KalenderView({super.key});

  @override
  State<KalenderView> createState() => _KalenderViewState();
}

class _KalenderViewState extends State<KalenderView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _riwayatData = [];
  bool _isLoading = true;
  
  int _rataSiklus = 28;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await DatabaseService.instance.readAllData();
    
    String savedSiklus = prefs.getString('rata_siklus') ?? '28';
    
    if (mounted) {
      setState(() {
        _rataSiklus = int.tryParse(savedSiklus) ?? 28;
        _riwayatData = data;
        _isLoading = false;
      });
    }
  }

  // --- LOGIKA KALKULASI TANGGAL ---
  bool _isHariHaid(DateTime day) {
    for (var item in _riwayatData) {
      final start = DateTime.parse(item['tanggal_mulai']);
      final endStr = item['tanggal_selesai'];
      final end = endStr != null ? DateTime.parse(endStr) : DateTime.now();
      
      final dateToCheck = DateTime(day.year, day.month, day.day);
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);

      if (dateToCheck.isAfter(startDate.subtract(const Duration(days: 1))) && 
          dateToCheck.isBefore(endDate.add(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }

  DateTime? _getOvulasiDate() {
    if (_riwayatData.isEmpty) return null;
    final startTerbaru = DateTime.parse(_riwayatData.first['tanggal_mulai']);
    final startDate = DateTime(startTerbaru.year, startTerbaru.month, startTerbaru.day);
    
    final nextHaid = startDate.add(Duration(days: _rataSiklus));
    return nextHaid.subtract(const Duration(days: 14));
  }

  bool _isOvulasi(DateTime day) {
    if (_riwayatData.isEmpty || _isHariHaid(day)) return false;
    final ovulasiDate = _getOvulasiDate();
    if (ovulasiDate == null) return false;

    final dateToCheck = DateTime(day.year, day.month, day.day);
    return dateToCheck.isAtSameMomentAs(ovulasiDate);
  }

  bool _isMasaSubur(DateTime day) {
    if (_riwayatData.isEmpty || _isHariHaid(day)) return false;
    final ovulasiDate = _getOvulasiDate();
    if (ovulasiDate == null) return false;

    final suburMulai = ovulasiDate.subtract(const Duration(days: 4));
    final suburSelesai = ovulasiDate.add(const Duration(days: 1));
    final dateToCheck = DateTime(day.year, day.month, day.day);

    if (dateToCheck.isAtSameMomentAs(ovulasiDate)) return false; 

    return (dateToCheck.isAfter(suburMulai.subtract(const Duration(days: 1))) && 
            dateToCheck.isBefore(suburSelesai.add(const Duration(days: 1))));
  }

  // --- UI HELPER ---
  Widget _buildLegendItem(Color color, String text, {bool isBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: isBorder ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: isBorder ? Border.all(color: const Color(0xFF9E4770), width: 2) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFF6A304C), fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _tampilkanMenuCatatan(BuildContext context) {
    final List<String> pilihanGejala = ['Kram', 'Kelelahan', 'Jerawat', 'Sakit Kepala', 'Mual', 'Nyeri Payudara'];
    List<String> gejalaTerpilih = []; 

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 24),
                  const Text('Catat Gejala Hari Ini', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: pilihanGejala.map((gejala) {
                      final isSelected = gejalaTerpilih.contains(gejala);
                      return ChoiceChip(
                        label: Text(gejala, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF6A304C))),
                        selected: isSelected,
                        selectedColor: const Color(0xFF9E4770),
                        backgroundColor: const Color(0xFFFFF0F5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              gejalaTerpilih.add(gejala);
                            } else {
                              gejalaTerpilih.remove(gejala);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Map<String, dynamic>? siklusAktif;
                        for (var s in _riwayatData) {
                          if (s['tanggal_selesai'] == null) {
                            siklusAktif = s;
                            break;
                          }
                        }

                        if (siklusAktif != null) {
                          final Map<String, dynamic> dataTerbaru = Map.from(siklusAktif);
                          String gejalaLama = dataTerbaru['gejala'] ?? '';
                          if (gejalaLama == 'Belum ada gejala') gejalaLama = '';
                          
                          String gejalaBaru = gejalaTerpilih.join(', ');
                          if (gejalaBaru.isNotEmpty) {
                            dataTerbaru['gejala'] = gejalaLama.isEmpty ? gejalaBaru : '$gejalaLama, $gejalaBaru';
                            await DatabaseService.instance.updateData(dataTerbaru);
                            _loadData(); 
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gejala berhasil dicatat!'), backgroundColor: Color(0xFF9E4770)));
                            }
                          }
                        } else {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mulai haid bulan ini terlebih dahulu untuk mencatat gejala.'), backgroundColor: Colors.red));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E4473), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                      child: const Text('Simpan Catatan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      appBar: AppBar(
        title: const Text('Kalender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
        backgroundColor: Colors.transparent, elevation: 0,
      ),
      // PERBAIKAN: Menggunakan properti bawaan Scaffold untuk tombol melayang
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tampilkanMenuCatatan(context),
        backgroundColor: const Color(0xFF6A304C), 
        elevation: 5,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      // PERBAIKAN: Menghapus Stack agar tidak saling menimpa
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- KALENDER ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: Color(0xFF9E4770), fontSize: 20, fontWeight: FontWeight.bold)),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_isHariHaid(day)) {
                      return Container(margin: const EdgeInsets.all(6.0), decoration: const BoxDecoration(color: Color(0xFFF48FB1), shape: BoxShape.circle), child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
                    }
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${day.day}', style: const TextStyle(color: Color(0xFF6A304C))),
                        const SizedBox(height: 2),
                        if (_isMasaSubur(day)) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFFCA28), shape: BoxShape.circle)),
                        if (_isOvulasi(day)) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                      ],
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return Container(
                      margin: const EdgeInsets.all(6.0), 
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF9E4770), width: 2)), 
                      child: Center(child: Text('${day.day}', style: const TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.bold)))
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- LEGEND (KETERANGAN WARNA) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                spacing: 20, runSpacing: 15,
                children: [
                  _buildLegendItem(const Color(0xFFF48FB1), 'Menstruasi'),
                  _buildLegendItem(const Color(0xFFFFCA28), 'Masa Subur'),
                  _buildLegendItem(Colors.transparent, 'Hari Ini', isBorder: true),
                  _buildLegendItem(Colors.grey, 'Ovulasi'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // --- INFO TANGGAL TERPILIH ---
            Text(
              _selectedDay != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDay!) : 'Pilih Tanggal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))
            ),
            const SizedBox(height: 12),
            
            // --- INDIKATOR HAID ---
            _selectedDay != null && _isHariHaid(_selectedDay!)
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.pink.shade100)),
                    child: Row(
                      children: const [
                        Icon(Icons.water_drop, color: Color(0xFFF48FB1)),
                        SizedBox(width: 10),
                        Text('Sedang Menstruasi', style: TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : const Text('Tidak ada riwayat menstruasi pada tanggal ini.', style: TextStyle(color: Colors.grey)),
            // PERBAIKAN: Ruang kosong ekstra di bawah agar keterangan warna bisa di-scroll melewati tombol +
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}