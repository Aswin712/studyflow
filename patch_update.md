# Patch Update

## Version 3.5.0 (Guide App, UX, & Optimasi Skala)
Pembaruan ini berfokus pada pengenalan aplikasi untuk pengguna baru (Guide App) serta optimasi tingkat lanjut pada UX dan manajemen penyimpanan untuk mencegah penumpukan data sampah.

### 🔴 Prioritas 1: Interactive Tutorial Banner (Guide App)
- **Solusi**: Menambahkan *floating banner* panduan langkah-demi-langkah interaktif di halaman Dashboard khusus untuk pengguna baru. Banner ini akan secara cerdas mendeteksi status kekosongan data (Mata Kuliah, Jadwal, Tugas) dan mengarahkan pengguna dengan navigasi otomatis.
- **Solusi Animasi**: Menambahkan efek animasi denyut (Pulse/Glow) pada tombol `+ Tambah` (Floating Action Button) di masing-masing tab yang sedang aktif di tutorial agar pengguna lebih terarah.
- **File Terdampak**:
  - `lib/shared/widgets/tutorial_banner_widget.dart` (Baru)
  - `lib/shared/widgets/tutorial_fab_highlight.dart` (Baru)
  - `lib/app/app.dart`
  - `lib/features/course/screens/course_screen.dart`
  - `lib/features/schedule/screens/schedule_screen.dart`
  - `lib/features/task/screens/task_screen.dart`

### 🟡 Prioritas 2: Optimasi Penyimpanan & Notifikasi (Resync & Orphan Files)
- **Solusi Foto (Orphan Files)**: Menutup celah kebocoran memori (Storage Leak). Sebelumnya, foto lama tidak terhapus jika pengguna *mengedit* tugas dan mengganti fotonya. Kini, sistem membandingkan path foto lama dan baru saat proses `update`, dan otomatis menghapus foto lama secara permanen.
- **Solusi Notifikasi (Silent Resync)**: Menambahkan mekanisme *Silent Resync* di `app.dart` yang memanggil `syncNotifications()` untuk mengamankan dan mendaftarkan ulang semua alarm/tugas saat aplikasi pertama kali dibuka. Ini memperbaiki isu hilangnya alarm akibat *cache* OS yang terhapus setelah proses *reboot*.
- **File Terdampak**:
  - `lib/features/task/providers/task_provider.dart`
  - `lib/features/exam/providers/exam_provider.dart`
  - `lib/app/app.dart`

### 🟡 Prioritas 3: Filter & Pengurutan Tingkat Lanjut (UX)
- **Solusi**: Memperkaya halaman Tugas (`TaskScreen`) dengan opsi *FilterChips* horisontal untuk menyaring tugas berdasarkan mata kuliah tertentu. Ditambah sebuah *PopupMenuButton* untuk mengurutkan daftar tugas secara dinamis (Deadline Terdekat, Deadline Terjauh, atau Prioritas Tinggi).
- **File Terdampak**:
  - `lib/features/task/providers/task_provider.dart`
  - `lib/features/task/screens/task_screen.dart`

### 🔧 Perbaikan Bug (Hotfixes)
- **SQLite Database Crash**: Memperbaiki skema tabel database dan migrasi dari SharedPreferences yang sebelumnya *crash* di versi 3.4.0.
- **Google Fonts Offline**: Menghapus blokade `allowRuntimeFetching` agar font utama aplikasi dapat diunduh jika tidak tersedia secara luring.

### Daftar Semua File yang Diubah
| File | Jenis Perubahan |
|---|---|
| `lib/shared/widgets/tutorial_banner_widget.dart` | **File Baru** — Banner Panduan Pengguna Baru |
| `lib/shared/widgets/tutorial_fab_highlight.dart` | **File Baru** — Animasi Denyut Tombol FAB |
| `lib/app/app.dart` | Integrasi Tutorial Banner dan Silent Notification Resync |
| `lib/features/task/providers/task_provider.dart` | Logika hapus foto lama (Update), Sinkronisasi Notif, Filter & Sort |
| `lib/features/task/screens/task_screen.dart` | UI FilterChips dan Sort Menu |
| `pubspec.yaml` | Version bump → 3.5.0+350 |

