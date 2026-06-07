# Master Plan: Optimasi UX Input Jadwal (Alternatif Pragmatis)

Setelah mengevaluasi risiko keamanan secara mendalam (terutama ancaman *reverse-engineering* pada API Key yang ditanam) dan tingginya potensi *friction* teknis pada sistem deteksi AI, kita membuang rencana Opsi A dan Opsi B. 

Kita beralih ke rute yang lebih tangguh, rasional, dan berorientasi pada pengguna: **Opsi C - Menghancurkan rasa malas pengguna melalui desain UX yang sangat mulus (*Frictionless Manual Input*).**

Fokus utama kita adalah mengubah proses input manual yang tadinya terasa "menyebalkan" menjadi sebuah pengalaman cepat yang "selesai dalam 3 menit".

## Rencana Fitur UX (Opsi C)

### 1. Template Jadwal Siap Pakai (Quick Add)
- **Konsep**: Menghindari formulir kosong yang mengintimidasi.
- **Eksekusi**: Menyediakan *grid* jadwal mingguan (Senin-Jumat) dengan slot waktu yang sudah terpetakan secara umum. Pengguna cukup mengetuk slot kosong di hari tertentu, dan form akan otomatis menyerap hari dan jam dari slot tersebut tanpa perlu input manual.

### 2. Input Massal (Batch Input)
- **Konsep**: Meminimalisir navigasi bolak-balik antar layar.
- **Eksekusi**: Mengubah halaman tambah mata kuliah menjadi *dynamic list*. Pengguna bisa mengetik Nama Matkul 1, lalu langsung menekan tombol "Tambah Baris Baru", ketik Matkul 2, dst. Setelah semua tertulis, cukup tekan **1 tombol "Simpan Semua"** untuk memasukkan 10 mata kuliah sekaligus ke database SQLite.

### 3. Preset Waktu Kuliah Cepat (Time Chips)
- **Konsep**: *TimePicker* bawaan OS (*dial* jam) terkadang memakan waktu lama untuk diatur dengan presisi.
- **Eksekusi**: Menambahkan tombol-tombol *preset* interaktif (*Chips*) di atas form waktu, misalnya: `[07:00]`, `[09:00]`, `[13:00]`, `[15:30]`. Satu ketukan akan langsung mengisi formulir jam tanpa pengguna harus menyentuh *TimePicker* sama sekali.

### 4. Duplikasi Jadwal (Satu Ketukan)
- **Konsep**: Membantu input untuk kelas praktikum atau mata kuliah dengan sks besar yang dipecah ke beberapa hari dengan jam yang sama.
- **Eksekusi**: Pada setiap kartu jadwal yang ada di aplikasi, ditambahkan tombol aksi **"Duplikat"**. Jika ditekan, form baru akan terbuka dengan membawa semua data jadwal aslinya, sehingga pengguna hanya perlu mengubah harinya saja lalu simpan.

---

## Mengapa Pendekatan Opsi C Lebih Superior?

| Aspek | Fitur AI Extract (Risiko Tinggi) | Optimasi UX Manual (Opsi C) |
|-------|-----------------------------|----------------------|
| **Keamanan** | API Key sangat rentan di-*reverse engineer* peretas. | **100% Aman.** Tidak ada *secret key* apa pun. |
| **Ketergantungan**| Bergantung mutlak pada server Google & limit kuota gratis. | **Zero dependencies.** Mandiri tanpa butuh internet. |
| **Akurasi Data** | Bisa salah baca (*typo*) jika foto buram atau tabel miring. | **100% Akurat** sesuai dengan niat ketikan pengguna. |
| **Privasi** | Mengunggah foto data kampus pengguna ke server *Cloud*. | **Mutlak terjaga.** Data tidak pernah keluar dari memori lokal HP. |

Dokumen ini merupakan kerangka kerja final yang diandalkan untuk menuntaskan masalah "rasa malas input data" pengguna.

---

# Roadmap Kehalusan (Polish Roadmap): Dari 68% → 90%+

Aplikasi sudah memiliki fondasi yang kuat, tetapi masih ada beberapa lapisan *finishing* yang perlu diasah agar terasa benar-benar *production-ready*. Berikut daftar pekerjaan yang perlu diselesaikan, diurutkan berdasarkan dampak terbesar ke pengguna.

