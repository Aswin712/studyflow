# 📚 StudyFlow

StudyFlow adalah aplikasi manajemen akademik berbasis mobile yang dirancang khusus untuk membantu mahasiswa mengatur jadwal tugas, ujian, serta produktivitas belajar mereka secara lebih efektif.

## ✨ Fitur Utama

- **📝 Manajemen Tugas & Ujian**: Catat, pantau, dan kelola tugas serta jadwal ujian dengan mudah di satu tempat.
- **🔔 Notifikasi Pintar Berbasis Prioritas**: Sistem pengingat (reminder) yang cerdas dan berjalan di latar belakang:
  - **Prioritas Rendah**: Pengingat otomatis H-1 sebelum tenggat waktu.
  - **Prioritas Sedang**: Pengingat mulai H-3, H-2, H-1, dan pada hari-H.
  - **Prioritas Tinggi**: Pengingat setiap hari sejak H-6 dan peringatan final 1 jam sebelum deadline/ujian.
- **🎨 Kustomisasi Tema**: Mendukung Tema Terang (Light Mode), Tema Gelap (Dark Mode), atau mengikuti preferensi sistem perangkat.
- **💾 Backup & Restore Data**: Fitur ekspor dan impor data jadwal untuk menjamin keamanan data dan memudahkan pemindahan perangkat.
- **📱 Widget Beranda**: Pantau tugas terdekat dan ujian langsung dari _home screen_ smartphone Anda.
- **🌐 Offline Support**: Aplikasi berjalan secara lokal tanpa memerlukan koneksi internet aktif.

## 🛠️ Teknologi yang Digunakan

- **Framework SDK**: [Flutter](https://flutter.dev/)
- **Bahasa Pemrograman**: Dart
- **State Management**: `provider`
- **Notifikasi Latar Belakang**: `flutter_local_notifications` dengan integrasi `timezone` untuk akurasi waktu lokal.

## 🚀 Cara Menjalankan Proyek

### Prasyarat
Pastikan environment pengembangan Anda sudah siap:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) terbaru.
- Android Studio atau Visual Studio Code.
- Emulator Android / iOS atau perangkat fisik (dengan _USB Debugging_ aktif).

### Instalasi & Menjalankan
1. **Clone repositori proyek ini:**
   ```bash
   git clone https://github.com/your-username/studyflow.git
   cd studyflow
   ```

2. **Unduh semua dependency yang dibutuhkan:**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi di perangkat:**
   ```bash
   flutter run
   ```

## 📁 Struktur Folder Utama

```text
lib/
├── app/               # Konfigurasi utama dan root widget aplikasi
├── core/              # Komponen inti (Services seperti NotificationService, Theme)
├── features/          # Modul fitur spesifik (Settings, Tugas, Ujian, Dashboard)
├── models/            # Struktur data (Task, Exam, dsb.)
├── utils/             # Utility (Formatter tanggal, konstanta global)
└── main.dart          # Entry point aplikasi
```

## 🤝 Kontribusi

Kami sangat menyambut kontribusi (Pull Request) dari siapa saja! Jika Anda ingin berkontribusi:
1. Lakukan *Fork* pada repositori ini.
2. Buat *branch* fitur Anda (`git checkout -b fitur-keren-anda`).
3. Lakukan *Commit* perubahan Anda (`git commit -m 'Menambahkan fitur keren'`).
4. *Push* ke branch Anda (`git push origin fitur-keren-anda`).
5. Buat *Pull Request* baru.

## 📄 Lisensi

Proyek StudyFlow merupakan perangkat lunak *open-source* dan dilisensikan secara bebas.
