# Hasil grep verifikasi

Hasil berikut berasal dari pemeriksaan kode pada 12 Oktober 2026, dari folder
`campus_notify`. Tiga kelompok pengecekan disertai perintah yang digunakan dan
hasilnya.

Di PowerShell jangan menulis wildcard directory Bash seperti
`lib/features/*/presentation`. Berikan direktori ke ripgrep dan gunakan `-g`
untuk memilih file.

## 1. Presentation steril dari akses data mentah

Perintah:

```powershell
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features -g "**/presentation/**/*.dart"
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/pages
```

Hasil: **tidak ada kecocokan** (`rg` exit code `1`). Tidak ditemukan akses
langsung ke Dio/database/secure storage/JSON dalam presentation atau halaman
lama. Halaman tetap membaca state provider dan melakukan interaksi UI, yang
memang tanggung jawab presentation.

## 2. Domain dan core bebas import framework/infrastruktur

Perintah:

```powershell
rg "import 'package:(flutter|dio|sqflite|firebase)" lib/features -g "**/domain/**/*.dart"
rg "import 'package:(flutter|dio|sqflite|firebase)" lib/core
```

Hasil: **tidak ada kecocokan** (`rg` exit code `1` pada kedua perintah).
Domain Notes dan core tidak mengimpor package Flutter, Dio, sqflite, atau
Firebase.

## 3. Tidak ada konstruksi repository/client di presentation

Perintah:

```powershell
rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
rg "Repository\(|Dio\(BaseOptions" lib/features -g "**/presentation/**/*.dart"
```

Hasil: **tidak ada kecocokan** (`rg` exit code `1` pada kedua perintah).
Konstruktor `AuthRepository()` berada di provider data lama, bukan halaman
atau widget. `PushService` juga dibuat pada `push_provider.dart`, kemudian
diambil oleh Home melalui Riverpod. Namun provider belum terkumpul dalam satu
lokasi/konvensi fitur.

## Pemeriksaan tambahan entity/model dan daftar announcements

Mapping Notes diperiksa dengan:

```powershell
rg "toMap\(|fromMap\(|toJson\(|fromJson\(" lib/features/notes/domain/entities lib/features/notes/data/models
```

Entity: **tidak ada mapping**. Model: mapping ditemukan di
`lib/features/notes/data/models/note_model.dart`.

Pemeriksaan class/file repository mengungkap:

- `NoteRepository` adalah interface di domain.
- `NoteRepositoryImpl` adalah implementasi data.
- `AuthRepository` masih class konkret lama di `lib/data/auth_repository.dart`.
- Tidak ditemukan `AnnouncementRepository`, model, remote data source, atau
  provider daftar announcements. Halaman pengumuman yang tersedia masih
  placeholder detail.

> Catatan: hasil Auth di atas adalah baseline sebelum Refactoring Challenge.
> Auth kemudian dirapikan; hasil verifikasi pasca-refactor ada di bawah.

## Verifikasi setelah Refactoring Challenge

### Grep 1: presentation tidak mengakses data mentah

```powershell
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features -g "**/presentation/**/*.dart"
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/pages
```

Kedua pencarian menghasilkan **0 kecocokan** (`rg` exit code `1`).

### Grep 2: domain/core bebas framework dan infrastruktur

```powershell
rg "import 'package:(flutter|dio|sqflite|firebase)" lib/features -g "**/domain/**/*.dart"
rg "import 'package:(flutter|dio|sqflite|firebase)" lib/core
```

Kedua pencarian menghasilkan **0 kecocokan**, termasuk domain Auth baru.

### Grep 3: tidak ada konstruksi repository/client pada presentation

```powershell
rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
rg "Repository\(|Dio\(BaseOptions" lib/features -g "**/presentation/**/*.dart"
```

Kedua pencarian menghasilkan **0 kecocokan**. Wiring Auth berada di provider
fitur Auth dan widget tidak membuat repository atau Dio.

### Error, helper murni, dan test

- Auth notifier mengubah error login/storage ke `Failure` sebelum disimpan ke
  state; `Login` memakai `ValidationFailure` untuk input invalid.
- `apiFailureFrom` memetakan Dio dan exception lain ke Failure bermessage aman.
- Notes repository mengembalikan `LocalFailure` generik tanpa detail mentah
  database; provider meneruskan Failure ke state.
- UI menggunakan Failure message atau fallback generik.
- `formatDate` dan `routeFromMessage` berada di `lib/core/format.dart` dan
  diuji tanpa widget.
- `test/get_notes_test.dart` menguji hasil dan failure dengan repository palsu,
  tanpa SQLite/Dio/Firebase.

Validasi terbaru:

```text
flutter analyze
No issues found!

flutter test
All tests passed! (19 tests)
```
