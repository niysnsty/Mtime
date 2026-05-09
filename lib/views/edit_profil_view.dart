import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilView extends StatefulWidget {
  const EditProfilView({super.key});

  @override
  State<EditProfilView> createState() => _EditProfilViewState();
}

class _EditProfilViewState extends State<EditProfilView> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _haidController = TextEditingController();
  final _siklusController = TextEditingController();
  DateTime? _tanggalLahir;
  String _imagePath = 'https://i.pravatar.cc/150?img=5'; // Foto default

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaController.text = prefs.getString('nama') ?? 'Sarah';
      _emailController.text = prefs.getString('email') ?? 'sarah@example.com';
      _haidController.text = prefs.getString('rata_haid') ?? '7';
      _siklusController.text = prefs.getString('rata_siklus') ?? '28';
      _imagePath = prefs.getString('user_photo') ?? 'https://i.pravatar.cc/150?img=5';
      String? tgl = prefs.getString('tanggal_lahir');
      if (tgl != null) _tanggalLahir = DateTime.parse(tgl);
    });
  }

  Future<void> _simpan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', _namaController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('rata_haid', _haidController.text);
    await prefs.setString('rata_siklus', _siklusController.text);
    await prefs.setString('user_photo', _imagePath);
    if (_tanggalLahir != null) {
      await prefs.setString('tanggal_lahir', _tanggalLahir!.toIso8601String());
    }

    if (mounted) {
      Navigator.pop(context, true); // Kirim 'true' agar halaman profil refresh
    }
  }

  // UX: Simulasi Ganti Foto Profil
  void _pilihFoto() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pilih dari Galeri (Simulasi)'),
            onTap: () {
              setState(() {
                // Kita ganti id fotonya saja untuk simulasi perubahan
                _imagePath = 'https://i.pravatar.cc/150?img=47'; 
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Hapus Foto'),
            onTap: () {
              setState(() => _imagePath = 'https://i.pravatar.cc/150?img=5');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      appBar: AppBar(title: const Text('Edit Profil'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pilihFoto,
              child: Stack(
                children: [
                  CircleAvatar(radius: 50, backgroundImage: NetworkImage(_imagePath)),
                  Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF9E4770), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18))),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildField('Nama', _namaController),
            _buildField('Email', _emailController),
            _buildField('Rata-rata Haid', _haidController, isNumber: true),
            _buildField('Rata-rata Siklus', _siklusController, isNumber: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _simpan,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9E4770), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
      ),
    );
  }
}