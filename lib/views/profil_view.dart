import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../services/db_service.dart';
import 'package:mtime/services/notification_service.dart';
import 'edit_profil_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'kalender_view.dart';

class ProfilView extends StatefulWidget {
  const ProfilView({super.key});

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  bool _isLoading = true;
  String _namaUser = 'Pengguna';
  String _rataHaid = '7';
  String _rataSiklus = '28';
  String _photo = '';
  String _prediksiBerikutnya = '-';
  
  bool _notifikasiHaid = true;
  bool _notifikasiSubur = false;
  
  // Variabel untuk menyimpan status on/off sidik jari
  bool _isFingerprintActive = true; 

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

  String _namaBulanLengkap(int month) {
    const bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return bulan[month - 1];
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await DatabaseService.instance.readAllData();
    
    String savedNama = prefs.getString('nama') ?? 'Pengguna';
    String savedHaid = prefs.getString('rata_haid') ?? '7';
    String savedSiklus = prefs.getString('rata_siklus') ?? '28';
    String savedPhoto = prefs.getString('user_photo') ?? '';
    
    bool savedNotifHaid = prefs.getBool('notif_haid') ?? false;
    bool savedNotifSubur = prefs.getBool('notif_subur') ?? false;
    
    // Membaca status sidik jari dari memori
    bool savedFingerprint = prefs.getBool('is_biometric_enabled') ?? false;

    int dynamicAvgHaid = int.tryParse(savedHaid) ?? 7;
    int dynamicAvgSiklus = int.tryParse(savedSiklus) ?? 28;
    String prediksiDate = '-';

    if (data.isNotEmpty) {
      int totalHaidDays = 0, completedHaidCount = 0;
      for (var item in data) {
        if (item['tanggal_selesai'] != null) {
          DateTime start = DateTime.parse(item['tanggal_mulai']);
          DateTime end = DateTime.parse(item['tanggal_selesai']);
          totalHaidDays += end.difference(start).inDays + 1;
          completedHaidCount++;
        }
      }
      if (completedHaidCount > 0) dynamicAvgHaid = (totalHaidDays / completedHaidCount).round();

      int totalSiklusDays = 0, cycleCount = 0;
      if (data.length >= 2) {
        for (int i = 0; i < data.length - 1; i++) {
          DateTime currentStart = DateTime.parse(data[i]['tanggal_mulai']);
          DateTime prevStart = DateTime.parse(data[i+1]['tanggal_mulai']);
          totalSiklusDays += currentStart.difference(prevStart).inDays;
          cycleCount++;
        }
        if (cycleCount > 0) dynamicAvgSiklus = (totalSiklusDays / cycleCount).round();
      }

      DateTime haidTerbaru = DateTime.parse(data.first['tanggal_mulai']);
      DateTime nextHaid = haidTerbaru.add(Duration(days: dynamicAvgSiklus));
      prediksiDate = '${nextHaid.day} ${_namaBulanLengkap(nextHaid.month)} ${nextHaid.year}';
    }

    if (mounted) {
      setState(() {
        _namaUser = savedNama;
        _rataHaid = dynamicAvgHaid.toString();
        _rataSiklus = dynamicAvgSiklus.toString();
        _prediksiBerikutnya = prediksiDate;
        _photo = savedPhoto;
        _notifikasiHaid = savedNotifHaid;
        _notifikasiSubur = savedNotifSubur;
        _isFingerprintActive = savedFingerprint; // Memperbarui status toggle di layar
        _isLoading = false;
      });
    }
  }

  Future<void> _buatDanUnduhPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menyimpan PDF ke folder Download...'), backgroundColor: Color(0xFF9E4770)));
    
