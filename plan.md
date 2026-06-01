# Rencana Pengembangan StudyFlow: Sistem Multi-Tema

Dokumen ini merangkum rencana teknis untuk menambahkan fitur pemilihan tema warna kustom di dalam aplikasi StudyFlow, melampaui sekadar mode Terang/Gelap standar.

## 1. Konsep Utama
Pengguna dapat memilih satu dari beberapa "Preset Warna" yang akan mengubah warna primer, sekunder, dan aksen di seluruh aplikasi secara konsisten.

### Kandidat Tema Warna:
- **Indigo (Default):** Fokus & Profesional.
- **Ocean Blue:** Tenang & Elegan.
- **Emerald Green:** Alami & Segar.
- **Rose Pink:** Manis & Vibran.
- **Midnight Orange:** Kontras Tinggi & Energetik.

## 2. Perubahan Arsitektur

### Core: `AppTheme` (`lib/core/theme/app_theme.dart`)
- Mengubah struktur dari variabel statis menjadi fungsi yang menerima parameter `ThemePreset`.
- Menambahkan class `AppThemeColor` untuk memetakan warna berdasarkan ID tema.

### Provider: `SettingsProvider` (`lib/features/settings/setting_provider.dart`)
- Menambahkan properti `selectedThemeId` (String).
- Mengintegrasikan penyimpanan pilihan tema ke `SharedPreferences` agar pilihan tetap bertahan setelah aplikasi ditutup (*Persistence*).

### UI: `SettingsScreen` (`lib/features/settings/setting_screen.dart`)
- Menambahkan widget "Theme Picker" (bisa berupa barisan lingkaran warna).
- Memberikan pratinjau instan saat warna diketuk.

## 3. Langkah Implementasi
1. `[ ]` Definisikan palet warna untuk setiap preset di `AppConstants` atau file baru `theme_presets.dart`.
2. `[ ]` Perbarui `SettingsProvider` untuk mendukung penyimpanan `themeId`.
3. `[ ]` Refaktor `AppTheme.getTheme` agar bersifat dinamis berdasarkan parameter warna.
4. `[ ]` Tambahkan UI pemilihan warna di halaman Pengaturan.
5. `[ ]` Uji coba kontras warna pada setiap tema di mode Terang maupun Gelap.

---
*Rencana ini akan dijalankan pada tahap pengembangan berikutnya sesuai instruksi user.*
