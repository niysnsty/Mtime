import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Package baru untuk galeri

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
  
  // Variabel untuk menyimpan jalur (*path*) foto di HP
  String _imagePath = ''; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaController.text = prefs.getString('nama') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _haidController.text = prefs.getString('rata_haid') ?? '7';
      _siklusController.text = prefs.getString('rata_siklus') ?? '28';
      
      // Ambil path foto. Jika sebelumnya masih pakai link pravatar, kita kosongkan saja agar jadi icon default
      String savedPhoto = prefs.getString('user_photo') ?? '';
      if (savedPhoto.startsWith('http')) {
        _imagePath = '';
      } else {
        _imagePath = savedPhoto;
      }
    });
  }

  Future<void> _simpan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', _namaController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('rata_haid', _haidController.text);
    await prefs.setString('rata_siklus', _siklusController.text);
    await prefs.setString('user_photo', _imagePath); // Simpan path foto

    if (mounted) {
      Navigator.pop(context, true); // Kirim sinyal ke halaman sebelumnya
    }
  }

  // --- LOGIKA BUKA GALERI ASLI ---
  Future<void> _pilihFoto() async {
    // Tutup bottom sheet terlebih dahulu
    Navigator.pop(context); 
    
    // Buka galeri HP
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imagePath = image.path; // Simpan jalur file asli dari HP
      });
    }
  }

  void _tampilkanMenuFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF9E4770)),
            title: const Text('Pilih dari Galeri'),
            onTap: _pilihFoto, // Panggil fungsi buka galeri
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Hapus Foto'),
            onTap: () {
              setState(() => _imagePath = ''); // Mengosongkan foto
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Widget khusus untuk menampilkan Avatar atau Icon Default
  Widget _buildAvatar() {
    if (_imagePath.isEmpty) {
      // Jika foto kosong (dihapus), tampilkan logo user abu-abu (seperti WA/IG)
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.person, size: 60, color: Colors.white),
      );
    } else {
      // Jika ada foto, tampilkan foto dari memori HP
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(File(_imagePath)),
        backgroundColor: Colors.transparent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      appBar: AppBar(
        title: const Text('Edit Profil', style: TextStyle(color: Colors.black87)), 
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black87)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _tampilkanMenuFoto,
              child: Stack(
                children: [
                  _buildAvatar(), // Panggil widget avatar dinamis
                  Positioned(
                    bottom: 0, right: 0, 
                    child: Container(
                      padding: const EdgeInsets.all(6), 
                      decoration: BoxDecoration(color: const Color(0xFF9E4770), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), 
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16)
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildField('Nama', _namaController),
            _buildField('Email', _emailController),
            _buildField('Rata-rata Haid', _haidController, isNumber: true),
            _buildField('Rata-rata Siklus', _siklusController, isNumber: true),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _simpan,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9E4770), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
            ),
          ),
        ],
      ),
    );
  }
}