    try {
      final data = await DatabaseService.instance.readAllData();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Laporan Riwayat Siklus Menstruasi', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.pink800)),
                pw.SizedBox(height: 10),
                pw.Text('Nama: $_namaUser', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('Tanggal Cetak: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                if (data.isEmpty)
                  pw.Text('Belum ada riwayat siklus yang tercatat.', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey))
                else
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.pink100),
                    headerHeight: 40,
                    cellHeight: 30,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerLeft,
                    },
                    headers: ['Tanggal Mulai', 'Tanggal Selesai', 'Gejala Tercatat'],
                    data: data.map((item) {
                      DateTime start = DateTime.parse(item['tanggal_mulai']);
                      String strMulai = DateFormat('dd MMM yyyy').format(start);
                      
                      String strSelesai = 'Masih haid';
                      if (item['tanggal_selesai'] != null) {
                        DateTime end = DateTime.parse(item['tanggal_selesai']);
                        strSelesai = DateFormat('dd MMM yyyy').format(end);
                      }
                      
                      String gejala = item['gejala'] ?? '-';
                      
                      return [strMulai, strSelesai, gejala];
                    }).toList(),
                  ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final dir = Directory('/storage/emulated/0/Download'); 
      
      if (!await dir.exists()) {
         await dir.create(recursive: true);
      }
      
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/MTime_Riwayat_$timestamp.pdf');
      
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sukses! PDF tersimpan di folder Download:\n${file.path}'), 
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          )
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan PDF. Error: $e'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          )
        );
      }
    }
  }

  void _konfirmasiHapusData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Seluruh Data?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('Semua riwayat siklus, gejala, dan catatan Anda akan dihapus secara permanen dari perangkat ini. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevButtonHapus(
            onPressed: () async {
              await DatabaseService.instance.deleteAllData();
              AppDataNotifier.triggerRefresh();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seluruh data riwayat berhasil dihapus.'), backgroundColor: Colors.red));
              }
            },
            text: 'Hapus Data',
          ),
        ],
      ),
    );
  }

  void _konfirmasiHapusAkun() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Akun?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('Ini akan menghapus seluruh data riwayat beserta profil Anda (Nama, Preferensi) dan mengatur ulang aplikasi ke kondisi awal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevButtonHapus(
            onPressed: () async {
              await DatabaseService.instance.deleteAllData();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              AppDataNotifier.triggerRefresh();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun dan data berhasil di-reset.'), backgroundColor: Colors.red));
              }
            },
            text: 'Hapus Akun',
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (_photo.isEmpty || _photo.startsWith('http')) {
      return Container(
        width: 100, height: 100,
        decoration: BoxDecoration(color: Colors.pink.shade100, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 10)]),
        child: const Icon(Icons.person, size: 50, color: Colors.white),
      );
    } else {
      return Container(
        key: ValueKey(_photo),
        width: 100, height: 100,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 10)], image: DecorationImage(image: FileImage(File(_photo)), fit: BoxFit.cover)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFFFFF7F8), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF6A304C))),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Color(0xFF9E4770)), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView())); _loadData(); }),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF7F8), Color(0xFFFCE4EC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      _buildAvatar().animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 20),
                      Text(_namaUser, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))).animate().fade(delay: 300.ms).slideY(begin: 0.5),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFD87093).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Aplikasi Mode Luring', style: TextStyle(color: Color(0xFFD87093), fontSize: 13, fontWeight: FontWeight.w600)),
                      ).animate().fade(delay: 400.ms).slideY(begin: 0.5),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Align(alignment: Alignment.centerLeft, child: Text('DATA SIKLUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF9E4770).withOpacity(0.8), letterSpacing: 1.5))).animate().fade(delay: 500.ms),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: const Color(0xFFD87093).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))]),
                  child: Column(
                    children: [
                      ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.water_drop_outlined, color: Color(0xFFD87093), size: 20)), title: const Text('Rata-rata Haid', style: TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.w500)), trailing: Text('$_rataHaid Hari', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A304C), fontSize: 16))),
                      const Divider(height: 1, indent: 60, color: Color(0xFFFFF0F5)),
                      ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.calendar_month, color: Color(0xFFFFCA28), size: 20)), title: const Text('Rata-rata Siklus', style: TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.w500)), trailing: Text('$_rataSiklus Hari', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A304C), fontSize: 16))),
                      const Divider(height: 1, indent: 60, color: Color(0xFFFFF0F5)),
                      ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.event_available, color: Color(0xFFCE93D8), size: 20)), title: const Text('Prediksi Berikutnya', style: TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.w500)), trailing: Text(_prediksiBerikutnya, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A304C), fontSize: 15))),
                    ],
                  ),
                ).animate().fade(duration: 600.ms, delay: 500.ms).slideY(begin: 0.1),
                const SizedBox(height: 30),

                Align(alignment: Alignment.centerLeft, child: Text('PREFERENSI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF9E4770).withOpacity(0.8), letterSpacing: 1.5))).animate().fade(delay: 600.ms),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: const Color(0xFFD87093).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))]),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Notifikasi Haid', style: TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.w500)), secondary: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFD87093), size: 20)), activeColor: const Color(0xFF9E4770),
                        value: _notifikasiHaid, 
                        onChanged: (bool value) async { 
                          if (value == true) {
                            bool granted = await NotificationService().requestPermissions();
                            if (!granted) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Izin notifikasi ditolak. Tidak dapat mengaktifkan notifikasi.')),
                                );
                              }
                              return; // Batalkan perubahan state
                            }
                          }
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('notif_haid', value);
                          setState(() { _notifikasiHaid = value; }); 
                          await NotificationService().updateScheduledNotifications();
                        },
                      ),
                      const Divider(height: 1, indent: 60, color: Color(0xFFFFF0F5)),
                      SwitchListTile(
                        title: const Text('Notifikasi Masa Subur', style: TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.w500)), secondary: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.favorite_border, color: Color(0xFFD87093), size: 20)), activeColor: const Color(0xFF9E4770),
                        value: _notifikasiSubur, 
                        onChanged: (bool value) async { 
                          if (value == true) {
                            bool granted = await NotificationService().requestPermissions();
                            if (!granted) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Izin notifikasi ditolak. Tidak dapat mengaktifkan notifikasi.')),
                                );
                              }
                              return; // Batalkan perubahan state
                            }
                          }
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('notif_subur', value);
                          setState(() { _notifikasiSubur = value; }); 
                          await NotificationService().updateScheduledNotifications();
                        },
                      ),
                    ],
                  ),
                ).animate().fade(duration: 600.ms, delay: 600.ms).slideY(begin: 0.1),
                const SizedBox(height: 30),

                Align(alignment: Alignment.centerLeft, child: Text('KEAMANAN & AKUN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF9E4770).withOpacity(0.8), letterSpacing: 1.5))).animate().fade(delay: 700.ms),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: const Color(0xFFD87093).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))]),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.fingerprint, color: Colors.blue, size: 20)),
                        title: const Text('Kunci Aplikasi', style: TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.w500)),
                        subtitle: const Text('Gunakan biometrik untuk membuka aplikasi', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeColor: const Color(0xFF9E4770),
                        value: _isFingerprintActive,
                        onChanged: (bool value) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('is_biometric_enabled', value);
                          setState(() {
                            _isFingerprintActive = value;
                          });
                        },
                      ),
                      const Divider(height: 1, indent: 60, color: Color(0xFFFFF0F5)),
                      
                      ListTile(
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.picture_as_pdf, color: Colors.grey, size: 20)), 
                        title: const Text('Ekspor Data (PDF)', style: TextStyle(color: Color(0xFF6A304C), fontWeight: FontWeight.w500)), 
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey), 
                        onTap: _buatDanUnduhPDF 
                      ),
                      const Divider(height: 1, indent: 60, color: Color(0xFFFFF0F5)),
                      ListTile(
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20)), 
                        title: const Text('Hapus Seluruh Data', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)), 
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey), 
                        onTap: _konfirmasiHapusData
                      ),
                      const Divider(height: 1, indent: 60, color: Color(0xFFFFF0F5)),
                      ListTile(
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person_off, color: Colors.red, size: 20)), 
                        title: const Text('Hapus Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), 
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey), 
                        onTap: _konfirmasiHapusAkun
                      ),
                    ],
                  ),
                ).animate().fade(duration: 600.ms, delay: 700.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget Bantuan Ekstra untuk Tombol Dialog
class ElevButtonHapus extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const ElevButtonHapus({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}