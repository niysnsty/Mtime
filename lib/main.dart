import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:mtime/services/notification_service.dart';

import 'views/main_navigation.dart';
import 'views/onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService().init();
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
  DateTime? _lastPausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isSetupDone) {
      _jalankanSplashDanOtentikasi();
    } else {
      _isSplashVisible = false; // Don't show splash if setup is not done
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      if (!_isAuthenticating && widget.isSetupDone) {
        _lastPausedTime ??= DateTime.now();
      }
    } 
    else if (state == AppLifecycleState.resumed) {
      if (!_isAuthenticating && widget.isSetupDone) {
        bool shouldLock = true;
        if (_lastPausedTime != null) {
          final difference = DateTime.now().difference(_lastPausedTime!);
          if (difference.inMinutes < 5) {
            shouldLock = false;
          }
        }

        if (shouldLock) {
          // Hanya kunci jika lebih dari 5 menit
          setState(() {
            if (_isBiometricEnabled) {
              _isAuthenticated = false;
            }
          });
          _jalankanSplashDanOtentikasi();
        } else {
          // Reset timer if resumed within grace period
          _lastPausedTime = null;
        }
      }
    }
  }

  Future<void> _jalankanSplashDanOtentikasi() async {
    final prefs = await SharedPreferences.getInstance();
    // Default false, jadi hanya aktif jika user secara eksplisit mengaktifkannya setelah punya akun
    _isBiometricEnabled = prefs.getBool('is_biometric_enabled') ?? false;

    // Pastikan layar splash menyala
    if (mounted) {
      setState(() {
        _isSplashVisible = true;
      });
    }

    // Jeda estetik 0,8 detik
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
          _isSplashVisible = false; 
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF48FB1),
          primary: const Color(0xFFD87093),
          secondary: const Color(0xFFFFCA28),
          surface: const Color(0xFFFFF7F8),
        ),
        textTheme: GoogleFonts.amitaTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFFFF7F8),
      ),
      home: widget.isSetupDone ? const MainNavigation() : const OnboardingView(),
      builder: (context, child) {
        if (widget.isSetupDone && _isSplashVisible) {
          return const Scaffold(
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
          );
        }

        if (widget.isSetupDone && !_isAuthenticated && _isBiometricEnabled) {
          return Scaffold(
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
          );
        }

        return child!;
      },
    );
  }
}