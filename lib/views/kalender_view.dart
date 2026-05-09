import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Untuk format bulan
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseService.instance.readAllData();
    if (mounted) {
      setState(() {
        _riwayatData = data;
        _isLoading = false;
      });
    }
  }

  // Cek apakah tanggal tersebut adalah masa haid
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

  // Cek apakah tanggal tersebut masuk masa subur
  bool _isMasaSubur(DateTime day) {
    if (_riwayatData.isEmpty || _isHariHaid(day)) return false;
    
    final startTerbaru = DateTime.parse(_riwayatData.first['tanggal_mulai']);
    final dateToCheck = DateTime(day.year, day.month, day.day);
    final startDate = DateTime(startTerbaru.year, startTerbaru.month, startTerbaru.day);
    
    int selisih = dateToCheck.difference(startDate).inDays;
    return selisih >= 12 && selisih <= 16; 
  }

  // --- WIDGET UNTUK KETERANGAN WARNA (LEGEND) ---
  Widget _buildLegendItem(Color color, String text, {bool isBorder = false}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: isBorder ? Colors.transparent : color,
              shape: BoxShape.circle,
              border: isBorder ? Border.all(color: color, width: 2) : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Color(0xFF6A304C), fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- UX: FUNGSI POP-UP CATAT GEJALA (BOTTOM SHEET) ---
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
                  const SizedBox(height: 8),
                  Text('Pilih gejala yang Anda rasakan pada ${_selectedDay != null ? DateFormat('dd MMMM', 'id_ID').format(_selectedDay!) : 'hari ini'}.', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 24),

                  // Kumpulan Chip Pilihan Gejala
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

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_riwayatData.isNotEmpty) {
                          final Map<String, dynamic> dataTerbaru = Map.from(_riwayatData.first);
                          String gejalaLama = dataTerbaru['gejala'] ?? '';
                          if (gejalaLama == 'Belum ada gejala') gejalaLama = '';
                          
                          String gejalaBaru = gejalaTerpilih.join(',');
                          String finalGejala = gejalaLama.isEmpty ? gejalaBaru : '$gejalaLama,$gejalaBaru';
                          
                          dataTerbaru['gejala'] = finalGejala;
                          
                          await DatabaseService.instance.updateData(dataTerbaru);
                          _loadData(); 
                          
                          if (context.mounted) {
                            Navigator.pop(context); 
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gejala berhasil dicatat!'), backgroundColor: Color(0xFF9E4770)));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mulai siklus haid terlebih dahulu di Beranda.'), backgroundColor: Colors.red));
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
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFFFFF7F8), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      appBar: AppBar(
        title: const Text('MTime', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5')),
        ),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {})],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- KALENDER CARD ---
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
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false, titleCentered: false,
                      leftChevronIcon: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFFFF7F8), shape: BoxShape.circle), child: const Icon(Icons.chevron_left, color: Color(0xFF6A304C))),
                      rightChevronIcon: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFFFF7F8), shape: BoxShape.circle), child: const Icon(Icons.chevron_right, color: Color(0xFF6A304C))),
                      titleTextStyle: const TextStyle(color: Color(0xFF9E4770), fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold), weekendStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        if (_isHariHaid(day)) {
                          return Container(margin: const EdgeInsets.all(6.0), decoration: const BoxDecoration(color: Color(0xFFF48FB1), shape: BoxShape.circle), child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
                        }
                        if (_isMasaSubur(day)) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${day.day}', style: const TextStyle(color: Color(0xFF6A304C))),
                              const SizedBox(height: 2),
                              Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFFFCA28), shape: BoxShape.circle)),
                            ],
                          );
                        }
                        return Center(child: Text('${day.day}', style: const TextStyle(color: Color(0xFF6A304C))));
                      },
                      todayBuilder: (context, day, focusedDay) {
                        return Container(margin: const EdgeInsets.all(6.0), decoration: BoxDecoration(color: const Color(0xFFF3E5F5), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFCE93D8), width: 2)), child: Center(child: Text('${day.day}', style: const TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.bold))));
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- LEGEND ---
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    _buildLegendItem(const Color(0xFFF48FB1), 'Menstruasi'),
                    _buildLegendItem(const Color(0xFFFFCA28), 'Masa Subur'),
                    _buildLegendItem(const Color(0xFFCE93D8), 'Hari Ini', isBorder: true),
                    _buildLegendItem(Colors.grey, 'Catatan'),
                  ],
                ),
                const SizedBox(height: 30),

                // --- WAWASAN HARI INI ---
                const Text('Wawasan Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFF6A304C))),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Masa subur akan dimulai dalam 3 hari.', style: TextStyle(color: Color(0xFF6A304C), fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Pertahankan hidrasi dan pola tidur yang teratur.', style: TextStyle(color: Color(0xFF9E4770), fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // --- TOMBOL FLOATING (+) ---
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _tampilkanMenuCatatan(context), // Sekarang sudah terhubung dengan benar!
              backgroundColor: const Color(0xFF9E4770), 
              elevation: 5,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}