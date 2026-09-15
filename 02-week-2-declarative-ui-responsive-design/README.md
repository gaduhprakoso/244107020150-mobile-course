# Laporan Praktkum Minggu 02 | Declarative UI & Responsive Design

- **Nama**: Gaduh Prakoso
- **NIM**: 2341720000

---


## 1. Langkah Praktikum: Layout Sederhana (Warm-up)

### 1.1
Hapus Expanded pada baris nama, lalu amati peringatan overflow atau perilaku layout-nya; kembalikan setelah itu.

![](screenshots\Screenshot-01.png)

### 1.2
Ganti mainAxisSize: MainAxisSize.min menjadi nilai default dan amati perubahan tinggi kartu.

![](screenshots\Screenshot-10.png)

### 1.3
Tambahkan satu baris data (misal Email) menggunakan pola Row + Expanded yang sama.

![](screenshots\Screenshot-09.png)

---

## 2. Langkah Praktikum: Dashboard Responsif

### 2.1.
Ubah breakpoint dari 700 menjadi nilai lain dan amati perubahan jumlah kolom.

![](screenshots\Screenshot-05.png)

### 2.2.
Ubah themeMode menjadi ThemeMode.dark, lalu kembalikan ke ThemeMode.system.

![](screenshots\Screenshot-04.png)
![](screenshots\Screenshot-05.png)

### 2.3
Tambahkan Semantics atau label yang bermakna pada elemen yang penting bagi screen reader.

![](screenshots\Screenshot-05.png)

---

## 3. Tugas Utama (Academic Overview)

Dashboard dikembangkan menjadi halaman *Academic Overview* yang memuat:
1. **Header Profil Mahasiswa**: Menggunakan `Container`, `Row`, `Column`, `Expanded`, dan `CircleAvatar`.
2. **Statistik Akademik**: 4 kartu informasi (`InfoCard`) mencakup **IPK (3.85)**, **Kehadiran (95%)**, **SKS Ditempuh (72)**, dan **Status (Aktif)**.
3. **Breakpoint Konstanta**: Menggunakan satu konstanta global `const double kWideBreakpoint = 700;`.

![](screenshots\Screenshot-06.png)

---

## 4. AI Prompt Challenge

### 4.1. Prompt Desain
> *"Bandingkan dua tata letak dashboard akademik untuk Flutter: versi GridView dan versi LayoutBuilder + Column. Jelaskan trade-off responsif dan aksesibilitasnya."*

* **Versi GridView:**
  * **Responsif:** Efisien untuk ubin seragam, namun kaku pada perubahan layar ekstrem tanpa penyesuaian rasio aspek.
  * **Aksesibilitas:** Urutan fokus *screen reader* bisa kurang linear jika struktur grid tidak diatur eksplisit.
* **Versi LayoutBuilder + Column:**
  * **Responsif:** Sangat fleksibel untuk adaptasi vertikal, tetapi butuh tambahan logika (seperti `Wrap`) untuk menyusun item secara horizontal.
  * **Aksesibilitas:** Urutan baca elemen lebih natural dan mudah diprediksi mengikuti alur vertikal.
* **Kesimpulan Trade-off:** `GridView` unggul pada kerapian visual berbasis ubin, sementara `LayoutBuilder + Column` lebih baik dalam adaptasi konten dinamis dan aksesibilitas dasar.

---

### 4.2. Prompt Penguatan Konsep
> *"Jelaskan kapan penggunaan Expanded justru menyebabkan overflow di dalam Row, beri contoh kode yang gagal dan perbaikannya."*

* **Penyebab:** `Expanded` memaksa anak widget mengisi sisa ruang. Jika diletakkan di dalam container yang lebarnya tak terbatas atau bersarang tanpa pembatas yang jelas, Flutter gagal menghitung ukuran dan memicu *overflow*.
* **Contoh Kode Gagal:**
  ```dart
  Row(
    children: [
      Text("Teks judul yang sangat panjang sekali..."),
      Expanded(child: Text("Badge")), // Bisa memicu overflow jika Row tak terbatas
    ],
  )

* **Contoh Kode perbaikan:**
  ```dart
  Row(
  children: [
    Expanded(child: Text("Teks judul yang sangat panjang sekali...")),
    Text("Badge"),
  ],
)

### 4.2. Prompt penguatan konsep.
> *"Periksa kembali rekomendasi layout di atas: apakah tetap responsif di bawah 600px, apakah mengurangi aksesibilitas, dan apakah ada widget yang tidak tersedia di Flutter stabil saat ini?"*

* Responsivitas (<600px): Ya, layout tetap responsif selama menggunakan penyesuaian breakpoint (misal via LayoutBuilder) untuk mengubah susunan horizontal menjadi vertikal pada layar sempit.

* Aksesibilitas: Tidak mengurangi aksesibilitas, dengan catatan ukuran target sentuh memenuhi standar minimum (48x48 dp) dan kontras warna teks memadai.

* Ketersediaan Widget: Tidak ada. Seluruh widget (GridView, LayoutBuilder, Column, Row, Expanded) merupakan komponen standar yang tersedia di kanal stabil (stable channel) Flutter saat ini.

---

## 5. Refleksi

## 5.1 Apa perbedaan cara berpikir imperative dan declarative saat membangun UI?
Pendekatan imperatif menuntut kita menuliskan instruksi secara bertahap untuk memodifikasi elemen UI secara manual, berlawanan dengan deklaratif yang memusatkan perhatian pada wujud akhir antarmuka berdasarkan kondisi data terkini. Di dalam ekosistem Flutter, gaya deklaratif jauh lebih ideal karena sistem akan otomatis merender ulang komponen-komponen layar setiap kali terjadi pergeseran nilai state maupun ukuran tampilan.

## 5.2 Kapan Expanded membantu dan kapan penggunaannya justru menghasilkan layout error?
Widget `Expanded` sangat diandalkan saat kita ingin memaksa komponen anak memenuhi rongga kosong yang tersisa di dalam wadah `Row` atau `Column`, namun keliru jika diterapkan pada kontainer induk yang tidak memiliki batas ukuran pasti (*unbounded width/height*) sehingga memicu kendala *overflow*. Untuk mengatasinya, kita bisa beralih menggunakan `Flexible`, memangkas teks dengan parameter *overflow*, atau menyesuaikan ulang tata letak ketika menyentuh ukuran *breakpoint* tertentu.

## 5.3 Bagaimana breakpoint dan theme memengaruhi pengalaman pengguna?
Keberadaan *breakpoint* dan tema visual memegang peranan vital dalam mendongkrak kenyamanan interaksi pengguna secara keseluruhan. *Breakpoint* berfungsi menentukan titik transisi pergeseran struktur layout—misalnya dari tampilan tunggal menjadi multi-kolom—sementara tema memastikan estetika, tingkat keterbacaan teks, serta keselarasan mode gelap dan terang tetap terjaga secara optimal di berbagai situasi.

## 5.4 Apa yang Anda verifikasi dari rekomendasi AI setelah tugas inti selesai?
Pemeriksaan ulang terhadap saran AI dijalankan untuk memastikan aspek fungsionalitas terpenuhi dengan baik: mulai dari konsistensi tingkat responsivitas pada layar di bawah 600px, perlindungan standar aksesibilitas, hingga validasi kestabilan seluruh widget di kanal rilis resmi Flutter.

---