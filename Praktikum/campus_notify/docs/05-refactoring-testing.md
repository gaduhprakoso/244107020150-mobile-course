# Refactoring Challenge dan testing

## Auth feature-first

```text
lib/features/auth/
├── domain/
│   ├── entities/auth_session.dart
│   ├── repositories/auth_repository.dart
│   └── usecases/login.dart
├── data/
│   └── repositories/auth_repository_impl.dart
└── presentation/
    └── providers/auth_providers.dart
```

- `AuthSession` adalah entity domain murni.
- `AuthRepository` merupakan interface domain; `AuthRepositoryImpl` adalah
  implementasi mock pada layer data.
- Use case `Login` memvalidasi email/password sebelum memanggil repository.
- Riverpod merangkai repository, use case, token store, notifier, dan API
  client. Tidak ada package DI tambahan.
- API client bergantung pada interface Auth untuk operasi refresh token.

## Pure functions

`lib/core/format.dart` menampung helper Dart murni:

- `formatDate(DateTime)` menghasilkan format `dd/MM/yyyy`.
- `routeFromMessage` menormalkan dan memvalidasi route notifikasi. Nilai route
  home dan segment pengumuman diberikan sebagai parameter agar core tidak
  bergantung pada router, Flutter, atau Firebase.

`test/format_test.dart` menguji kedua fungsi tanpa widget.

## Failure sebelum UI

- `apiFailureFrom` mengubah Dio exception dan exception lain menjadi `Failure`
  dengan pesan aman bagi pengguna.
- Auth notifier mengubah error login, baca token, dan logout sebelum disimpan
  ke state.
- Notes repository mengembalikan `LocalFailure` generik; provider meneruskan
  Failure, bukan membungkusnya menjadi `Exception`.
- Login/Notes menampilkan Failure message atau fallback generik. Home dan app
  router memetakan error sebelum menampilkan Snackbar/halaman error.
- Error saat inisialisasi push dilaporkan melalui
  `FlutterError.reportError`, bukan ditampilkan sebagai teks exception.

## Fake repository tests

`test/get_notes_test.dart` menguji use case `GetNotes` dengan
`FakeNoteRepository`:

1. Daftar sukses diteruskan dari repository.
2. `LocalFailure` diteruskan tanpa throw.

Test ini tidak memakai SQLite, Dio, ataupun Firebase.
`test/login_test.dart` menguji use case Login dengan repository palsu untuk
kredensial valid dan invalid.

## Validasi

- `flutter analyze` — **No issues found**.
- `flutter test` — **All tests passed (19 tests)**.
