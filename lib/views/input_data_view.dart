import 'package:flutter/material.dart';
import '../services/db_service.dart';

class InputDataView extends StatefulWidget {
  const InputDataView({super.key});

  @override
  State<InputDataView> createState() => _InputDataViewState();
}

class _InputDataViewState extends State<InputDataView> {
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  
  final TextEditingController _gejalaController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  Future<void> _pilihTanggal(BuildContext context, bool isMulai) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _simpanKeDatabase() async {
    if (_tanggalMulai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oops! Tanggal mulai wajib diisi ya.')),
      );
      return; 
    }

    final data = {
      'tanggal_mulai': _tanggalMulai!.toIso8601String(),
      'tanggal_selesai': _tanggalSelesai?.toIso8601String(),
      'gejala': _gejalaController.text.isEmpty ? 'Tidak ada gejala' : _gejalaController.text,
      'catatan': _catatanController.text,
    };

    await DatabaseService.instance.insertData(data);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yeay! Data berhasil disimpan ke Database.')),
    );
    Navigator.pop(context); 
  }

  @override
  void dispose() {
    _gejalaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Data', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tanggal Mulai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pilihTanggal(context, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tanggalMulai == null 
                          ? 'Pilih Tanggal' 
                          : '${_tanggalMulai!.day}/${_tanggalMulai!.month}/${_tanggalMulai!.year}',
                      style: TextStyle(color: _tanggalMulai == null ? Colors.grey : Colors.black87),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Tanggal Selesai (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pilihTanggal(context, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tanggalSelesai == null 
                          ? 'Pilih Tanggal' 
                          : '${_tanggalSelesai!.day}/${_tanggalSelesai!.month}/${_tanggalSelesai!.year}',
                      style: TextStyle(color: _tanggalSelesai == null ? Colors.grey : Colors.black87),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Gejala yang Dirasakan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _gejalaController,
              decoration: InputDecoration(
                hintText: 'Misal: Kram perut, pusing',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Catatan Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _catatanController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan jika ada...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                // Perbaikan di sini: menggunakan arrow function agar lebih aman
                onPressed: () => _simpanKeDatabase(), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  'Simpan Data', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}