---

## Version 3.4.0 (Migrasi SQLite & Arsitektur)
### Arsitektur & Performa 🚀
- **Migrasi Database:** Seluruh penyimpanan utama (Mata Kuliah, Tugas, Jadwal, Ujian) yang sebelumnya berbasis JSON text (`SharedPreferences`) kini telah dimigrasikan ke **SQLite**!
- **Kinerja Cepat (O(1)):** Operasi hapus/tambah data kini langsung mengeksekusi tabel database, bukan memparsing ulang seluruh baris JSON, sehingga meminimalisir frame-drop dan konsumsi memori saat data sangat banyak.
- **Auto-Migration:** Pengguna yang *update* dari versi 3.3.0 tidak akan kehilangan data. Sistem otomatis memindahkan JSON lama (sf_*) ke baris SQLite pada saat instalasi pertama selesai, tanpa membebani UI.

### Fitur Tersembunyi (Under the Hood)
- **Backup & Restore V2:** Sistem pencadangan di `BackupService` kini berinteraksi langsung dengan Database SQLite. Kecepatan *import/export* data jauh lebih cepat.
- **Asynchronous Providers:** Transisi state menjadi *asynchronous* yang lebih stabil, memastikan tidak ada file yang *corrupt* saat dihentikan mendadak.


## Version 3.3.0 (Polishing & Platform Features)
Pembaruan ini adalah fase final dari optimasi, menghadirkan fitur setara *production* melalui penambahan Onboarding, proteksi crash global, peningkatan fitur platform OS, dan Unit Testing.

### 🔴 Prioritas 1: Onboarding & Animasi Transisi (UX)
- **Solusi**: 
  - Menambahkan `OnboardingScreen` yang muncul hanya saat aplikasi pertama kali diinstal (dilacak menggunakan `keyFirstLaunch` di `LocalStorageService`).
  - Menerapkan `PageTransitionsTheme` dengan `CupertinoPageTransitionsBuilder` di seluruh aplikasi agar perpindahan layar terasa lebih halus (*premium*).
- **File Terdampak**: 
  - `lib/features/onboarding/screens/onboarding_screen.dart` (Baru)
  - `lib/core/services/local_storage_service.dart`
  - `lib/core/theme/app_theme.dart`
  - `lib/app/app.dart` & `lib/main.dart`

### 🔴 Prioritas 2: Global Error Boundary (Arsitektur)
- **Solusi**: Membungkus seluruh aplikasi dengan `runZonedGuarded` dan membuat `GlobalErrorWidget` untuk menangkap crash (misalnya JSON *corrupt*) agar tidak menampilkan "Layar Abu-abu" (*Grey Screen of Death*), melainkan layar error yang lebih ramah pengguna.
- **File Terdampak**:
  - `lib/shared/widgets/error_boundary.dart` (Baru)
  - `lib/main.dart`

### 🟡 Prioritas 3: Deep Link Notifikasi & Advanced Widget (Platform)
- **Solusi**: 
  - **Notifikasi**: Menambahkan injeksi *payload* (`type|id`) pada notifikasi tugas/ujian. Saat notifikasi ditekan, aplikasi akan melakukan navigasi otomatis (deep link) ke halaman `TaskDetailScreen` atau `ExamDetailScreen` menggunakan `GlobalKey<NavigatorState>`.
  - **Widget Android**: Mengubah `WidgetService` agar Android Home Widget tidak hanya menampilkan jadwal kuliah, tetapi juga 3 tugas dengan *deadline* terdekat (dalam 3 hari ke depan).
- **File Terdampak**:
  - `lib/core/services/notification_service.dart`
  - `lib/core/services/widget_service.dart`
  - `lib/app/app.dart` & `lib/main.dart`

### 🟡 Prioritas 4: Unit Testing (Technical Debt)
- **Solusi**: Menyusun standar *Unit Testing* pada core logic (Repository & Provider) dengan bantuan _Mock_ `SharedPreferences`. Pengujian mencakup iterasi data dan listener status state.
- **File Terdampak**:
  - `test/features/course/repositories/course_repository_test.dart` (Baru)
  - `test/features/course/providers/course_provider_test.dart` (Baru)

