# Laporan Praktkum Minggu 02 | Declarative UI & Responsive Design

- **Nama**: Gaduh Prakoso
- **NIM**: 2341720000

---


## 1. Langkah Praktikum: Layout Sederhana (Warm-up)

### 1.1
Hapus Expanded pada baris nama, lalu amati peringatan overflow atau perilaku layout-nya; kembalikan setelah itu.

![screenshots](screenshots/screenshots-01.png)

### 1.2
Ganti mainAxisSize: MainAxisSize.min menjadi nilai default dan amati perubahan tinggi kartu.

![screenshots](screenshots/screenshots-10.png)

### 1.3
Tambahkan satu baris data (misal Email) menggunakan pola Row + Expanded yang sama.

![screenshots](screenshots/screenshots-09.png)

---

## 2. Langkah Praktikum: Dashboard Responsif

### 2.1.
Ubah breakpoint dari 700 menjadi nilai lain dan amati perubahan jumlah kolom.

![screenshots](screenshots/screenshots-05.png)

### 2.2.
Ubah themeMode menjadi ThemeMode.dark, lalu kembalikan ke ThemeMode.system.

![screenshots](screenshots/screenshots-04.png)
![screenshots](screenshots/screenshots-05.png)

### 2.3
Tambahkan Semantics atau label yang bermakna pada elemen yang penting bagi screen reader.

![screenshots](screenshots/screenshots-05.png)

---

## 3. Tugas Utama (Academic Overview)

Dashboard dikembangkan menjadi halaman *Academic Overview* yang memuat:
1. **Header Profil Mahasiswa**: Menggunakan `Container`, `Row`, `Column`, `Expanded`, dan `CircleAvatar`.
2. **Statistik Akademik**: 4 kartu informasi (`InfoCard`) mencakup **IPK (3.85)**, **Kehadiran (95%)**, **SKS Ditempuh (72)**, dan **Status (Aktif)**.
3. **Breakpoint Konstanta**: Menggunakan satu konstanta global `const double kWideBreakpoint = 700;`.

![screenshots](screenshots/screenshots-06.png)

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

1. **Imperative vs Declarative**: Flutter menggunakan pendekatan deklaratif di mana UI dirender ulang secara otomatis berdasarkan perubahan *state* dan ukuran layar.
2. **Penggunaan `Expanded`**: Sangat membantu untuk mengisi sisa ruang secara proporsional dalam `Row`/`Column`, namun dapat memicu error *overflow* jika digunakan di dalam parent tanpa batasan ukuran yang jelas.
3. **Pengaruh Breakpoint & Theme**: Membantu meningkatkan pengalaman pengguna (*UX*) secara signifikan melalui adaptasi tata letak layar dan kenyamanan kontras visual.

---