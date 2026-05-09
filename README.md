# 🌸 MTime (Menstrual Time)

MTime adalah aplikasi pelacak siklus menstruasi pintar yang didesain secara elegan, minimalis, dan sangat memperhatikan *User Experience* (UX). Aplikasi ini membantu pengguna mencatat tanggal menstruasi, memantau riwayat siklus, serta memprediksi masa subur dan hari ovulasi secara otomatis berdasarkan kalkulasi data historis.

*Project ini dibuat untuk memenuhi tugas Mata Kuliah Mobile Programming (Semester 4).*

---

## Fitur Utama

Aplikasi ini menggunakan sistem *Bottom Navigation Bar* dengan 4 menu utama yang saling terintegrasi:

1. **Hari Ini (Beranda)**
   * Menampilkan ringkasan hari ke-berapa siklus saat ini berjalan.
   * Kalkulasi otomatis **Haid Berikutnya, Masa Subur, dan Hari Ovulasi**.
   * Menampilkan rata-rata haid dan siklus berdasarkan data historis pengguna.
   * **Smart Button (Mulai/Akhiri Haid):** Tombol dinamis yang menyesuaikan state database untuk mencatat awal dan akhir menstruasi hanya dengan satu ketukan.

2. **Kalender Interaktif**
   * Visualisasi kalender bulanan penuh.
   * Memberikan *highlight* (penanda visual khusus) pada tanggal-tanggal yang tercatat sebagai masa menstruasi.

3. **Catatan (Riwayat Siklus & Custom UI Bar)**
   * Menampilkan daftar riwayat siklus sebelumnya dengan kalkulasi durasi aktual.
   * **Custom Visual Bar:** Menampilkan proporsi visual siklus yang membedakan masa haid (Pink), masa jeda/aman (Abu-abu), dan masa ovulasi (Kuning) menggunakan logika *flexing layout*.

4. **Analisis Cerdas**
   * Laporan kesehatan otomatis yang membaca data riwayat dari SQLite.
   * Menghitung dan menampilkan variasi siklus (Siklus Terpendek & Terpanjang).
   * Mengekstrak dan menampilkan *Top 3 Gejala* yang paling sering dialami pengguna.

---

## Teknologi & Arsitektur

* **Framework:** Flutter (Dart)
* **Database:** `sqflite` (SQLite Local Database) - Menjamin 100% privasi data pengguna karena bersifat *offline* dan disimpan di memori perangkat.
* **Package Tambahan:** `table_calendar` (Untuk UI kalender interaktif).
* **State Management:** `StatefulWidget` (Native Flutter State Management).
* **Arsitektur:** Menggunakan pemisahan *Views* (UI) dan *Services* (Logika Database) agar kode mudah di-*maintain*.

---