### Daftar Semua File yang Diubah
| File | Jenis Perubahan |
|---|---|
| `lib/features/onboarding/screens/onboarding_screen.dart` | **File Baru** — Halaman pengenalan fitur aplikasi |
| `lib/shared/widgets/error_boundary.dart` | **File Baru** — Global Error Handler UI |
| `test/features/course/repositories/course_repository_test.dart` | **File Baru** — Unit Test untuk CourseRepository |
| `test/features/course/providers/course_provider_test.dart` | **File Baru** — Unit Test untuk CourseProvider |
| `lib/core/services/local_storage_service.dart` | Flag `keyFirstLaunch` untuk Onboarding |
| `lib/core/theme/app_theme.dart` | `PageTransitionsTheme` untuk *smooth routing* |
| `lib/main.dart` | Implementasi `runZonedGuarded`, Error Builder, dan Deep Linking Navigator |
| `lib/app/app.dart` | Menerima state `isFirstLaunch` & implementasi `onGenerateRoute` |
| `lib/core/services/notification_service.dart` | Penambahan payload untuk *Notification Deep Linking* |
| `lib/core/services/widget_service.dart` | Menampilkan **Tugas Terdekat** pada Home Widget |
| `pubspec.yaml` | Version bump → 3.3.0+330 |
| `lib/core/services/backup_service.dart` | Version update → 3.3.0 |

### Pembaruan Sistem
- **Update Versi Aplikasi**: Versi aplikasi telah diperbarui ke `3.3.0`.

## Version 3.2.0 (UX & Pembersihan)
Pembaruan ini menambahkan fitur-fitur yang meningkatkan kenyamanan pengguna (UX) serta memastikan sistem berjalan lebih bersih dari penumpukan data.

### 🔴 Prioritas 1: Kustomisasi Tema Aplikasi (Multi-Theme)
Sebelumnya, aplikasi hanya memiliki satu warna primer yaitu Indigo (dan mendukung Light/Dark mode). Kini pengguna dapat memilih warna aksen favorit mereka.
- **Solusi**: Memisahkan pengaturan tampilan ke halaman khusus `PersonalizationScreen`. Di dalamnya terdapat Theme Picker melingkar menggunakan enum `ThemePreset` dengan 5 pilihan warna elegan: Indigo (Default), Ocean Blue, Emerald Green, Rose Pink, dan Midnight Orange. Pilihan ini disimpan secara persisten di SharedPreferences dan di-inject langsung ke `AppTheme`.
- **File Terdampak**: 
  - `lib/core/theme/theme_presets.dart` (File Baru)
  - `lib/features/settings/personalization_screen.dart` (File Baru)
  - `lib/core/theme/app_theme.dart`
  - `lib/features/settings/setting_provider.dart`
  - `lib/features/settings/setting_screen.dart`
  - `lib/core/services/local_storage_service.dart`

### 🔴 Prioritas 2: Fitur Pencarian Tugas (Search/Filter)
Saat jumlah data tugas semakin banyak, pengguna kesulitan mencari tugas tertentu hanya dari *scroll* daftar.
- **Solusi**: Menambahkan `TextField` pencarian di atas daftar tugas pada halaman `TaskScreen`. Filter berjalan secara *realtime* dengan mencocokkan kata kunci terhadap judul tugas atau nama mata kuliah pengampu tugas tersebut. Menampilkan ilustrasi khusus jika hasil pencarian kosong.
- **File Terdampak**:
  - `lib/features/task/screens/task_screen.dart`

### 🟡 Prioritas 3: Pembersihan Foto Orphan (Garbage Collection)
Sebelumnya, jika pengguna menghapus sebuah tugas yang memiliki lampiran foto, data tugas tersebut terhapus dari database, tetapi **file fotonya tetap tertinggal** di memori internal pengguna (storage leak).
- **Solusi**: Menambahkan logika pembersihan fisik menggunakan `dart:io`. Saat `delete`, `deleteMultiple`, atau `deleteByCourse` dipanggil, `TaskProvider` akan memeriksa keberadaan path foto dan menjalankan `File(path).deleteSync()` sebelum menghapus record dari repository.
- **File Terdampak**:
  - `lib/features/task/providers/task_provider.dart`

