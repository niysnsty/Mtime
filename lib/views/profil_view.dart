import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart'; 
import '../services/db_service.dart';
import 'edit_profil_view.dart';
import 'register_view.dart';

class ProfilView extends StatefulWidget {
  const ProfilView({super.key});

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  // --- STATE VARIABLES ---
  bool _notifHaid = true;
  bool _notifSubur = false;
  String _nama = 'Sarah';
  String _email = 'sarah@example.com';
  String _rataHaid = '7';
  String _rataSiklus = '28';
  String _prediksi = '-';
  String _photo = ''; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- LOGIKA MEMUAT DATA ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await DatabaseService.instance.readAllData();
    
    setState(() {
      _nama = prefs.getString('nama') ?? 'Sarah';
      _email = prefs.getString('email') ?? 'sarah@example.com';
      _rataHaid = prefs.getString('rata_haid') ?? '7';
      _rataSiklus = prefs.getString('rata_siklus') ?? '28';
      _notifHaid = prefs.getBool('notif_haid') ?? true;
      _notifSubur = prefs.getBool('notif_subur') ?? false;

      // Logika Sinkronisasi Foto Nyata / Icon Default
      String savedPhoto = prefs.getString('user_photo') ?? '';
      if (savedPhoto.startsWith('http')) {
        _photo = ''; 
      } else {
        _photo = savedPhoto; 
      }

      // Kalkulasi Prediksi Otomatis
      if (data.isNotEmpty) {
        DateTime lastStart = DateTime.parse(data.first['tanggal_mulai']);
        int cycleDays = int.tryParse(_rataSiklus) ?? 28;
        _prediksi = DateFormat('dd MMMM yyyy', 'id_ID').format(lastStart.add(Duration(days: cycleDays)));
      }
    });
  }

  // --- WIDGET FOTO PROFIL DINAMIS ---
  Widget _buildAvatar() {
    if (_photo.isEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.person, size: 60, color: Colors.white),
      );
    } else {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(File(_photo)),
        backgroundColor: Colors.transparent,
      );
    }
  }

  // --- FITUR: EKSPOR PDF & AUTO OPEN ---
  Future<void> _eksporDataKePDF(BuildContext context) async {
    final pdf = pw.Document();
    final data = await DatabaseService.instance.readAllData();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Laporan Riwayat Siklus MTime', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Nama Pengguna: $_nama'),
            pw.Text('Email: $_email'),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['No', 'Tanggal Mulai', 'Tanggal Selesai', 'Gejala'],
                ...List.generate(data.length, (index) {
                  final item = data[index];
                  return [
                    '${index + 1}',
                    item['tanggal_mulai'].toString().substring(0, 10),
                    item['tanggal_selesai']?.toString().substring(0, 10) ?? 'Berjalan',
                    item['gejala'] ?? '-'
                  ];
                })
              ],
            ),
          ],
        ),
      ),
    );

    try {
      final output = await getApplicationDocumentsDirectory();
      final filePath = "${output.path}/Laporan_MTime_$_nama.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await OpenFilex.open(filePath); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF Berhasil Dibuat dan Dibuka'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: Colors.red));
    }
  }

  // --- UX: DIALOG KONFIRMASI (HAPUS DATA/AKUN) ---
  void _showConfirmDialog({required String title, required String content, required VoidCallback onConfirm, bool isDanger = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(backgroundColor: isDanger ? Colors.red : const Color(0xFF9E4770)),
            child: const Text('Ya, Lanjutkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDER UTAMA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        elevation: 0,
        backgroundColor: const Color(0xFFFFF7F8),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // --- HEADER FOTO & IDENTITAS ---
            Center(
              child: InkWell(
                onTap: () async {
                  bool? updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView()));
                  if (updated == true) _loadData();
                },
                child: Column(
                  children: [
                    _buildAvatar(), 
                    const SizedBox(height: 12),
                    Text(_nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
                    Text(_email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ),
            
            _buildSectionTitle('DATA SIKLUS'),
            
            // UX UPDATE: Rata-rata Haid bisa diklik, menuju Edit Profil
            _buildListTile(
              Icons.water_drop_outlined, 
              'Rata-rata Haid ($_rataHaid Hari)',
              onTap: () async {
                bool? updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView()));
                if (updated == true) _loadData();
              }
            ),

            // UX UPDATE: Rata-rata Siklus bisa diklik, menuju Edit Profil
            _buildListTile(
              Icons.calendar_month_outlined, 
              'Rata-rata Siklus ($_rataSiklus Hari)',
              onTap: () async {
                bool? updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView()));
                if (updated == true) _loadData();
              }
            ),

            // UX UPDATE: Prediksi Berikutnya tidak pakai icon '>', menampilkan pesan info jika diklik
            _buildListTile(
              Icons.date_range_outlined, 
              'Prediksi Berikutnya ($_prediksi)',
              trailing: const SizedBox.shrink(), // Menghilangkan icon panah
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prediksi dihitung otomatis berdasarkan rata-rata siklus Anda.'),
                    backgroundColor: Color(0xFF9E4770),
                  ),
                );
              }
            ),

            _buildSectionTitle('PREFERENSI'),
            _buildListTile(
              Icons.notifications_none, 
              'Notifikasi Haid', 
              trailing: Switch(
                value: _notifHaid, 
                activeColor: Colors.pinkAccent, 
                onChanged: (v) async {
                  setState(() => _notifHaid = v);
                  (await SharedPreferences.getInstance()).setBool('notif_haid', v);
                }
              )
            ),
            _buildListTile(
              Icons.favorite_border, 
              'Notifikasi Masa Subur', 
              trailing: Switch(
                value: _notifSubur, 
                activeColor: Colors.pinkAccent, 
                onChanged: (v) async {
                  setState(() => _notifSubur = v);
                  (await SharedPreferences.getInstance()).setBool('notif_subur', v);
                }
              )
            ),

            _buildSectionTitle('KEAMANAN & AKUN'),
            _buildListTile(Icons.picture_as_pdf_outlined, 'Ekspor Data (PDF)', onTap: () => _eksporDataKePDF(context)),
            _buildListTile(Icons.refresh, 'Hapus Semua Data', onTap: () {
              _showConfirmDialog(
                title: 'Hapus Semua Riwayat?',
                content: 'Tindakan ini akan menghapus seluruh data haid Anda dari aplikasi secara permanen.',
                onConfirm: () async {
                  await DatabaseService.instance.deleteAllData();
                  Navigator.pop(context);
                  _loadData();
                }
              );
            }),
            _buildListTile(
              Icons.delete_outline, 
              'Hapus Akun', 
              iconColor: Colors.red,
              onTap: () {
                _showConfirmDialog(
                  title: 'Hapus Akun & Keluar?',
                  content: 'Anda akan keluar dari aplikasi dan semua data profil akan direset kembali seperti awal.',
                  isDanger: true,
                  onConfirm: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear(); 
                    await DatabaseService.instance.deleteAllData(); 
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RegisterView()), (route) => false);
                    }
                  }
                );
              }
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BANTUAN UI ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 24, bottom: 8),
      child: Text(title, style: const TextStyle(color: Color(0xFF9E4770), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
    );
  }

  Widget _buildListTile(IconData icon, String title, {Widget? trailing, Color? iconColor, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? const Color(0xFF9E4770), size: 22),
      title: Text(title, style: const TextStyle(color: Color(0xFF6A304C), fontSize: 14)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
    );
  }
}