## 🔴 Prioritas Tinggi (Dampak Langsung ke Pengguna)

### P1: Eksekusi Opsi C — UX Input Jadwal
Empat fitur di atas (Quick Add Grid, Batch Input Matkul, Time Chips, Duplikat Jadwal) belum dieksekusi ke kode sama sekali. Ini adalah fitur yang paling langsung mempengaruhi pengalaman pertama pengguna baru saat mengisi data.

### P2: Validasi Form yang Ketat
Saat ini form tidak memiliki penjaga yang cukup kuat. Perlu ditambahkan:
- **Nama mata kuliah kosong** → tidak bisa disimpan, muncul pesan "Nama tidak boleh kosong".
- **Jadwal konflik** → jika pengguna menambahkan jadwal di hari dan jam yang sudah ada mata kuliah lain, tampilkan peringatan.
- **Deadline sudah lewat** → saat membuat tugas baru dengan tanggal deadline yang sudah lampau, tampilkan peringatan (bukan error keras, cukup peringatan kuning).
- **Jam deadline tidak masuk akal** → misalnya 25:00 atau nilai menit di luar 0-59.

### P3: Perbaikan `syncNotifications` — Jangan Hanya Sekali
Saat ini flag `_hasSyncedNotifications` mencegah sync dijalankan lebih dari sekali per sesi. Masalahnya: jika user menambah tugas baru di tengah sesi, lalu HP di-reboot, notifikasi tugas baru tersebut tidak ikut di-sync ulang saat aplikasi dibuka kembali. Solusinya: hapus flag itu, cukup jalankan sync saat `AppLifecycleState.resumed` tapi batasi frekuensinya dengan *debounce* (misal: min. 5 menit antar sync).

---

## 🟡 Prioritas Sedang (Kerapian Teknis)

### P4: Verifikasi Home Widget Pasca-Migrasi SQLite
Home Widget kemungkinan besar masih menggunakan cara lama untuk membaca data (atau belum diuji sama sekali setelah migrasi SQLite di v3.4.0). Perlu diuji secara manual di HP fisik untuk memastikan jadwal dan tugas tampil benar di layar beranda Android.

### P5: Loading State yang Konsisten
Beberapa operasi async (save, delete, restore backup) tidak menampilkan *loading indicator* apapun ke pengguna. Pengguna yang menekan tombol dua kali bisa menyebabkan operasi ganda. Perlu ditambahkan:
- Tombol simpan berubah menjadi *spinner* saat proses berlangsung.
- Halaman Settings menampilkan *loading overlay* saat proses Backup/Restore berjalan.

### P6: Feedback Visual yang Lebih Kaya
- Saat tugas ditandai selesai, tambahkan animasi centang (*checkmark animation*) yang memuaskan.
- Saat jadwal dihapus, tampilkan *Snackbar* dengan opsi "Batalkan" (*Undo*) dalam 3 detik.

---

## 🟢 Prioritas Rendah (Nice-to-Have)

### P7: Pesan Kosong yang Lebih Baik
Halaman tugas dan jadwal yang kosong (kondisi awal) saat ini hanya menampilkan teks biasa. Bisa ditingkatkan dengan ilustrasi SVG ringan yang lebih *engaging* dan *call-to-action* yang lebih jelas.

### P8: Ringkasan Status Kode Saat Ini

| Area | Status | Catatan |
|------|--------|---------|
| Arsitektur (SQLite + Provider) | ✅ Stabil | Tidak perlu diubah |
| Backup ZIP + Kompresi Foto | ✅ Selesai | v3.6.0 |
| Notifikasi (slot bug fix) | ✅ Selesai | v3.6.x |
| Tutorial/Onboarding | ✅ Selesai | v3.5.0 |
| Filter & Sort Tugas | ✅ Selesai | v3.5.0 |
| UX Input Jadwal (Opsi C) | ❌ Belum | Target berikutnya |
| Validasi Form | ❌ Belum | Perlu dikerjakan |
| Sync Notifikasi (debounce) | ⚠️ Parsial | Flag terlalu ketat |
| Home Widget | ⚠️ Belum diverifikasi | Perlu uji manual |
| Loading State Konsisten | ⚠️ Parsial | Hanya sebagian layar |