### Daftar Semua File yang Diubah
| File | Jenis Perubahan |
|---|---|
| `lib/core/theme/theme_presets.dart` | **File Baru** — Definisi Enum warna tema |
| `lib/features/settings/personalization_screen.dart` | **File Baru** — Ekstraksi pengaturan tampilan |
| `lib/core/theme/app_theme.dart` | Dynamic seedColor generator dari ThemePreset |
| `lib/features/settings/setting_provider.dart` | Penambahan state & operasi save/load preset |
| `lib/features/settings/setting_screen.dart` | UI Theme Picker melingkar (Aksen Warna) |
| `lib/core/services/local_storage_service.dart` | Operasi persisten `keyThemePreset` & backup support |
| `lib/features/task/screens/task_screen.dart` | Search Bar UI & logika realtime text filter |
| `lib/features/task/providers/task_provider.dart` | Penghapusan file (Image) saat penghapusan Task |
| `pubspec.yaml` | Version bump → 3.2.0+5 |
| `lib/core/services/backup_service.dart` | Metadata version → 3.2.0 |

### Pembaruan Sistem
- **Update Versi Aplikasi**: Versi aplikasi telah diperbarui ke `3.2.0`.
- **Integrasi Library**: Import `dart:io` secara internal pada provider untuk operasi _filesystem_.


## Version 3.1.0 (Optimasi Performa)
Pembaruan ini berfokus sepenuhnya pada **peningkatan performa aplikasi** — tidak ada fitur baru yang ditambahkan. Seluruh optimasi bertujuan mengurangi waktu startup, meminimalkan penggunaan memori, dan mengurangi widget rebuild yang tidak perlu.

### 🔴 Prioritas 1: In-Memory Cache di Repository (Dampak Terbesar)
Sebelumnya, setiap operasi read (`getAll()`, `getById()`, `getByDay()`, `getPending()`, `getUpcoming()`) selalu memanggil `jsonDecode()` ulang dari SharedPreferences. Ini menyebabkan overhead signifikan terutama di Dashboard yang memanggil `getById()` berkali-kali untuk setiap jadwal dan tugas.

**Solusi**: Menambahkan layer cache in-memory di semua repository dengan mekanisme invalidation otomatis saat data berubah (save/delete).

- `lib/features/course/repositories/course_repository.dart` — Cache `List<Course>` + `Map<String, Course>` untuk lookup `getById()` dari O(n) menjadi O(1).
- `lib/features/task/repositories/task_repository.dart` — Cache `List<Task>` + invalidation pada `save()`, `delete()`, `toggleDone()`, `deleteByCourse()`.
- `lib/features/schedule/repositories/schedule_repository.dart` — Cache `List<Schedule>` + invalidation pada `save()`, `delete()`, `deleteByCourse()`.
- `lib/features/exam/repositories/exam_repository.dart` — Cache `List<Exam>` + invalidation pada `save()`, `delete()`, `deleteByCourse()`.

### 🔴 Prioritas 2: LazyIndexedStack (Lazy Loading Tab)
Sebelumnya, `IndexedStack` di `app.dart` langsung membuild **semua 5 screen** saat aplikasi pertama kali dibuka, meskipun user hanya melihat tab Dashboard.

**Solusi**: Membuat widget kustom `LazyIndexedStack` yang hanya membuild tab ketika user pertama kali mengunjunginya. Tab yang belum pernah dibuka tetap berupa placeholder `SizedBox.shrink()`.

- `lib/shared/widgets/lazy_indexed_stack.dart` — **[FILE BARU]** Widget `LazyIndexedStack` dengan tracking `Set<int>` untuk index yang sudah pernah diaktifkan.
- `lib/app/app.dart` — Mengganti `IndexedStack` dengan `LazyIndexedStack`. Saat cold start, hanya Dashboard (tab 0) yang di-build.

### 🟡 Prioritas 3: Granular Provider Listening (Selector)
Sebelumnya, `DashboardScreen` menggunakan `context.watch<SettingsProvider>()` yang menyebabkan **seluruh screen** rebuild setiap kali ada perubahan apapun pada SettingsProvider (termasuk perubahan tema yang tidak relevan).

