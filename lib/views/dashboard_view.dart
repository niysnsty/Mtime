import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
    const DashboardView({super.key});

    @override
    State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>{
    @override
    Widget build(BuildContext context){
        return Scaffold(
            appBar: AppBar(
                title: const Text(
                    "Mtime",
                    style: TextStyle(fontWeight: FontWeight.bold),
                ),
            ),
            //SingleChildScrollView agar layar bisa di scroll jika kontennya panjang
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // 1. Bagian greeting (Sapaan)
                        const Text(
                            "Halo, Cantik!👋",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                            ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            "Bagaimana Perasaan Anda Hari Ini?",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                            ),
                        ),
                        const SizedBox(height: 30),
                        //2. Card Info Siklus (Elegan dengan gradasi dan shadow)
                        Card(
                            elevation: 4, //memberikan efek bayangan halus
                            shadowColor: const Color(0xFFF48FB1).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                                width: double.infinity,//memnuhi layar lebar
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    //memberikan warna gradasi pink ke ungu pastel
                                    gradient: const LinearGradient(
                                        colors:[Color(0xFFF48FB1), Color(0xFFCE93D8)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                    ),
                                ),
                                child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children:[
                                        Text(
                                            "Siklus Menstruasi",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                            ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                            "Hari Ke-14", //data bohongan sementara
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize:36,
                                                fontWeight: FontWeight.bold,
                                            ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                            "Menstruasi berikutnya: 18 Mei", // data bohongan sementara
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                            ),
                                        ),
                                    ],
                                ),                       
                            ),         
                        ),
                        const SizedBox(height: 40),
                        // 3. Tombol Tambah Data
                        const Text(
                            "Aksi Cepat",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                            ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                            width:double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                                onPressed: (){
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("Next Fitur 😊"),
                                            duration: Duration(seconds:2),                                            
                                        ),
                                    );
                                },
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text(
                                    "Catatan",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                    ),
                                ),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary, //warna pink dari tema
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 2,
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}