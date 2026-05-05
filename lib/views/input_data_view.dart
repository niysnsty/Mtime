import 'package:flutter/material.dart';

class InputDataView extends StatefulWidget{
    const InputDataView({super.key});

    @override
    State<InputDataView> createState() => _InputDataViewState();
}

class _InputDataViewState extends State<InputDataView> {
    //variabel untuk menyimpan data yang diinput
    DateTime? _tanggalMulai;
    DateTime? _tanggalSelesai;

    //Controller untuk teks
    final TextEditingController _gejalaController = TextEditingController();
    final TextEditingController _catatanController = TextEditingController();

    //fungsi untuk memunculkan kalender
    Future<void> _pilihTanggal(BuildContext context, bool isMulai) async {
        final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
        );
        //jika user memilih tanggal
        if (picked != null){
            setState((){
                if (isMulai){
                    _tanggalMulai = picked;
                } else {
                    _tanggalSelesai = picked;
                }
            });
        }
    }
    //membersihkan controller saat halaman ditutup
    @override
    void dispose(){
        _gejalaController.dispose();
        _catatanController.dispose();
        super.dispose();
    }
    @override
    Widget build(BuildContext context){
        return Scaffold(
            appBar: AppBar(
                title: const Text('Catat Data', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        // field tanggal mulai
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
                                            _tanggalMulai == null? 'Pilih Tanggal': '${_tanggalMulai!.day}/${_tanggalMulai!.month}/${_tanggalMulai!.year}',
                                            style: TextStyle(color: _tanggalMulai == null? Colors.grey: Colors.black87),
                                        ),
                                        const Icon(Icons.calendar_today, color: Colors.grey),
                                    ],
                                ),
                            ),
                        ),
                        const SizedBox(height: 20),
                        // field tanggal selesai
                        const Text('Tanggal Selesai',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        InkWell(
                            onTap: () => _pilihTanggal(context, false),
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                ),
                                child:Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                        Text(
                                            _tanggalSelesai == null? 'Pilih Tanggal':'${_tanggalSelesai!.day}/${_tanggalSelesai!.month}/${_tanggalSelesai!.year}',
                                            style: TextStyle(color: _tanggalSelesai == null? Colors.grey: Colors.black87),
                                        ),
                                        const Icon(Icons.calendar_today, color: Colors.grey),
                                    ],
                                ),
                            ),
                        ),
                        // field gejala
                        const Text('Gejala Yang Dirasakan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        TextField(
                            controller: _gejalaController,
                            decoration: InputDecoration(
                                hintText: 'contoh: Kram Perut, Pusing',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                        ),
                        const SizedBox(height: 20),
                        // field catatan
                        const Text('Catatan Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        TextField(
                            controller: _catatanController,
                            maxLines: 3,
                            decoration: InputDecoration(
                                hintText: 'Tambahkan Catatan Jika ada...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                        ),
                        const SizedBox(height: 40),
                        // Tombol Simpan
                        SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                                onPressed: (){
                                    //validasi sederhana: Tanggal mulai tidak boleh kosong
                                    if(_tanggalMulai == null){
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('oops.. tanggal mulai belum diisi')),
                                        );
                                        return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(  
                                        const SnackBar(content: Text('Data Berhasil Ditambahkan!')),                             
                                    );
                                    Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                child: const Text(
                                    'Simpan Data',
                                    style: TextStyle(fontSize:16, fontWeight: FontWeight.bold, color: Colors.white)
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}