**Solusi**: Mengganti `context.watch` dengan `Selector<SettingsProvider, String>` yang hanya mendengarkan perubahan pada field `userName`. Widget lain di Dashboard (StatRow, TodaySchedule, TaskProgress, Upcoming) sudah terisolasi dengan baik menggunakan `Consumer` masing-masing.

- `lib/features/dashboard/screens/dashboard_screen.dart` — Header section kini di-wrap dengan `Selector<SettingsProvider, String>` agar hanya rebuild saat `userName` berubah.

### 🟡 Prioritas 4: Google Fonts — Disable Runtime Fetching
Sebelumnya, package `google_fonts` akan mencoba **mengunduh font Outfit dari internet** saat pertama kali dipanggil. Ini menyebabkan delay pada cold start jika koneksi lambat, dan network request yang tidak perlu.

**Solusi**: Menonaktifkan runtime fetching agar font langsung diambil dari asset yang sudah terbundle di APK.

- `lib/main.dart` — Menambahkan `GoogleFonts.config.allowRuntimeFetching = false;` sebelum `runApp()`.

### 🟡 Prioritas 5: Optimasi Image Loading
Sebelumnya, semua `Image.file()` untuk foto tugas di-decode pada **resolusi penuh** (bisa sampai 1920px dari hasil kompresi ImagePicker) meskipun hanya ditampilkan pada container 200px. Ini memboroskan RAM secara signifikan.

**Solusi**: Menambahkan `cacheWidth` pada semua `Image.file()` agar Flutter mendecode gambar pada resolusi yang lebih kecil, serta menambahkan `frameBuilder` untuk animasi fade-in yang smooth saat gambar sedang loading.

- `lib/features/task/widgets/image_picker_widget.dart` — Menambahkan `cacheWidth: 600` dan `frameBuilder` dengan `AnimatedSwitcher` (200ms fade-in) pada preview foto di form tugas.
- `lib/features/task/screens/task_detail_screen.dart`:
  - `_FotoSection` (preview 240px): `cacheWidth: 800` + `frameBuilder` dengan `CircularProgressIndicator`.
  - `_FullScreenPhoto` (InteractiveViewer): `cacheWidth: 1200` untuk full screen tanpa oversize.

### 🟢 Prioritas 6: Cleanup Debug Logging
Sebelumnya, `notification_service.dart` berisi **40+ baris `debugPrint()`** yang selalu dieksekusi saat menjadwalkan atau membatalkan notifikasi. Meskipun `debugPrint` hanya muncul di debug mode, overhead dari string interpolation dan list iteration tetap terjadi.

**Solusi**: Menambahkan flag `static const bool _verbose = false;` dan membungkus seluruh blok `debugPrint()` dengan `if (_verbose)`. Saat debugging notifikasi, cukup set `_verbose = true` untuk menyalakan kembali log.

- `lib/core/services/notification_service.dart` — Seluruh ~40 baris `debugPrint()` kini terbungkus di balik flag `_verbose`. Method `_logPendingNotifications()` tidak lagi dipanggil di production path.

### 🟢 Prioritas 7: Optimasi Minor Lainnya

#### 7a. `UnmodifiableListView` (Semua Provider)
Sebelumnya, getter `courses`, `all`, dan sejenisnya menggunakan `List.unmodifiable()` yang membuat **copy baru** list setiap kali dipanggil. Diganti dengan `UnmodifiableListView` dari `dart:collection` yang hanya membungkus (wrap) tanpa menyalin.

- `lib/features/course/providers/course_provider.dart` — `courses` getter menggunakan `UnmodifiableListView`.
- `lib/features/task/providers/task_provider.dart` — `all` getter menggunakan `UnmodifiableListView`.
- `lib/features/exam/providers/exam_provider.dart` — `all` getter menggunakan `UnmodifiableListView`.
- `lib/features/schedule/providers/schedule_provider.dart` — `all` getter menggunakan `UnmodifiableListView`.

#### 7b. Cache `pending` di TaskProvider
Sebelumnya, getter `pending` melakukan **filter + sort + alokasi list baru** setiap kali diakses. Di Dashboard, `pending` dan `pendingCount` bisa dipanggil berkali-kali per build cycle.

