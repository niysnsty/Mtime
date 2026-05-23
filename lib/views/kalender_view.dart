import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import '../services/db_service.dart';
import 'history_view.dart'; 

class AppDataNotifier {
  static final ValueNotifier<bool> refreshSignal = ValueNotifier<bool>(false);
  static void triggerRefresh() {
    refreshSignal.value = !refreshSignal.value;
  }
}

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
    AppDataNotifier.refreshSignal.addListener(_loadData);
  }

  @override
  void dispose() {
    AppDataNotifier.refreshSignal.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await DatabaseService.instance.readAllData();
    String savedSiklus = prefs.getString('rata_siklus') ?? '28';
    
    // --- ALGORITMA SMART LEARNING UNTUK KALENDER ---
    int dynamicAvgSiklus = int.tryParse(savedSiklus) ?? 28;

    if (data.isNotEmpty) {
      int totalSiklusDays = 0;
      int cycleCount = 0;
      if (data.length >= 2) {
        for (int i = 0; i < data.length - 1; i++) {
          DateTime currentStart = DateTime.parse(data[i]['tanggal_mulai']);
          DateTime prevStart = DateTime.parse(data[i+1]['tanggal_mulai']);
          totalSiklusDays += currentStart.difference(prevStart).inDays;
          cycleCount++;
        }
        if (cycleCount > 0) {
          dynamicAvgSiklus = (totalSiklusDays / cycleCount).round();
        }
      }
    }

    if (mounted) {
      setState(() {
        _rataSiklus = dynamicAvgSiklus; // Sekarang menggunakan nilai 34 Hari (Dinamis)
        _riwayatData = data;
        _isLoading = false;
      });
    }
  }

  bool _isHariHaid(DateTime day) {
    for (var item in _riwayatData) {
      final start = DateTime.parse(item['tanggal_mulai']);
      final endStr = item['tanggal_selesai'];
      
      final d = DateTime(day.year, day.month, day.day);
      final s = DateTime(start.year, start.month, start.day);
      
      DateTime e;
      if (endStr != null) {
        final parsedEnd = DateTime.parse(endStr);
        e = DateTime(parsedEnd.year, parsedEnd.month, parsedEnd.day);
      } else {
        final now = DateTime.now();
        e = DateTime(now.year, now.month, now.day);
      }

      if ((d.isAtSameMomentAs(s) || d.isAfter(s)) && (d.isAtSameMomentAs(e) || d.isBefore(e))) {
        return true;
      }
    }
    return false;
  }

  String _getStatusHaidText(DateTime day) {
    for (var item in _riwayatData) {
      final start = DateTime.parse(item['tanggal_mulai']);
      final endStr = item['tanggal_selesai'];
      
      final d = DateTime(day.year, day.month, day.day);
      final s = DateTime(start.year, start.month, start.day);
      
      DateTime e;
      if (endStr != null) {
        final parsedEnd = DateTime.parse(endStr);
        e = DateTime(parsedEnd.year, parsedEnd.month, parsedEnd.day);
      } else {
        final now = DateTime.now();
        e = DateTime(now.year, now.month, now.day);
      }

      if ((d.isAtSameMomentAs(s) || d.isAfter(s)) && (d.isAtSameMomentAs(e) || d.isBefore(e))) {
        if (endStr != null) {
          return 'Riwayat Menstruasi';
        } else {
          return 'Sedang Menstruasi';
        }
      }
    }
    return 'Tidak ada riwayat pada tanggal ini.';
  }

  DateTime? _getOvulasiDate() {
    if (_riwayatData.isEmpty) return null;
    final startTerbaru = DateTime.parse(_riwayatData.first['tanggal_mulai']);
    final startDate = DateTime(startTerbaru.year, startTerbaru.month, startTerbaru.day);
    // nextHaid sekarang dikalkulasi menggunakan siklus 34 hari
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
    return (dateToCheck.isAfter(suburMulai.subtract(const Duration(days: 1))) && dateToCheck.isBefore(suburSelesai.add(const Duration(days: 1))));
  }

  Widget _buildLegendItem(Color color, String text, {bool isBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: isBorder ? Colors.transparent : color, shape: BoxShape.circle, border: isBorder ? Border.all(color: const Color(0xFF9E4770), width: 2) : null)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFF6A304C), fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _tampilkanMenuCatatan(BuildContext context) {
    final List<String> pilihanGejala = ['Kram', 'Kelelahan', 'Jerawat', 'Sakit Kepala', 'Mual', 'Nyeri Payudara'];
    List<String> gejalaTerpilih = []; 

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
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
                        selected: isSelected, selectedColor: const Color(0xFF9E4770), backgroundColor: const Color(0xFFFFF0F5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                        onSelected: (selected) { setModalState(() { if (selected) { gejalaTerpilih.add(gejala); } else { gejalaTerpilih.remove(gejala); } }); },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Map<String, dynamic>? siklusAktif;
                        for (var s in _riwayatData) { if (s['tanggal_selesai'] == null) { siklusAktif = s; break; } }
                        if (siklusAktif != null) {
                          final Map<String, dynamic> dataTerbaru = Map.from(siklusAktif);
                          String gejalaLama = dataTerbaru['gejala'] ?? '';
                          if (gejalaLama == 'Belum ada gejala') gejalaLama = '';
                          String gejalaBaru = gejalaTerpilih.join(', ');
                          if (gejalaBaru.isNotEmpty) {
                            dataTerbaru['gejala'] = gejalaLama.isEmpty ? gejalaBaru : '$gejalaLama, $gejalaBaru';
                            await DatabaseService.instance.updateData(dataTerbaru);
                            AppDataNotifier.triggerRefresh();
                            if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gejala berhasil dicatat!'), backgroundColor: Color(0xFF9E4770))); }
                          }
                        } else {
                          if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mulai haid bulan ini terlebih dahulu untuk mencatat gejala.'), backgroundColor: Colors.red)); }
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

  Widget _buildCustomDay(DateTime day, {bool isSelected = false, bool isToday = false}) {
    TextStyle textStyle = TextStyle(
      color: _isHariHaid(day) ? Colors.white : const Color(0xFF6A304C),
      fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
    );

    return Container(
      margin: const EdgeInsets.all(5.0), 
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _isHariHaid(day) ? const Color(0xFFF48FB1) : (isSelected ? const Color(0xFFFFF0F5) : Colors.transparent),
        shape: BoxShape.circle,
        border: isToday 
            ? Border.all(color: const Color(0xFF9E4770), width: 2.5) 
            : (isSelected && !_isHariHaid(day) ? Border.all(color: const Color(0xFF9E4770).withOpacity(0.5), width: 1.5) : null),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}', style: textStyle),
          const SizedBox(height: 1),
          if (!_isHariHaid(day)) ...[
             if (_isMasaSubur(day)) Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFFFCA28), shape: BoxShape.circle)),
             if (_isOvulasi(day)) Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      appBar: AppBar(title: const Text('Kalender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)), backgroundColor: Colors.transparent, elevation: 0),
      floatingActionButton: FloatingActionButton(onPressed: () => _tampilkanMenuCatatan(context), backgroundColor: const Color(0xFF6A304C), elevation: 5, child: const Icon(Icons.add, color: Colors.white, size: 30)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1), lastDay: DateTime.utc(2030, 12, 31), focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) { setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }); },
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: Color(0xFF9E4770), fontSize: 20, fontWeight: FontWeight.bold)),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) => _buildCustomDay(day),
                  todayBuilder: (context, day, focusedDay) => _buildCustomDay(day, isToday: true),
                  selectedBuilder: (context, day, focusedDay) { bool isToday = isSameDay(day, DateTime.now()); return _buildCustomDay(day, isSelected: true, isToday: isToday); },
                ),
              ),
            ),
            const SizedBox(height: 30),

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

            Text(_selectedDay != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDay!) : 'Pilih Tanggal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
            const SizedBox(height: 12),
            
            _selectedDay != null && _isHariHaid(_selectedDay!)
                ? GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryView()));
                      _loadData(); 
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.pink.shade100)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop, color: Color(0xFFF48FB1)),
                              const SizedBox(width: 10),
                              Text(_getStatusHaidText(_selectedDay!), style: const TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFF9E4770)), 
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        Icon(Icons.event_busy, color: Colors.grey.shade400),
                        const SizedBox(width: 10),
                        const Text('Tidak ada riwayat pada tanggal ini.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}