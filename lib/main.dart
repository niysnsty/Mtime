import 'package:flutter/material.dart';
import 'views/dashboard_view.dart';

void main() {
  runApp(const MtimeApp());
}

class MtimeApp extends StatelessWidget{
  const MtimeApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: "Mtime",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF48FB1),
          primary: const Color(0xFFF48FB1),
          secondary: const Color(0xFFCE93D8),
          surface: const Color(0xFFFAFAFA),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF48FB1),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      //rute sederhana
      initialRoute: '/',
      routes: {
        '/' : (context) => const DashboardView(),
      },   
    );
  }  
}