- `lib/features/task/providers/task_provider.dart` — Menambahkan `_pendingCache` yang diinvalidasi saat `load()` dipanggil. Getter `pending` hanya menghitung ulang jika cache kosong.

#### 7c. Fix `upcoming` Bypass di ExamProvider
Sebelumnya, getter `upcoming` langsung memanggil `_repo.getUpcoming()` yang bypass cache provider dan decode ulang dari SharedPreferences setiap kali dipanggil.

- `lib/features/exam/providers/exam_provider.dart` — Getter `upcoming` kini menghitung dari `_exams` yang sudah di-cache di memory, bukan dari repository langsung.

### 🟢 Prioritas 8: Validasi Backup & Rollback (Hotfix)
Sebelumnya, jika pengguna melakukan import file `.json` yang rusak atau bukan dari aplikasi ini, data lama akan langsung tertimpa (hilang), dan UI akan menampilkan layar kosong (grey screen) karena gagal melakukan *parsing*.

**Solusi**: Menerapkan mekanisme validasi dan *rollback*.
- `lib/core/services/backup_service.dart` — Sebelum menulis data secara permanen, sistem akan mengambil *snapshot* data lama. Setelah mengimpor JSON baru, sistem mencoba memparsing data tersebut. Jika `FormatException` atau `TypeError` terjadi (format rusak), sistem otomatis melakukan **rollback** ke snapshot lama.
- `lib/core/services/local_storage_service.dart` — Menambahkan `try-catch` di metode `readList` agar dapat mengembalikan list kosong daripada melempar exception fatal jika data tak dikenal terdeteksi.
- `lib/features/settings/setting_screen.dart` — Memberikan respon `SnackBar` berwarna merah yang deskriptif jika format file backup tidak valid.

### Daftar Semua File yang Diubah
| File | Jenis Perubahan |
|---|---|
| `lib/features/course/repositories/course_repository.dart` | In-memory cache + O(1) byId |
| `lib/features/task/repositories/task_repository.dart` | In-memory cache + invalidation |
| `lib/features/schedule/repositories/schedule_repository.dart` | In-memory cache + invalidation |
| `lib/features/exam/repositories/exam_repository.dart` | In-memory cache + invalidation |
| `lib/shared/widgets/lazy_indexed_stack.dart` | **File baru** — LazyIndexedStack widget |
| `lib/app/app.dart` | IndexedStack → LazyIndexedStack |
| `lib/features/dashboard/screens/dashboard_screen.dart` | Selector untuk userName |
| `lib/main.dart` | Disable Google Fonts runtime fetch |
| `lib/features/task/widgets/image_picker_widget.dart` | cacheWidth + frameBuilder |
| `lib/features/task/screens/task_detail_screen.dart` | cacheWidth + frameBuilder |
| `lib/core/services/notification_service.dart` | Verbose flag untuk debug log |
| `lib/features/course/providers/course_provider.dart` | UnmodifiableListView |
| `lib/features/task/providers/task_provider.dart` | UnmodifiableListView + pending cache |
| `lib/features/exam/providers/exam_provider.dart` | UnmodifiableListView + fix upcoming |
| `lib/features/schedule/providers/schedule_provider.dart` | UnmodifiableListView |
| `pubspec.yaml` | Version bump → 3.1.0+4 |
| `lib/core/services/local_storage_service.dart` | Robust `readList` dengan `try-catch` |
| `lib/features/settings/setting_screen.dart` | Version label 3.1.0 & SnackBar error handling untuk file rusak |
| `lib/core/services/backup_service.dart` | _appVersion 3.1.0 & Logika validasi JSON beserta otomatisasi rollback |

### Pembaruan Sistem
- **Update Versi Aplikasi**: Versi aplikasi telah diperbarui ke `3.1.0` (`pubspec.yaml` → `3.1.0+4`, Settings → `3.1.0`, Backup metadata → `3.1.0`).
- **Tidak ada perubahan dependency**: Tidak ada package baru yang ditambahkan atau dihapus.

