import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart'; // Package untuk membuka file
import '../services/db_service.dart';
import 'edit_profil_view.dart';
import 'register_view.dart';

class ProfilView extends StatefulWidget {
  const ProfilView({super.key});

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  bool _notifHaid = true;
  bool _notifSubur = false;
  String _nama = 'Sarah', _email = 'sarah@example.com';
  String _rataHaid = '7', _rataSiklus = '28', _prediksi = '-', _photo = 'https://i.pravatar.cc/150?img=5';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await DatabaseService.instance.readAllData();
    
    setState(() {
      _nama = prefs.getString('nama') ?? 'Sarah';
      _email = prefs.getString('email') ?? 'sarah@example.com';
      _rataHaid = prefs.getString('rata_haid') ?? '7';
      _rataSiklus = prefs.getString('rata_siklus') ?? '28';
      _photo = prefs.getString('user_photo') ?? 'https://i.pravatar.cc/150?img=5';
      _notifHaid = prefs.getBool('notif_haid') ?? true;
      _notifSubur = prefs.getBool('notif_subur') ?? false;

      if (data.isNotEmpty) {
        DateTime lastStart = DateTime.parse(data.first['tanggal_mulai']);
        int cycleDays = int.tryParse(_rataSiklus) ?? 28;
        _prediksi = DateFormat('dd MMMM yyyy', 'id_ID').format(lastStart.add(Duration(days: cycleDays)));
      }
    });
  }

  // --- FITUR: PIN KEAMANAN ---
  void _tampilkanDialogPIN(BuildContext context) {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Atur PIN Keamanan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(hintText: 'Masukkan 4 digit PIN baru'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('app_pin', pinController.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Berhasil Diatur!'), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9E4770)),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      // Simpan file
      final output = await getApplicationDocumentsDirectory();
      final filePath = "${output.path}/Laporan_MTime_$_nama.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // UX: Buka file secara otomatis
      await OpenFilex.open(filePath); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF Berhasil Dibuat dan Dibuka'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

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
            child: const Text('Ya', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      appBar: AppBar(title: const Text('Profil'), elevation: 0, backgroundColor: const Color(0xFFFFF7F8)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: InkWell(
                onTap: () async {
                  bool? updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilView()));
                  if (updated == true) _loadData();
                },
                child: Column(
                  children: [
                    CircleAvatar(radius: 50, backgroundImage: NetworkImage(_photo)),
                    const SizedBox(height: 12),
                    Text(_nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
                    Text(_email, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            _buildSectionTitle('DATA SIKLUS'),
            _buildListTile(Icons.water_drop_outlined, 'Rata-rata Haid ($_rataHaid Hari)'),
            _buildListTile(Icons.calendar_month_outlined, 'Rata-rata Siklus ($_rataSiklus Hari)'),
            _buildListTile(Icons.date_range_outlined, 'Prediksi Berikutnya ($_prediksi)'),

            _buildSectionTitle('PREFERENSI'),
            _buildListTile(Icons.notifications_none, 'Notifikasi Haid', trailing: Switch(value: _notifHaid, activeColor: Colors.pinkAccent, onChanged: (v) async {
              setState(() => _notifHaid = v);
              (await SharedPreferences.getInstance()).setBool('notif_haid', v);
            })),
            _buildListTile(Icons.favorite_border, 'Notifikasi Masa Subur', trailing: Switch(value: _notifSubur, activeColor: Colors.pinkAccent, onChanged: (v) async {
              setState(() => _notifSubur = v);
              (await SharedPreferences.getInstance()).setBool('notif_subur', v);
            })),

            _buildSectionTitle('KEAMANAN & AKUN'),
            _buildListTile(Icons.lock_outline, 'Kunci Aplikasi (PIN)', onTap: () => _tampilkanDialogPIN(context)),
            _buildListTile(Icons.picture_as_pdf_outlined, 'Ekspor Data (PDF)', onTap: () => _eksporDataKePDF(context)),
            _buildListTile(Icons.refresh, 'Hapus Semua Data', onTap: () {
              _showConfirmDialog(title: 'Hapus Riwayat?', content: 'Semua riwayat akan hilang.', onConfirm: () async {
                await DatabaseService.instance.deleteAllData();
                Navigator.pop(context);
                _loadData();
              });
            }),
            _buildListTile(Icons.delete_outline, 'Hapus Akun', iconColor: Colors.red, onTap: () {
              _showConfirmDialog(title: 'Hapus Akun?', content: 'Data profil akan direset.', isDanger: true, onConfirm: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await DatabaseService.instance.deleteAllData();
                if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RegisterView()), (route) => false);
              });
            }),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(left: 20, top: 24, bottom: 8), child: Text(title, style: const TextStyle(color: Color(0xFF9E4770), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)));
  Widget _buildListTile(IconData icon, String title, {Widget? trailing, Color? iconColor, VoidCallback? onTap}) => ListTile(onTap: onTap, leading: Icon(icon, color: iconColor ?? const Color(0xFF9E4770), size: 22), title: Text(title, style: const TextStyle(color: Color(0xFF6A304C), fontSize: 14)), trailing: trailing ?? const Icon(Icons.chevron_right, size: 18, color: Colors.grey));
}