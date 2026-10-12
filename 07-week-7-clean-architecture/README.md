## week 7 Clean Architecture

## Tujuan pembelajaran
- menjelaskan prinsip SOLID dan separation of concerns dengan contoh kode Flutter;
- membedakan struktur feature-first vs layer-first beserta trade-off-nya;
- menjelaskan tiga layer (presentation, domain, data) dan aturan dependensi (dependensi mengarah ke dalam);
- membedakan entity vs model serta peran repository, use case, dan dependency injection;
- merefactor project Minggu 5/6 menjadi struktur feature-first yang terpisah layer-nya;
- menguji use case dengan repository palsu tanpa database atau jaringan sungguhan.

## Praktikum 1: Audit layer project lama

### 1. Petakan file ke layer

| File | Layer | Masalah |
|---|---|---|
| lib/pages/home_page.dart | presentation | UI terlalu banyak menangani logic: logout, toggle notifikasi, dan akses service langsung. Ini titik paling jelas pelanggaran separation of concerns. |
| lib/pages/login_page.dart | presentation | Validasi email/password ada di widget. Boleh untuk UI validation, tapi jika makin besar akan bercampur dengan business rule. |
| lib/providers/auth_provider.dart | presentation (state) | Provider berperan sebagai state + wiring dependency sekaligus. Di sini auth logic, token store, dan repository dipakai langsung; terlalu berat dan mencampur layer. |
| lib/data/auth_repository.dart | data | Repository yang seharusnya hanya akses data malah berisi validasi email/password dan mock token. Ini masuk logika bisnis, bukan data-only. |
| lib/data/api_client.dart | data | Masuk layer data yang benar, tapi refresh session dan header auth dibuat di satu tempat. Bisa membuat client terlalu berat dan sulit dipisah saat refactor clean architecture. |
| lib/messaging/push_services.dart | data / infrastructure | Akses Firebase Messaging dan local notification langsung. Ini memang layer data/infrastructure, tapi UI masih tergantung detail implementasinya. |

### 2. Tandai tiga pelanggaran klasik

Cari dengan grep di project Anda:

```bash
# Widget / halaman yang terlalu banyak menangani layanan dan state
rg "ref.read\(|context.go\(|ScaffoldMessenger|FirebaseMessaging|subscribeToTopic|unsubscribeFromTopic" lib/pages lib/providers

# Logika bisnis yang masih berada di UI atau repository
rg "email.contains\(|password.length|DateTime|jsonDecode|map\(|toJson\(|parse\(" lib/

# Instansiasi manual / dependency yang bocor ke layer presentation
rg "AuthRepository\(|TokenStore\(|PushService\(|Dio\(|FirebaseMessaging\.instance" lib/
```

## Praktikum 2: Domain dan data per fitur

### 1. Entity murni (domain)
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
}
```

### 2. Failure dan kontrak repository (domain)
```
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
```

```
import '../../domain/entities/note.dart';
import '../../../../core/failures.dart';

abstract class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  });

```

### 3. Model dan implementasi (data)

```
import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    super.id,
    required super.title,
    super.body = '',
    required super.updatedAt,
    super.dirty = false,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty ? 1 : 0,
      };

  factory NoteModel.fromMap(Map<String, Object?> map) {
    return NoteModel(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  Note toEntity() => Note(
        id: id,
        title: title,
        body: body,
        updatedAt: updatedAt,
        dirty: dirty,
      );
}
```
```
import 'package:sqflite/sqflite.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required Future<Database> Function() openDb})
      : _openDb = openDb;

  final Future<Database> Function() _openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await _openDb();
      final rows =
          await db.query('notes', orderBy: 'updated_at DESC');
      final notes =
          rows.map((r) => NoteModel.fromMap(r).toEntity()).toList();
      return (notes: notes, failure: null);
    } catch (e) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await _openDb();
      final now = DateTime.now();
      final id = await db.insert(
        'notes',
        NoteModel(
            title: title, body: body, updatedAt: now, dirty: true)
            .toMap(),
      );
      return (
        note: Note(id: id, title: title, body: body,
            updatedAt: now, dirty: true),
        failure: null,
      );
    } catch (e) {
      return (note: null,
          failure: LocalFailure('Gagal menyimpan catatan: $e'));
    }
  }
}
```

### 4. Use case: satu operasi bisnis
```
import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  const GetNotes(this._repository);
  final NoteRepository _repository;

  Future<({List<Note> notes, Failure? failure})> call() {
    return _repository.fetchNotes();
  }
}
```

## Praktikum 3: Presentation, DI, dan verifikasi

### 1. Dependency injection dengan Riverpod

```
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/entities/note.dart';

// Data layer: database opener disuntikkan (mudah diganti fake saat test)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// Domain layer: use case menerima abstraksi, bukan implementasi
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

// Presentation layer: state untuk UI
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.notes;
});
```

### 2. Halaman hanya membaca state
```
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    return state.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(notesProvider),
      ),
      data: (notes) => notes.isEmpty
          ? const Center(child: Text('Belum ada catatan.'))
          : NotesList(notes),
    );
  }
}

```
### 3. Verifikasi dependency rule

```
# 1. Presentation steril dari data mentah (harus NOL hasil)
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation lib/pages

# 2. Domain steril dari framework & package (harus NOL hasil)
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core

# 3. Static analysis + test
flutter analyze
flutter test
```
## AI Challenge

### AI Prompt Challenge

```
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```
### verifikasi

**Apakah interface repository tinggal di domain dan implementasi di data?** Sebagian (Notes sudah terpisah, Auth belum).

**Apakah domain bebas import Flutter/Dio/SQLite/Firebase?** Lulus. Hasil pencarian pada folder lib/features/**/domain dan lib/core membuktikan tidak ada import package eksternal tersebut. 

**Apakah AI membuat use case untuk tiap CRUD satu-baris?** Ya, namun ini dianggap tidak lulus prinsip kesederhanaan (over-engineering)

**Apakah entity bebas mapping (toMap/fromMap/toJson hanya di model)?**
Lulus untuk Notes. Entity Note di layer domain bersih dari fungsi konversi. Logika mapping (seperti SQLite) sudah diletakkan dengan benar di dalam NoteModel pada layer data.

**Apakah wiring DI terpusat di provider dan widget tidak new Repository() sendiri?**
Sebagian (UI sudah bersih dari inisialisasi manual, tapi file provider masih tersebar).

**Keputusan final dan alasan teknis Anda, boleh berbeda dari saran AI selama berargumen.**
- Sederhanakan Arsitektur: Hapus use case yang hanya berupa CRUD 1-baris.

- Tunda Refactor Auth: Pemisahan interface Auth baru dilakukan saat integrasi API/backend asli.

- Tunda Fitur Announcements: Layer data dan domain baru dibuat setelah kontrak endpoint API tersedia.

- Rapikan Kode: File provider perlu dikumpulkan agar terpusat, dan logika PushService di UI akan dipindah ke notifier jika nantinya makin kompleks.
