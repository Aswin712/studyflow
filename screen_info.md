# Informasi Screen Aplikasi StudyFlow

Dokumen ini berisi daftar semua layar (screen) yang ada di aplikasi StudyFlow beserta elemen-elemen UI utama yang ada di dalamnya. Informasi ini berguna sebagai referensi untuk melakukan redesain antarmuka aplikasi.

## 1. Dashboard Screen (`dashboard_screen.dart`)
- **Header**: Sapaan (Selamat pagi/siang/malam), Nama User, Tanggal Hari Ini, dan Avatar User (mengarah ke Settings).
- **Statistik Row**: 4 kartu statistik utama (Total SKS, Tugas Pending, Ujian Mendatang, Jadwal Hari Ini).
- **Jadwal Hari Ini (Section)**: Menampilkan widget daftar kuliah untuk hari ini.
- **Progress Tugas (Section)**: Menampilkan widget persentase atau daftar ringkas tugas.
- **Ujian Mendatang (Section)**: Menampilkan widget daftar ujian yang akan datang.

## 2. Mata Kuliah (Course)
### a. Course Screen (`course_screen.dart`)
- **AppBar**: Judul "Mata Kuliah" dan Chip berisi total SKS.
- **Daftar Mata Kuliah**: Menampilkan list kartu mata kuliah. Setiap kartu memuat: Inisial/Avatar warna, Nama Mata Kuliah, Jumlah SKS, Nama Dosen, dan Tombol Hapus.
- **Empty State**: Menampilkan ikon dan teks ajakan jika belum ada mata kuliah.
- **FAB**: Tombol "Tambah" untuk menambah mata kuliah baru.

### b. Course Form Screen (`course_form_screen.dart`)
- Form untuk menambah atau mengedit informasi mata kuliah (Nama, SKS, Dosen, Pilihan Warna, dll).

## 3. Tugas (Task)
### a. Task Screen (`task_screen.dart`)
- **AppBar**: Judul "Tugas" dan Tombol *Toggle Visibility* untuk menyembunyikan/menampilkan tugas yang sudah selesai.
- **Daftar Tugas**: List kartu tugas. Setiap kartu memiliki: Checkbox selesai, Judul Tugas, Indikator Mata Kuliah, Indikator Waktu/Deadline, Status Prioritas, dan Tombol Hapus (jika sudah selesai).
- **Empty State**: Tampilan jika tidak ada tugas.
- **FAB**: Tombol "Tambah" untuk membuat tugas baru.

### b. Task Form Screen (`task_form_screen.dart`)
- Form untuk membuat atau mengedit tugas (Judul, Mata Kuliah, Tenggat Waktu, Prioritas, Deskripsi, dll).

### c. Task Detail Screen (`task_detail_screen.dart`)
- Halaman untuk melihat detail lengkap dari suatu tugas (termasuk deskripsi panjang atau gambar jika ada).

## 4. Jadwal Kuliah (Schedule)
### a. Schedule Screen (`schedule_screen.dart`)
- **AppBar**: Judul "Jadwal Kuliah".
- **Day Selector**: Deretan *Choice Chips* (Senin - Minggu) untuk memilih hari secara horizontal.
- **Daftar Jadwal**: List kartu jadwal pada hari yang dipilih. Tiap kartu memuat: Garis warna mata kuliah, Nama Mata Kuliah, Ruangan, Waktu Mulai, dan Waktu Selesai.
- **Empty State**: Tampilan "Tidak ada kuliah" jika hari tersebut kosong.
- **FAB**: Tombol "Tambah" untuk jadwal baru.

### b. Schedule Form Screen (`schedule_form_screen.dart`)
- Form untuk menambah atau mengedit jadwal (Pilih Mata Kuliah, Hari, Jam Mulai, Jam Selesai, Ruangan).

## 5. Ujian (Exam)
### a. Exam Screen (`exam_screen.dart`)
- **AppBar**: Judul "Ujian".
- **Daftar Ujian**: List kartu ujian mendatang. Tiap kartu memiliki: Bubble Countdown Tanggal/Bulan (merah jika dekat), Judul Ujian (UTS/UAS/Kuis), Nama Mata Kuliah, Jam & Ruangan, serta Teks Sisa Hari.
- **Empty State**: Tampilan jika tidak ada ujian.
- **FAB**: Tombol "Tambah" untuk jadwal ujian baru.

### b. Exam Form Screen (`exam_form_screen.dart`)
- Form untuk membuat atau mengedit informasi ujian (Pilih Mata Kuliah, Judul, Tanggal, Jam, Ruangan).

## 6. Pengaturan (Settings)
### a. Settings Screen (`setting_screen.dart`)
- **Profil (Section)**: Card untuk melihat dan mengedit nama pengguna langsung (TextField inline).
- **Tampilan (Section)**: Pengaturan mode tema aplikasi dengan 3 opsi (Ikuti Sistem, Terang, Gelap).
- **Tentang (Section)**: Card informasi detail aplikasi (Versi Aplikasi, Nama Aplikasi "StudyFlow", Deskripsi).

## Prompt : 
- Tolong bantu saya meredesain UI/UX aplikasi Flutter saya yang bernama StudyFlow.

- Saya memiliki file `screen_info.md` (atau baca konteks terlampir) yang berisi rincian semua screen dan elemen UI yang ada di aplikasi saat ini. Gunakan informasi dalam dokumen tersebut sebagai panduan utama agar kamu mengetahui fitur, struktur, dan informasi apa saja yang wajib dipertahankan di setiap halamannya.

- Berikut adalah tema visual dan panduan desain utama yang saya inginkan:
[ ISI TEMA DAN GAYA DESAIN KAMU DI SINI ]

- Mohon berikan saya kode implementasi Flutter terbaru untuk screen-screen tersebut dengan desain yang sudah disesuaikan dengan tema di atas. Pastikan kode desain yang baru tetap mempertahankan semua struktur dan fungsionalitas (seperti tombol FAB, empty state, list data) sesuai yang tercatat di `screen_info.md`.
