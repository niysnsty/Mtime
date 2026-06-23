import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'db_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // Untuk iOS bisa tambahkan konfigurasi jika perlu, tapi fokus kita Android
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    bool? granted = await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
    return granted ?? false;
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> _scheduleNotification({required int id, required String title, required String body, required DateTime scheduledDate}) async {
    if (scheduledDate.isBefore(DateTime.now())) return; // Jangan jadwalkan jika waktunya sudah lewat

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'siklus_channel',
          'Notifikasi Siklus',
          channelDescription: 'Notifikasi untuk haid dan masa subur',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          color: const Color(0xFFD87093), // Pink color
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> updateScheduledNotifications() async {
    // 1. Batalkan semua notifikasi lama
    await cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();
    bool notifHaid = prefs.getBool('notif_haid') ?? false;
    bool notifSubur = prefs.getBool('notif_subur') ?? false;

    if (!notifHaid && !notifSubur) return; // Jika semua mati, selesai.

    // 2. Ambil data untuk kalkulasi
    final data = await DatabaseService.instance.readAllData();
    if (data.isEmpty) return; // Belum ada data, tidak bisa prediksi

    String savedSiklus = prefs.getString('rata_siklus') ?? '28';
    int dynamicAvgSiklus = int.tryParse(savedSiklus) ?? 28;

    // Kalkulasi rata-rata siklus dinamis (sama seperti di KalenderView/ProfilView)
    int totalSiklusDays = 0, cycleCount = 0;
    if (data.length >= 2) {
      for (int i = 0; i < data.length - 1; i++) {
        DateTime currentStart = DateTime.parse(data[i]['tanggal_mulai']);
        DateTime prevStart = DateTime.parse(data[i+1]['tanggal_mulai']);
        totalSiklusDays += currentStart.difference(prevStart).inDays;
        cycleCount++;
      }
      if (cycleCount > 0) dynamicAvgSiklus = (totalSiklusDays / cycleCount).round();
    }

    DateTime haidTerbaru = DateTime.parse(data.first['tanggal_mulai']);
    // Tanggal Haid Berikutnya
    DateTime nextHaid = haidTerbaru.add(Duration(days: dynamicAvgSiklus));
    // Tanggal Ovulasi
    DateTime ovulasiDate = nextHaid.subtract(const Duration(days: 14));
    // Tanggal Masa Subur (4 hari sebelum ovulasi)
    DateTime suburMulai = ovulasiDate.subtract(const Duration(days: 4));

    // 3. Jadwalkan Notifikasi
    if (notifHaid) {
      // H-1 pukul 08:00
      DateTime jadwalHaid = DateTime(nextHaid.year, nextHaid.month, nextHaid.day - 1, 8, 0);
      
      // Jika ternyata jadwal H-1 sudah lewat, jadwalkan pada Hari H pukul 08:00
      if (jadwalHaid.isBefore(DateTime.now())) {
        jadwalHaid = DateTime(nextHaid.year, nextHaid.month, nextHaid.day, 8, 0);
      }
      
      await _scheduleNotification(
        id: 1,
        title: 'Pengingat Haid',
        body: 'Haid Anda diperkirakan akan segera datang. Siapkan pembalut Anda!',
        scheduledDate: jadwalHaid,
      );
    }

    if (notifSubur) {
      // H-1 pukul 08:00 sebelum masa subur
      DateTime jadwalSubur = DateTime(suburMulai.year, suburMulai.month, suburMulai.day - 1, 8, 0);
      
      if (jadwalSubur.isBefore(DateTime.now())) {
        jadwalSubur = DateTime(suburMulai.year, suburMulai.month, suburMulai.day, 8, 0);
      }
      
      await _scheduleNotification(
        id: 2,
        title: 'Masa Subur Dimulai',
        body: 'Masa subur Anda diperkirakan dimulai hari ini/besok.',
        scheduledDate: jadwalSubur,
      );
    }
  }
}
