# Output awal AI: usulan arsitektur

## Struktur yang diusulkan

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routing/
│       ├── app_router.dart
│       └── app_routes.dart
├── core/
│   ├── failures.dart
│   └── network/api_client.dart
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/auth_session.dart
│   │   │   ├── repositories/auth_repository.dart
│   │   │   └── usecases/login.dart
│   │   ├── data/
│   │   │   ├── datasources/auth_remote_data_source.dart
│   │   │   ├── datasources/secure_token_data_source.dart
│   │   │   └── repositories/auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── pages/login_page.dart
│   │       └── providers/auth_providers.dart
│   ├── announcements/
│   │   ├── domain/
│   │   │   ├── entities/announcement.dart
│   │   │   └── repositories/announcement_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/announcement_remote_data_source.dart
│   │   │   ├── models/announcement_model.dart
│   │   │   └── repositories/announcement_repository_impl.dart
│   │   └── presentation/
│   │       ├── pages/announcements_page.dart
│   │       ├── pages/announcement_detail_page.dart
│   │       └── providers/announcements_providers.dart
│   ├── notifications/
│   │   ├── data/services/firebase_push_service.dart
│   │   └── presentation/providers/notification_providers.dart
│   └── home/presentation/pages/home_page.dart
└── pages/app_error_page.dart
```

Notes yang telah memiliki `domain/data/presentation` dapat tetap berada di
`features/notes`; tidak perlu dipindahkan hanya untuk menyamakan nama folder
fitur lain.

## Pemetaan awal file lama

| File lama | Tujuan awal yang diusulkan |
|---|---|
| `lib/main.dart` | Tetap menjadi bootstrap Flutter/Firebase. |
| `lib/app.dart` | Pindah ke `lib/app/app.dart`; komposisi MaterialApp dan startup push. |
| `lib/routes.dart` | Pecah ke `lib/app/routing/app_routes.dart` dan `app_router.dart`. |
| `lib/core/failures.dart` | Tetap di core; tipe error Dart murni. |
| `lib/data/api_client.dart` | Pindah ke `lib/core/network/api_client.dart` karena dipakai lintas fitur. |
| `lib/data/api_errors.dart` | Pisahkan pemetaan error infrastruktur dari pesan yang ditampilkan UI. |
| `lib/data/auth_repository.dart` | Pecah menjadi kontrak `auth/domain` dan implementasi `auth/data`. |
| `lib/data/auth_repository_provider.dart` | Gabungkan/pindah ke `auth/presentation/providers/auth_providers.dart`. |
| `lib/data/token_store.dart` | Pindah ke `auth/data/datasources/secure_token_data_source.dart`. |
| `lib/providers/auth_provider.dart` | Pindah ke `auth/presentation/providers/auth_providers.dart`. |
| `lib/providers/push_provider.dart` | Pindah ke `notifications/presentation/providers/notification_providers.dart`. |
| `lib/messaging/push_services.dart` | Pindah ke `notifications/data/services/firebase_push_service.dart`. |
| `lib/pages/login_page.dart` | Pindah ke `auth/presentation/pages/login_page.dart`. |
| `lib/pages/home_page.dart` | Pindah ke `home/presentation/pages/home_page.dart`. |
| `lib/pages/announcement_page.dart` | Pindah ke `announcements/presentation/pages/announcement_detail_page.dart`. |
| `lib/pages/app_error_page.dart` | Tetap sebagai UI error lintas fitur. |
| `lib/features/notes/**` | Tetap pada tempatnya; sudah mengikuti pola feature-first. |


## Over-engineering dan use case

Jawaban awal menyarankan tidak membuat use case untuk setiap operasi CRUD
secara otomatis. Untuk operasi seperti `GET /announcements`, notifier/provider
dapat memanggil interface repository langsung. Use case layak ditambahkan
ketika ada aturan bisnis, orkestrasi beberapa dependency, operasi dipakai ulang,
atau perlu diuji terisolasi.

Use case login dapat bermanfaat bila login mengorkestrasi autentikasi,
penyimpanan token, dan aturan sesi. Sebaliknya, wrapper yang hanya meneruskan
satu pemanggilan repository menambah file dan navigasi kode tanpa perilaku
tambahan.

## Wiring Riverpod yang diusulkan


```dart
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => SecureTokenDataSource(),
);

final rawDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
  ref.onDispose(dio.close);
  return dio;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(rawDioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(
    AnnouncementRemoteDataSource(ref.watch(authenticatedDioProvider)),
  );
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) {
  return ref.watch(announcementRepositoryProvider).getAnnouncements();
});
```