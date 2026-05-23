import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../services/db_service.dart';
import 'kalender_view.dart'; 

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<Map<String, dynamic>> _riwayatData = [];
  bool _isLoading = true;
  String _rataSiklus = '28'; 

  @override
  void initState() {
    super.initState();
    _loadData();
    AppDataNotifier.refreshSignal.addListener(_loadData);
  }

  @override
  void dispose() {
    AppDataNotifier.refreshSignal.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await DatabaseService.instance.readAllData();
    final prefs = await SharedPreferences.getInstance();
    String savedSiklus = prefs.getString('rata_siklus') ?? '28';

    // ALGORITMA SMART LEARNING UNTUK RIWAYAT
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
        _rataSiklus = dynamicAvgSiklus.toString(); 
        _riwayatData = data;
        _isLoading = false;
      });
    }
  }

  String _namaBulanLengkap(int month) {
    const bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return bulan[month - 1];
  }
  
  String _namaBulanSingkat(int month) {
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return bulan[month - 1];
  }

  Widget _buildCustomBar(int haidDays, int cycleDays) {
    if (cycleDays < haidDays) cycleDays = haidDays + 1; 
    int flexHaid = haidDays;
    int flexJeda1 = 7; 
    int flexSubur = 5; 
    int flexJeda2 = cycleDays - (flexHaid + flexJeda1 + flexSubur);
    if (flexJeda2 < 0) flexJeda2 = 0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                Expanded(flex: flexHaid, child: Container(color: const Color(0xFFF48FB1))),
                Expanded(flex: flexJeda1, child: Container(color: const Color(0xFFEBE0E4))),
                Expanded(
                  flex: flexSubur,
                  child: Container(
                    color: const Color(0xFFE1BEE7),
                    child: Center(
                      child: Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF6A304C), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))),
                    ),
                  ),
                ),
                Expanded(flex: flexJeda2, child: Container(color: const Color(0xFFEBE0E4))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Menstruasi', style: TextStyle(color: Color(0xFF9E4770), fontSize: 11)),
            Text('Masa Subur', style: TextStyle(color: Color(0xFF9E4770), fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildGejalaList(String gejalaString) {
    if (gejalaString.isEmpty || gejalaString.toLowerCase() == 'belum ada gejala') return const SizedBox.shrink(); 
    List<String> listGejala = gejalaString.split(',').where((g) => g.trim().isNotEmpty).toList();
    if (listGejala.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFFCE4EC), thickness: 1),
        const SizedBox(height: 12),
        const Text('Gejala Tercatat:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9E4770))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: listGejala.map((g) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.pink.shade100)),
              child: Text(g.trim(), style: const TextStyle(fontSize: 11, color: Color(0xFF6A304C))),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _tampilkanMenuEditSiklus(BuildContext context, Map<String, dynamic> item) {
    DateTime startDate = DateTime.parse(item['tanggal_mulai']);
    DateTime? endDate = item['tanggal_selesai'] != null ? DateTime.parse(item['tanggal_selesai']) : null;
    
    TextEditingController gejalaController = TextEditingController(
      text: item['gejala'] == 'Belum ada gejala' ? '' : item['gejala']
    );

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true, 
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit Catatan Siklus', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('Hapus Riwayat Ini?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                content: const Text('Apakah Anda yakin ingin menghapus catatan siklus ini? Tindakan ini tidak dapat dibatalkan.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () async {
                                      await DatabaseService.instance.deleteData(item['id']);
                                      AppDataNotifier.triggerRefresh();
                                      if (context.mounted) {
                                        Navigator.pop(context); 
                                        Navigator.pop(context); 
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan riwayat berhasil dihapus'), backgroundColor: Colors.red));
                                      }
                                    },
                                    child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Sesuaikan tanggal dan gejala yang Anda rasakan.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 24),

                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), tileColor: const Color(0xFFFFF0F5),
                      leading: const Icon(Icons.water_drop, color: Color(0xFFF48FB1)),
                      title: const Text('Tanggal Mulai', style: TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(startDate), style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.edit_calendar, color: Color(0xFF9E4770)),
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2023), lastDate: DateTime.now(), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF9E4770))), child: child!));
                        if (picked != null) setModalState(() => startDate = picked);
                      },
                    ),
                    const SizedBox(height: 12),

                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), tileColor: const Color(0xFFFFF0F5),
                      leading: const Icon(Icons.check_circle_outline, color: Color(0xFFCE93D8)),
                      title: const Text('Tanggal Selesai', style: TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.bold)),
                      subtitle: Text(endDate != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(endDate!) : 'Belum selesai (Masih haid)', style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.edit_calendar, color: Color(0xFF9E4770)),
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: endDate ?? DateTime.now(), firstDate: startDate, lastDate: DateTime.now(), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF9E4770))), child: child!));
                        if (picked != null) setModalState(() => endDate = picked);
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text('Gejala (Pisahkan dengan koma)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A304C), fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: gejalaController,
                      decoration: InputDecoration(hintText: 'Contoh: Kram, Mual, Lelah', filled: true, fillColor: const Color(0xFFFFF0F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.healing, color: Color(0xFF9E4770))),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final updatedItem = Map<String, dynamic>.from(item);
                          updatedItem['tanggal_mulai'] = startDate.toIso8601String();
                          updatedItem['tanggal_selesai'] = endDate?.toIso8601String();
                          String gejalaBaru = gejalaController.text.trim();
                          updatedItem['gejala'] = gejalaBaru.isEmpty ? 'Belum ada gejala' : gejalaBaru;
                          
                          await DatabaseService.instance.updateData(updatedItem);
                          AppDataNotifier.triggerRefresh();
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan berhasil diperbarui!'), backgroundColor: Color(0xFF9E4770)));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E4473), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                        child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
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
            const Text('Riwayat Siklus', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
            const SizedBox(height: 8),
            const Text('Pantau perjalanan kesehatan dan keteraturan siklus bulanan Anda secara menyeluruh.', style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.pink.withOpacity(0.1))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Rata-rata Siklus', style: TextStyle(color: Color(0xFF9E4770), fontSize: 18, fontWeight: FontWeight.bold)), Icon(Icons.auto_graph, color: Color(0xFF9E4770))]),
                  const SizedBox(height: 16),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(_rataSiklus, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF6A304C), height: 1)), const SizedBox(width: 8), const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('Hari', style: TextStyle(color: Colors.grey, fontSize: 16)))]),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _riwayatData.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada riwayat siklus.", style: TextStyle(color: Colors.grey))))
                : ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _riwayatData.length,
                    itemBuilder: (context, index) {
                      final item = _riwayatData[index];
                      final tglMulai = DateTime.parse(item['tanggal_mulai']);
                      final tglSelesai = item['tanggal_selesai'] != null ? DateTime.parse(item['tanggal_selesai']) : null;
                      int durasiHaid = tglSelesai != null ? tglSelesai.difference(tglMulai).inDays + 1 : 1;
                      int durasiSiklus = int.tryParse(_rataSiklus) ?? 28; 
                      
                      if (index < _riwayatData.length - 1) {
                         final nextStart = DateTime.parse(_riwayatData[index + 1]['tanggal_mulai']);
                         // Hitung jarak dari bulan sebelumnya ke bulan ini (mengingat list diurutkan DESC)
                         durasiSiklus = tglMulai.difference(nextStart).inDays;
                      }

                      String rangeTgl = tglSelesai != null 
                        ? '${tglMulai.day} ${_namaBulanSingkat(tglMulai.month)} - ${tglSelesai.day} ${_namaBulanSingkat(tglSelesai.month)}'
                        : '${tglMulai.day} ${_namaBulanSingkat(tglMulai.month)} - Sekarang';

                      String stringGejala = item['gejala'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${_namaBulanLengkap(tglMulai.month)} ${tglMulai.year}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
                                Row(
                                  children: [
                                    Text('$durasiSiklus Hari', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _tampilkanMenuEditSiklus(context, item),
                                      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit, color: Color(0xFF9E4770), size: 18)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('$rangeTgl ($durasiHaid Hari Menstruasi)', style: const TextStyle(color: Colors.grey, fontSize: 12)), const Text('Durasi Siklus', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                            const SizedBox(height: 20),
                            _buildCustomBar(durasiHaid, durasiSiklus),
                            _buildGejalaList(stringGejala),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}