## Version 3.0.1 (Backup Format)
### Perbaikan
- **Format Backup Lebih Rapi**: File backup `.json` kini menggunakan struktur JSON yang proper dan mudah dibaca (pretty-printed). Data tidak lagi tersimpan sebagai *double-encoded string*.
- **Metadata Backup**: Setiap file backup kini menyertakan informasi `version`, `appVersion`, dan `exportedAt` untuk memudahkan identifikasi.
- **Struktur Terorganisir**: Data aplikasi (`courses`, `schedules`, `tasks`, `exams`) dan pengaturan (`userName`, `themeMode`, `useSystemTheme`) kini dipisah dalam section `data` dan `settings`.
- **Nama File Bertanggal**: File backup otomatis diberi nama dengan tanggal ekspor, contoh: `studyflow_backup_2026-05-14.json`.
- **Backward Compatible**: Import tetap mendukung file backup format lama (versi sebelumnya) secara otomatis.

### File yang Diubah
- `lib/core/services/backup_service.dart` — Restrukturisasi output backup dengan metadata dan pretty-print.
- `lib/core/services/local_storage_service.dart` — `exportData()` menghasilkan JSON proper, `importData()` mendukung 3 format (structured baru, decoded, dan legacy lama).

## Version 3.0.0 (UI Revamp)
### Fitur Baru & Perubahan Visual
- **Desain UI Modern (Glassmorphism)**: Merombak seluruh tampilan aplikasi menjadi lebih modern, vibran, dan premium. Menggunakan `GoogleFonts.outfitTextTheme` untuk tipografi yang lebih bersih.
- **Floating Bottom Navigation**: Mengganti Navigation Bar bawaan menjadi *floating rounded navigation* dengan efek *shadow*.
- **Dashboard Interaktif**: Dashboard utama kini menggunakan gradasi warna dinamis pada `StatCard`, Header, `TodayScheduleWidget`, dan `TaskProgressWidget`.
- **Card Lists**: Memperbarui tampilan daftar Mata Kuliah, Tugas, Jadwal, dan Ujian dengan *container* modern, *rounded corners*, dan *soft shadow*.
- **Pembaruan Ikon & Warna**: Tema Light dan Dark kini lebih konsisten dengan palet Indigo (`0xFF4F46E5`) yang memberikan nuansa profesional dan segar.

### Pembaruan Sistem
- **Update Versi Aplikasi**: Versi aplikasi telah diperbarui ke `3.0.0`.
- **Integrasi Library**: Menambahkan package `google_fonts: ^8.1.0`.

## Version 2.2.0
### Fitur Baru
- **Kalkulator IPK**: Menambahkan fitur "Kalkulator IPK" yang terintegrasi di halaman Mata Kuliah. Pengguna dapat mencatat nilai akhir (A/B/C/D/E) untuk setiap mata kuliah yang selesai, dan mensimulasikan target IPK.
- **Home Screen Widget**: Menambahkan Widget "Jadwal Hari Ini" di layar utama Android. Pengguna dapat melihat jadwal mata kuliah tanpa membuka aplikasi.
- **Backup & Restore**: Menambahkan fitur Eksport (Backup) dan Import (Restore) data di halaman Pengaturan. Pengguna dapat mengekspor jadwal dan tugas ke file `.json`.

### Pembaruan Sistem
- **Update Versi Aplikasi**: Versi aplikasi telah diperbarui ke `2.2.0`.
- **Integrasi Library**: Menambahkan package `home_widget`, `file_picker`, dan `share_plus`.

## Version 2.1.0

### Fitur Baru
- **Multi-Selection untuk Tugas Selesai**: Menambahkan fitur "Pilih Semua" (Select All) dan "Hapus Semua" (Delete All) pada daftar tugas yang sudah selesai dikerjakan (`TaskScreen`). Pengguna kini dapat memilih beberapa tugas sekaligus dan menghapusnya secara bersamaan untuk memudahkan pembersihan data.
- **Provider Dukungan**: Menambahkan method `deleteMultiple` pada `TaskProvider` untuk menghapus kumpulan tugas secara efisien sekaligus membersihkan notifikasi yang terkait.

### Pembaruan Sistem
- **Update Versi Aplikasi**: Versi aplikasi telah diperbarui ke `2.1.0` baik di konfigurasi `pubspec.yaml` (menjadi `2.1.0+2`) maupun pada tampilan di halaman Settings.
