# Week 5 Offline Notes

### Tujuan pembelajaran

Setelah menyelesaikan codelab ini, mahasiswa mampu:

- menjelaskan konsep HTTP, REST API, dan JSON;
- memetakan JSON ke model Dart (serialization) dengan aman null;
- menerapkan repository pattern dasar sehingga UI tidak 
- memanggil API secara langsung;
- mengonfigurasi Dio (base URL, timeout, interceptor) dan menangani error jaringan;
- menampilkan state loading, error, empty, dan success pada UI dengan AsyncValue + Riverpod;
- menerapkan pagination dasar (infinite scroll).

### Praktikum 1: SharedPreferences
siapkan project:
```
flutter create week5_offline_notes
cd week5_offline_notes
flutter pub add flutter_riverpod shared_preferences sqflite path
```
1.Repository preferensi
```
import 'package:shared_preferences/shared_preferences.dart';

class PrefsRepository {
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> markOpenedNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
  }

  Future<String?> getLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenedKey);
  }
}
```
2.Provider dan halaman pengaturan

```
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());
final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}
```
### Praktikum 2: SQLite dan repository catatan
1.Model catatan
```
class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty ? 1 : 0,
      };

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
    );
  }
}
```
2.Pembuka Database
```
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE cached_posts(
          id INTEGER PRIMARY KEY,
          payload TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    },
  );
}
```
3.Repository sebagai satu-satunya pintu data
```
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> addNote({required String title, String body = ''}) async {
    final db = await _openDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    final id = await db.insert('notes', note.toMap());
    return Note(
      id: id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: true,
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countDirty() async {
    final db = await _openDb();
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

  Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
  }
}
```
### Praktikum 3: Cache-first dan antrean sync
1.Cache-first read untuk data API
```
Future<List<Post>> loadPostsCacheFirst() async {
  final cached = await readCachedPosts(); // dari tabel cached_posts
  // 1. Segera kembalikan cache agar UI tidak blank saat offline.
  // 2. Di background: fetch Dio -> simpan ke cached_posts -> invalidate provider.
  refreshPostsInBackground();
  return cached;
}
```
2.Sinkronisasi catatan kotor (dirty)
```
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
```
### AI Challenge
Minta AI coding assistant (Cursor, Copilot, Claude Code, atau tool setara) dengan prompt berikut:

### AI Prompt Challenge
```
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

### AI Verification Checklist

1. **Apakah daftar catatan disimpan di SharedPreferences?** Tidak. SharedPreferences hanya untuk preferensi kecil seperti tema. Catatan disimpan di SQLite (sqflite) karena mendukung query dan manajemen data terstruktur.
2. **Apakah skema mendukung antrean sync?** Ya (lokal). Skema menggunakan penanda dirty dan updated_at untuk data yang belum terkirim, meski belum menjadi sistem sync server penuh yang tahan konflik.
3. **Apakah real-time didukung stream?** Tidak. Implementasi sqflite menggunakan Future. Pembaruan UI dilakukan secara eksplisit lewat invalidasi provider setiap selesai operasi CRUD.
4. **Apakah estimasi boilerplate sudah dibandingkan lewat instalasi semua
   opsi?**
   Belum. Kesimpulan bahwa setup Drift lebih rumit (butuh code-gen) didasarkan pada perbandingan arsitektur, bukan uji coba instalasi.
5. **Keputusan final: setuju dengan rekomendasi AI.** 
Gunakan SharedPreferences untuk pengaturan dan sqflite untuk catatan. Kombinasi ini sudah memadai untuk CRUD offline dan antrean sync dasar tanpa perlu kompleksitas Drift saat ini.

## Screenshots

![](screenshots\001.png)
![](screenshots\003.png)
![](screenshots\002.png)
![](screenshots\004.png)


## Refleksi

### 1. Mengapa daftar catatan tidak disimpan di SharedPreferences?

haredPreferences didesain untuk data key-value sederhana. Menyimpan daftar catatan di dalamnya memaksa aplikasi membaca dan menulis ulang seluruh data untuk setiap perubahan kecil, sehingga tidak efisien, rentan korup, dan tidak memiliki fitur query atau indeks.

### 2. Kapan strategi cache-first cukup?

Cocok untuk data informatif yang tetap berguna meski sedikit tertinggal (misal: artikel/postingan), sehingga aplikasi tetap responsif saat offline. Jangan gunakan untuk data yang cepat berubah dan krusial (seperti harga saham atau stok barang) yang mewajibkan strategi network-first.

### 3. Bagaimana dirty flag menjadi antrean sync?

Flag dirty=1 menandai catatan yang diubah offline agar UI bisa langsung diperbarui, sementara proses di background mencari flag ini untuk diunggah ke server. Namun, implementasi saat ini baru sebatas simulasi. Untuk sistem sync produksi yang kompleks (mendukung urutan operasi, hapus, dan retry), diperlukan tabel outbox terpisah.

### 4. Rekomendasi AI mana yang ditolak?

Pilihan teknologinya disetujui (SharedPreferences + sqflite), namun klaim berlebihannya ditolak. Flag dirty saat ini belum merupakan antrean sync yang utuh, dan aplikasinya belum real-time karena masih menggunakan Future (bukan stream query seperti Drift). Upgrade ini baru akan dipertimbangkan jika kebutuhannya sudah mendesak.
