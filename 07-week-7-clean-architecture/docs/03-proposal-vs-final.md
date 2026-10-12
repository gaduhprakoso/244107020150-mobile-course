# Usulan AI vs keputusan final

Refactoring Challenge diterapkan setelah audit awal 12 Oktober 2026. Status ini
mencerminkan kode setelah perubahan, bukan hanya usulan.

| Topik | Usulan awal AI | Status kode kini | Keputusan final dan alasan |
|---|---|---|---|
| Repository Auth | Interface di domain, implementasi di data. | Selesai: kontrak di `features/auth/domain/repositories/auth_repository.dart`, implementasi mock di `features/auth/data/repositories/auth_repository_impl.dart`. | Pertahankan pemisahan. Use case dan API client bergantung pada domain interface; impl mock dapat kelak diganti backend tanpa UI tergantung Dio. |
| Repository Notes | Kontrak domain dan implementasi data. | Selesai sebelumnya: `NoteRepository` dan `NoteRepositoryImpl` sudah terpisah. | Pertahankan pola ini untuk fitur yang memiliki data source nyata. |
| Use case | Tidak perlu wrapper satu baris untuk semua operasi CRUD. | `Login` diterapkan dan berisi validasi input. `GetNotes` dan `AddNote` masih meneruskan operasi repository. | `Login` dipertahankan karena memuat aturan validasi. Wrapper Notes satu-baris tidak wajib; hapus saat menyederhanakan CRUD atau pertahankan hanya untuk tujuan praktikum. |
| Entity dan mapping | Entity murni; mapping di model. | `AuthSession` dan `Note` tidak memiliki mapping. Mapping SQLite `toMap/fromMap` tetap pada `NoteModel`. | Pertahankan batas tersebut agar format penyimpanan/API tidak bocor ke domain. |
| DI | Riverpod sebagai composition root tanpa package tambahan; widget tidak membuat repository. | Auth dependency wiring berada di `features/auth/presentation/providers/auth_providers.dart`; Notes di provider Notes. Halaman tidak membuat repository atau Dio. | Pertahankan Riverpod dan provider per fitur. Ini memberi seam untuk override test tanpa framework DI lain. |
| Formatting/routing | Fungsi murni bisa diuji tanpa widget. | `formatDate` dan `routeFromMessage` berada di `lib/core/format.dart`; fungsi routing menerima konstanta sebagai parameter supaya core tidak mengimpor router. | Pertahankan helper Dart murni dan test unit. Format tanggal sekarang `dd/MM/yyyy`. |
| Failure | Exception mentah tidak boleh tampil di UI. | Auth mengubah error menjadi `Failure` pada notifier/API mapper; Notes repository mengembalikan `LocalFailure`; halaman menampilkan `.message` atau fallback generik. | Pesan UI aman tidak membocorkan exception/storage detail. Simpan detail teknis untuk logging bila diperlukan, bukan untuk teks UI. |
| Announcements | Feature-first domain/data/presentation bila kontrak API tersedia. | Masih hanya halaman detail placeholder; daftar/API repository belum ada. | Tunda implementasi network sampai kontrak endpoint/response jelas. GET CRUD sederhana tidak perlu use case pass-through. |

## Keputusan teknis

1. Auth kini memakai entity, repository interface, repository implementation,
   satu use case `Login`, serta wiring Riverpod.
2. Notes tetap memisahkan interface dan implementasi. Use case CRUD satu-baris
   tidak diwajibkan.
3. `core/format.dart` berisi formatter tanggal dan parser route murni.
4. Semua error yang ditampilkan melalui alur Auth, Notes, Home, dan app router
   dipetakan menjadi Failure/pesan aman.
5. API announcements ditunda; tidak membuat model/data source spekulatif.
6. Hasil grep, analyzer, dan test dicatat di
   [04-grep-verification.md](04-grep-verification.md).
