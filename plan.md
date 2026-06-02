# Master Plan: AI Auto-Extract Jadwal Kuliah (Fitur Ekstraksi KRS)

Fitur ini bertujuan untuk mengotomatisasi pengisian data Mata Kuliah dan Jadwal dengan cara memindai gambar (screenshot/foto) dari Kartu Rencana Studi (KRS) atau SIAKAD menggunakan AI.

Mengingat faktor UX dan keterbatasan pengguna awam, pengguna **TIDAK AKAN** diminta untuk memasukkan API Key. Kunci akses akan ditanam secara aman di dalam aplikasi.

Berikut adalah dua opsi arsitektur yang dapat Anda diskusikan dengan tim:

## Opsi A: Jalur "Generative AI" (Google Gemini 1.5 Flash)
Menggunakan AI multimodal berbasis Cloud yang sangat cerdas dalam memahami konteks dan tabel acak.

### 1. Arsitektur Alur Kerja
- **Input**: User mengunggah gambar KRS melalui Galeri/Kamera.
- **Proses**: Aplikasi mengompresi gambar (agar hemat kuota) dan mengirimkannya ke endpoint Google Gemini API melalui HTTP *request*. Prompt yang disematkan secara tersembunyi akan memerintahkan Gemini untuk merespons dengan format JSON yang sangat kaku.
- **Output**: JSON yang berisi *Array of Courses* (Nama Matkul, Dosen, Hari, Jam, Ruang).
- **Finalisasi**: Aplikasi me-*looping* JSON tersebut dan melakukan *insert* ke SQLite secara massal (`insertBatch`).

### 2. Pro & Kontra
| Kelebihan | Kekurangan |
|-----------|------------|
| Sangat cerdas. Bisa membaca tabel miring, tulisan kepotong, atau format aneh dengan akurasi 99%. | **Membutuhkan koneksi internet.** |
| Tidak perlu membuat algoritma *parsing* teks yang rumit. AI langsung mengembalikan JSON siap pakai. | Terdapat limitasi kuota harian dari Google (Free Tier). Jika aplikasi viral, kunci API gratis bisa *limit*. |

### 3. Kebutuhan Teknis
- Library: `google_generative_ai` atau sekadar `http` standar.
- API Key: Developer membuat 1 API Key gratis di Google AI Studio dan di-*hardcode* atau diambil via *environment variables*.

---

## Opsi B: Jalur "On-Device AI" (Google ML Kit - Text Recognition)
Menggunakan *Machine Learning* yang tertanam langsung di dalam aplikasi untuk membaca huruf (*Optical Character Recognition*).

### 1. Arsitektur Alur Kerja
- **Input**: User mengunggah gambar KRS melalui Galeri/Kamera.
- **Proses**: Library ML Kit memindai gambar secara *offline* di dalam HP. ML Kit mengembalikan sebuah paragraf besar (kumpulan kata dan angka yang terdeteksi dari gambar).
- **Heuristic Parsing**: Aplikasi harus mengeksekusi algoritma *Regex* (*Regular Expression*) buatan kita sendiri. Misalnya: mencari kata yang polanya `(07:00 - 09:30)` untuk mengidentifikasi Jam, mencari kata `Senin\|Selasa` untuk mengidentifikasi Hari.
- **Finalisasi**: Memasukkan hasil susunan ke SQLite.

### 2. Pro & Kontra
| Kelebihan | Kekurangan |
|-----------|------------|
| **100% Offline & Gratis selamanya.** Tidak butuh internet dan tidak akan pernah terkena limit kuota. | Kurang pintar. Jika format tabel SIAKAD dari kampus A berbeda dengan kampus B, algoritma *parsing* bisa gagal mendeteksi. |
| Privasi tingkat tinggi karena foto jadwal tidak pernah keluar dari memori HP. | Beban kerja *developer* sangat berat karena harus terus merevisi algoritma Regex agar cocok untuk semua format kampus. |

### 3. Kebutuhan Teknis
- Library: `google_mlkit_text_recognition`.
- Ukuran Aplikasi (APK) akan sedikit membengkak (~5MB - 10MB) karena harus mengemas model *Machine Learning* ke dalam aplikasi.

---

## Kesimpulan & Keputusan (Diskusi Tim)

Silakan diskusikan dengan tim, dengan dua pertanyaan panduan ini:
1. Apakah target audiens kita mau menggunakan kuota internet sesaat untuk mendapatkan fitur instan ini? (Jika ya, pilih **Opsi A**).
2. Apakah kita ingin menghindari risiko sistem lumpuh jika aplikasi mendadak di-download puluhan ribu mahasiswa dan API Key terkena limit? (Jika ya, pilih **Opsi B**).

Jika sudah ada keputusan final dari hasil diskusi, informasikan opsi mana yang akan kita bangun, dan saya akan bersiap mengeksekusi kodenya!
