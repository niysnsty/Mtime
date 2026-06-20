import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart'; 

import 'views/main_navigation.dart';
import 'views/onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('id_ID', null);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  final prefs = await SharedPreferences.getInstance();
  bool isSetupDone = prefs.getBool('is_logged_in') ?? false;

  runApp(MTimeApp(isSetupDone: isSetupDone));
}

class MTimeApp extends StatefulWidget {
  final bool isSetupDone;
  const MTimeApp({super.key, required this.isSetupDone});

  @override
  State<MTimeApp> createState() => _MTimeAppState();
}

class _MTimeAppState extends State<MTimeApp> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isBiometricEnabled = true;
  bool _isAuthenticating = false; 
  
  // Variabel khusus untuk mengontrol layar transisi
  bool _isSplashVisible = true; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _jalankanSplashDanOtentikasi();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat aplikasi diminimalkan / masuk background
    if (state == AppLifecycleState.paused) {
      if (!_isAuthenticating) {
        setState(() {
          _isSplashVisible = true; // SELALU siapkan layar splash saat masuk background
          if (_isBiometricEnabled) {
            _isAuthenticated = false; // Kunci aplikasi HANYA JIKA sidik jari aktif
          }
        });
      }
    } 
    // Saat aplikasi dibuka kembali
    else if (state == AppLifecycleState.resumed) {
      if (!_isAuthenticating && widget.isSetupDone) {
        _jalankanSplashDanOtentikasi(); // SELALU jalankan splash saat dibuka ulang
      }
    }
  }

  Future<void> _jalankanSplashDanOtentikasi() async {
    final prefs = await SharedPreferences.getInstance();
    _isBiometricEnabled = prefs.getBool('is_biometric_enabled') ?? true;

    // Pastikan layar splash menyala
    if (mounted) {
      setState(() {
        _isSplashVisible = true;
      });
    }

    // Jeda estetik 0,8 detik yang akan SELALU MUNCUL
    await Future.delayed(const Duration(milliseconds: 800));

    // Jika sidik jari aktif, lanjut ke pemindaian
    if (_isBiometricEnabled) {
      _otentikasiBiometrik();
    } 
    // Jika tidak aktif, langsung masuk ke aplikasi dan matikan layar splash
    else {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isSplashVisible = false;
        });
      }
    }
  }

  Future<void> _otentikasiBiometrik() async {
    if (_isAuthenticating) return; 

    _isAuthenticating = true; 

    try {
      bool canAuthenticate = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isSplashVisible = false;
          });
        }
        _isAuthenticating = false;
        return;
      }

      bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Mohon pindai sidik jari Anda untuk membuka MTime',
      );

      if (mounted) {
        setState(() {
          _isAuthenticated = didAuthenticate;
          _isSplashVisible = false; // Matikan splash setelah sidik jari sukses/gagal
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      _isAuthenticating = false;

    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false; 
          _isSplashVisible = false;
        });
      }
      await Future.delayed(const Duration(milliseconds: 500));
      _isAuthenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. LAYAR JEDA TRANSISI ESTETIK (Selalu muncul di awal dan saat Resume)
    if (widget.isSetupDone && _isSplashVisible) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFFFFF7F8),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, size: 80, color: Color(0xFF9E4770)),
                SizedBox(height: 20),
                Text(
                  'MTime',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF6A304C), letterSpacing: 1.5),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: 30, height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9E4770)),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    // 2. TAMPILAN TERKUNCI (Jika gagal sidik jari atau batal)
    if (widget.isSetupDone && !_isAuthenticated && _isBiometricEnabled) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFFFF7F8),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 80, color: Color(0xFF9E4770)),
                  const SizedBox(height: 24),
                  const Text('MTime Terkunci', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6A304C))),
                  const SizedBox(height: 10),
                  const Text('Aplikasi ini dilindungi keamanan biometrik demi menjaga privasi data kesehatan Anda.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.fingerprint, color: Colors.white),
                      label: const Text('Buka Kunci', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _otentikasiBiometrik,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9E4770), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. GERBANG MASUK UTAMA APLIKASI
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFFFF7F8),
      ),
      home: widget.isSetupDone ? const MainNavigation() : const OnboardingView(),
    );
  }
}