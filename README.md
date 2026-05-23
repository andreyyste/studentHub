# StudentHub 🎓

StudentHub adalah aplikasi manajemen produktivitas berbasis Flutter yang dirancang khusus untuk membantu mahasiswa mengorganisasi jadwal perkuliahan, manajemen tugas, dan pengarsipan materi. Aplikasi ini terintegrasi langsung dengan portal eLOK UGM untuk kemudahan pengunduhan dokumen, serta dilengkapi dengan Asisten AI cerdas berbasis *multi-model* (Google Gemini, Ollama Lokal, dan GitHub Models) untuk mendampingi proses belajar.

## ✨ Fitur Utama

- **Manajemen Jadwal Kuliah**: Pencatatan jadwal kelas, ruangan, dan waktu secara mendetail. Mendukung penandaan khusus untuk kelas pengganti atau kelas yang dibatalkan.
- **Sistem Pelacakan Tugas**: Pemantauan tenggat waktu tugas secara *real-time* yang dilengkapi dengan fitur pelampiran berkas referensi lokal (PDF).
- **Integrasi eLOK UGM**: Peramban internal (*WebView*) yang dioptimalkan untuk mengakses portal eLOK UGM. Pengguna dapat membaca dan mengunduh materi atau tugas berekstensi PDF langsung ke dalam penyimpanan luring perangkat.
- **Pustaka Materi Luring (Offline)**: Pengarsipan materi perkuliahan dalam berbagai kategori (Slide, Catatan, Latihan) yang dapat dibaca kapan saja menggunakan penampil PDF terintegrasi.
- **Asisten AI Terintegrasi**: Ruang obrolan interaktif dengan kemampuan analisis konteks (mengetahui jadwal dan tugas pengguna). Mendukung penggunaan berbagai model AI seperti Gemini (Cloud), Llama 3 (via Ollama REST API Lokal), dan model lain via GitHub Inference API.

## 🛠️ Teknologi yang Digunakan

- **Kerangka Kerja (Framework)**: [Flutter](https://flutter.dev/) (Dart)
- **Basis Data Luring**: SQLite (melalui modul `sqflite` dan `sqflite_common_ffi` untuk dukungan Desktop).
- **Integrasi AI**: `google_generative_ai` & REST API `http`.
- **Manajemen Berkas & PDF**: `syncfusion_flutter_pdfviewer`, `file_picker`, `path_provider`.
- **Peramban Web Internal**: `flutter_inappwebview`.
- **Manajemen Variabel Lingkungan**: `flutter_dotenv`.

## 📋 Prasyarat

Sebelum memulai proses instalasi, pastikan sistem Anda telah memenuhi persyaratan berikut:
1. Telah memasang [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi terbaru direkomendasikan).
2. Perangkat lunak IDE seperti Android Studio atau Visual Studio Code.
3. Kunci API yang valid:
   - **Google Gemini API Key** (Dapatkan di [Google AI Studio](https://aistudio.google.com/)).
   - **GitHub Token** (Dapatkan di Pengaturan Akun GitHub Anda untuk akses GitHub Models).
4. (Opsional) Ollama berjalan secara lokal jika Anda berencana menggunakan model Llama 3.

## 🚀 Panduan Instalasi

Ikuti langkah-langkah di bawah ini untuk menjalankan aplikasi di perangkat atau emulator Anda:

**1. Kloning Repositori**
```
git clone [https://github.com/andreyyste/studentHub.git](https://github.com/andreyyste/studentHub.git)
cd studentHub
```
2. Unduh Dependensi
Unduh seluruh pustaka (packages) yang dibutuhkan oleh proyek.
```
flutter pub get
```
3. Konfigurasi Variabel Lingkungan (.env)
Aplikasi ini memerlukan beberapa kredensial API untuk fitur Asisten AI. Buat sebuah berkas bernama .env di direktori utama (root) proyek, lalu tambahkan konfigurasi berikut:
Cuplikan kode
```
GEMINI_API_KEY=masukkan_api_key_gemini_anda_di_sini
GITHUB_TOKEN=masukkan_token_github_anda_di_sini
```
(Catatan: Berkas .env telah dimasukkan ke dalam .gitignore sehingga kunci API Anda akan tetap aman dan tidak terunggah ke repositori).

4. Jalankan Aplikasi
Pastikan emulator atau perangkat fisik Android/iOS Anda telah terhubung.
Bash
```
flutter run
```
📂 Struktur Direktori Utama
```text
lib/
├── models/                  # Struktur data (ClassSchedule, StudentTask)
├── screens/                 # Antarmuka pengguna (UI) utama
├── widgets/                 # Komponen antarmuka yang dapat digunakan kembali (Cards, Dialogs)
├── services/                # Layanan integrasi API & kueri basis data (database_helper.dart, ai_service.dart)
├── utils/                   # Fungsi utilitas pembantu (date_formatter.dart, schedule_helper.dart)
└── main.dart                # Titik masuk utama aplikasi (Entry Point)
```
💡 Cara Penggunaan

    Memantau Dasbor: Halaman utama akan langsung menyajikan kartu informasi mengenai jadwal kelas terdekat di hari tersebut dan tugas dengan tenggat waktu paling mendesak.

    Mengelola Dokumen eLOK: Buka menu Portal eLOK, masuk (login) menggunakan akun SSO UGM Anda, cari berkas PDF yang ingin diunduh. Aplikasi akan mencegat URL PDF tersebut dan memunculkan pop-up formulir untuk menyimpannya ke dalam database sebagai Materi atau Tugas.

    Menggunakan AI: Buka menu Tanya AI. Secara bawaan, AI telah diberikan konteks membaca jadwal dan tugas Anda di database. Gunakan dropdown di sudut kanan atas untuk beralih antara model Google Gemini, Ollama Lokal, atau model eksternal lainnya.
