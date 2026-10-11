# Authentication, Security & FCM

### Tujuan pembelajaran

Setelah menyelesaikan codelab ini, mahasiswa mampu:

- menjelaskan alur autentikasi (Firebase Auth / JWT / OAuth / Google Login) dan perbedaan ID token vs access token vs refresh token;
- menyimpan token secara aman dengan secure storage serta menerapkan token refresh otomatis;
- menjelaskan arsitektur FCM: app server, Firebase, dan perangkat;
- meminta notification permission dan mengelola token lifecycle (getToken, onTokenRefresh);
- membedakan notification payload vs data payload serta perilakunya pada state foreground, background, dan terminated;
- menangani klik notifikasi (deep link dengan GoRouter) dan topic messaging;
- menerapkan prinsip keamanan dasar aplikasi mobile (tidak menyimpan secret di kode, tidak log token).

### Praktikum 1: Login + secure storage + token refresh
siapkan project:
```
flutter create campus_notify
cd campus_notify
flutter pub add flutter_riverpod go_router dio flutter_secure_storage
flutter pub add firebase_core firebase_messaging flutter_local_notifications
```
1.Penyimpanan token yang aman
```
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> readAccess() => _storage.read(key: _accessKey);
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> clear() => _storage.deleteAll();
}
```
2.Repository auth (mock yang siap diganti Firebase Auth)

```
class AuthSession {
  const AuthSession({required this.access, required this.refresh});
  final String access;
  final String refresh;
}

class AuthRepository {
  // GANTI titik ini dengan FirebaseAuth.instance.signInWithEmailAndPassword
  // atau GoogleSignIn saat backend Firebase sudah siap.
  Future<AuthSession> login(
      {required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!email.contains('@') || password.length < 6) {
      throw Exception('Email atau kata sandi tidak valid');
    }
    // Simulasi JWT: header.payload.signature (jangan parse manual di produksi,
    // gunakan verifikasi server).
    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  Future<String> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) throw Exception('Refresh token hilang');
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}
```
3.Dio dengan refresh otomatis

```
import 'package:dio/dio.dart';
import 'auth_repository.dart';
import 'token_store.dart';

Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final access = await store.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      if (e.response?.statusCode == 401) {
        final refresh = await store.readRefresh();
        if (refresh == null) return handler.next(e);
        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);
          final retry = await dio.fetch(
            e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
          );
          return handler.resolve(retry);
        } catch (_) {
          await store.clear(); // refresh ikut mati -> paksa login ulang
        }
      }
      handler.next(e);
    },
  ));
  return dio;
}
```
4.Provider auth + guard route
```
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}
```
### Praktikum 2: FCM, permission, dan token lifecycle
1.Minta izin notifikasi
```
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _local = FlutterLocalNotificationsPlugin();

Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true, badge: true, sound: true,
    announcement: false, carPlay: false, criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      // Klik banner foreground -> teruskan payload ke router.
      pendingDeepLink = response.payload;
    },
  );
}

String? pendingDeepLink;
```
2.Token lifecycle: ambil, kirim ke backend, pantau perubahan
```
Future<void> initFcmToken({required Future<void> Function(String token) onToken}) async {
  // 1. Ambil token saat ini dan kirim ke backend.
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  // 2. Token bisa berubah (reinstall, clear data, rotasi keamanan).
  //    Listener ini WAJIB ada, jika tidak backend menyimpan token basi.
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  // 3. Langganan topik kampus (mis. semua mahasiswa angkatan).
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}
```
![](screenshots\001.png)

### Praktikum 3: Payload, tiga app state, klik dan topik
1.Background handler wajib top-level
```
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Jangan akses BuildContext / Riverpod di sini.
  // Tugasnya: catat / simpan ringan saja. Navigasi dilakukan saat klik.
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
```
2.Tiga handler + contoh payload gabungan
```
void listenForeground(void Function(String route) go) {
  // Foreground: sistem TIDAK menampilkan banner otomatis,
  // jadi tampilkan manual via local notification.
  FirebaseMessaging.onMessage.listen((message) async {
    final route = message.data['route'] ?? '/';
    const androidDetails = AndroidNotificationDetails(
      'pengumuman', 'Pengumuman Kampus',
      importance: Importance.high, priority: Priority.high,
    );
    await _local.show(
      message.hashCode,
      message.notification?.title ?? 'Pengumuman',
      message.notification?.body ?? '',
      const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  // Background -> diklik.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(message.data['route'] ?? '/');
  });
}

Future<void> handleTerminated(void Function(String route) go) async {
  // Terminated -> dibuka dari notifikasi.
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(initial.data['route'] ?? '/');
  if (pendingDeepLink != null) go(pendingDeepLink!);
}
```
### AI Challenge
Minta AI coding assistant (Cursor, Copilot, Claude Code, atau tool setara) dengan prompt berikut:

### AI Prompt Challenge
```
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

### AI Verification Checklist

#### Hasil verifikasi implementasi

**Apakah background handler berupa fungsi top-level dengan @pragma('vm:entry-point')?**
Ya. Handler (firebaseMessagingBackgroundHandler) sudah berada di luar kelas (top-level) dan menggunakan pragma tersebut.

**Apakah onTokenRefresh benar-benar mengirim token baru ke backend, bukan hanya dicetak ke log?***
Belum. Saat ini token belum dikirim dan baru dicatat/divalidasi saja karena URL backend untuk endpoint POST /devices belum tersedia.

**Apakah foreground memakai local notification manual?**
Ya. Menggunakan flutter_local_notifications.show() pada listener onMessage.

**Apakah klik dari ketiga state masuk ke rute yang benar?**
Secara alur kode ya, tapi belum diuji di perangkat. Berikut bukti jalurnya (contoh rute /pengumuman/123):
- Foreground: Memakai handler onMessage ➔ tap diteruskan ke router.
- Background: Memakai handler onMessageOpenedApp ➔ membaca data.route.
- Terminated: Memakai handler getInitialMessage() ➔ membaca data.route saat aplikasi dimulai.

**Apakah token/secret tidak di-hardcode dan tidak di-log penuh?**
Ya, aman. Nilai token tidak dicetak utuh di log. Authorization di API klien hanya memakai placeholder literal ('******') dan tidak ada kredensial yang di-hardcode.

## Screenshots

![](screenshots\003.png)
![](screenshots\002.png)
![](screenshots\004.png)


## Refleksi

### 1. Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?

Penyimpanan ini berupa teks biasa (tidak dienkripsi). Jika bocor (misal perangkat di-root/terkena malware), peretas bisa menggunakan refresh token yang berumur panjang untuk membajak akun secara permanen tanpa perlu login ulang. Selalu gunakan Secure Storage.

### 2. Apa yang rusak bila onTokenRefresh diabaikan selama satu semester perkuliahan?

Token FCM bisa berubah (karena clear data, ganti HP, atau reset sistem). Jika pembaruan token tidak dikirim ke backend, server akan terus mengirim pesan ke token lama yang sudah mati. Akibatnya, mahasiswa gagal menerima notifikasi sama sekali selama satu semester.

### 3. Kapan memakai topik dan kapan memakai token perangkat? Beri contoh pesan kampus untuk masing-masing.

- Token Perangkat (Personal / 1-to-1): Untuk pesan spesifik ke satu pengguna.
Contoh: "Nilai Pemrograman Mobile Anda sudah keluar."
- Topik (Broadcast / 1-to-Many): Untuk pengumuman massal ke kelompok tertentu.
Contoh: "Perkuliahan D4 Teknik Informatika diliburkan hari ini."

