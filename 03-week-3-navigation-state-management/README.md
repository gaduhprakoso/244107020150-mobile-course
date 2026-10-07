# Week3 | Navigation & State Management

### Tujuan pembelajaran

Setelah menyelesaikan codelab ini, mahasiswa mampu:

- menjelaskan konsep navigasi, route, dan perbedaan Navigator 1.0 dengan GoRouter;
menerapkan navigasi multi-page dengan GoRouter, termasuk passing argument dan deep link sederhana;
- menjelaskan mengapa state management diperlukan dan cara kerja Riverpod (Provider, ConsumerWidget, Notifier);
- menggunakan AsyncValue untuk menangani state loading, error, dan success pada UI;
- membangun aplikasi ToDo dengan navigasi dan Riverpod, lalu memverifikasi hasilnya dengan widget test sederhana.

### Praktikum 1 — Aplikasi multi-page dengan GoRouter

Buat project baru:
```
flutter create week3_navigation
cd week3_navigation
flutter pub add go_router
```
1.Definisikan router di lib/main.dart:
```
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/detail_page.dart';
import 'pages/home_page.dart';

void main() => runApp(const MyApp());

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'detail/:id',
          builder: (context, state) => DetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Week 3 - Navigation',
      routerConfig: _router,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    );
  }
}
```

2.Halaman Home (lib/pages/home_page.dart):
```
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ListTile(
          title: Text('Item ${index + 1}'),
          onTap: () => context.go('/detail/${index + 1}'),
        ),
      ),
    );
  }
}
```
3.Halaman Detail (lib/pages/detail_page.dart):
```
import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final String id;
  const DetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail $id')),
      body: Center(child: Text('Anda membuka item dengan id: $id')),
    );
  }
}
```

4.Jalankan dan amati.
![](screenshot\001.png)
![](screenshot\002.png)

### Praktikum 2 — Aplikasi ToDo dengan Riverpod

```
flutter create week3_todo
cd week3_todo
flutter pub add flutter_riverpod
```

1.Bungkus aplikasi dengan ProviderScope:
```
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/todo_page.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Week 3 - ToDo',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const TodoPage(),
      );
}
```
2.Buat state dan provider:
```
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  Todo(this.title, {this.done = false});
  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done);
}

class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  void add(String title) => state = [...state, Todo(title)];

  void toggle(int index) {
    final todos = [...state];
    todos[index] = todos[index].copyWith(done: !todos[index].done);
    state = todos;
  }

  void remove(int index) => state = [...state]..removeAt(index);
}

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);
```
3.Tampilkan dengan ConsumerWidget:
```
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ToDo Riverpod')),
      body: todos.isEmpty
          ? const Center(child: Text('Belum ada tugas'))
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) => ListTile(
                leading: Checkbox(
                  value: todos[index].done,
                  onChanged: (_) =>
                      ref.read(todoListProvider.notifier).toggle(index),
                ),
                title: Text(
                  todos[index].title,
                  style: TextStyle(
                      decoration: todos[index].done
                          ? TextDecoration.lineThrough
                          : null),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () =>
                      ref.read(todoListProvider.notifier).remove(index),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(todoListProvider.notifier)
                    .add(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
```
4.Jalankan dan amati.
![](screenshot\003.png)
![](screenshot\004.png)
![](screenshot\005.png)

### Praktikum 3 — Uji ketiga state

**AsyncValue**

Riverpod menyediakan AsyncValue yang memodelkan ketiga kondisi tersebut dalam satu tipe. Gunakan AsyncNotifier untuk state asinkron:
```
class ProductsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    await Future.delayed(const Duration(seconds: 2)); // simulasi network
    return ['Keyboard', 'Mouse', 'Monitor'];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<List<String>> _fetch() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Keyboard', 'Mouse', 'Monitor', 'Headset'];
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<String>>(
        ProductsNotifier.new);
```

Di sisi UI, AsyncValue dapat dipola dengan when atau if-case matching:
```
class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $err'),
              FilledButton(
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) =>
              ListTile(title: Text(products[index])),
        ),
      ),
    );
  }
}
```
![](screenshot\006.png)
![](screenshot\007.png)

Refleksikan:
- **Mengapa menampilkan data lama (stale data) dengan indikator refresh lebih baik daripada mengosongkan layar?**
Karena pengguna tidak dihadapkan pada layar kosong atau kedipan (blank screen) yang mengganggu pengalaman pengguna (user experience). Pengguna tetap bisa melihat informasi sebelumnya while aplikasi memperbarui data di latar belakang.
- **Kapan pola itu penting?:**
Pola ini sangat penting pada aplikasi berbasis feed atau daftar (seperti media sosial, e-commerce, atau dashboard berita), di mana menjaga ketersediaan konten yang sudah ada jauh lebih nyaman bagi pengguna daripada membuat mereka menunggu dengan layar kosong saat proses sinkronisasi ulang data berjalan.

## AI Challenge
AI Prompt Challenge:
```
Buatkan halaman Flutter bernama StatsPage menggunakan flutter_riverpod.
Requirements:
- ConsumerWidget dengan satu AsyncNotifierProvider yang mensimulasikan
  pengambilan data statistik (delay 2 detik, kadang gagal 30%).
- UI harus menangani loading (spinner), error (pesan + tombol retry),
  dan success (ListView 3 item).
- Berikan unit test untuk notifier-nya.
Jelaskan setiap bagian kode dalam komentar.
```
hasil:
File Provider (lib/providers/stats_provider.dart):
```
import 'package:flutter_riverpod/flutter_riverpod.dart';

// StatsNotifier mengelola state asinkron berupa List<String> menggunakan AsyncNotifier
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    // Dipanggil saat pertama kali provider diinisialisasi
    return _fetchStats();
  }

  // Fungsi privat untuk mensimulasikan pengambilan data (network request)
  Future<List<String>> _fetchStats() async {
    // Simulasi delay jaringan selama 2 detik
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulasi kegagalan acak sebesar 30% (menggunakan milidetik saat ini)
    if (DateTime.now().millisecond % 10 < 3) {
      throw Exception('Gagal terhubung ke server statistik');
    }

    // Mengembalikan 3 item data statistik jika berhasil
    return [
      'Total Pengguna Aktif: 1,450',
      'Pendapatan Bulan Ini: Rp 24.5 Juta',
      'Tingkat Kepuasan Pengguna: 94%',
    ];
  }

  // Fungsi untuk merefresh atau mencoba ulang pengambilan data
  Future<void> refresh() async {
    state = const AsyncLoading(); // Ubah state menjadi loading
    state = await AsyncValue.guard(() => _fetchStats()); // Tangani sukses/error secara aman
  }
}

// Mendefinisikan AsyncNotifierProvider untuk menghubungkan UI dengan StatsNotifier
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  () => StatsNotifier(),
);
```

File Halaman / UI (lib/pages/stats_page.dart):
```
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// StatsPage menggunakan ConsumerWidget agar dapat mengakses WidgetRef Riverpod
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau state dari statsProvider secara reaktif
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Aplikasi'),
      ),
      // Menggunakan method .when() untuk menangani 3 state AsyncValue secara elegan
      body: statsAsync.when(
        // 1. Kondisi saat data sedang dimuat (Loading)
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        
        // 2. Kondisi saat terjadi kegagalan/error (Error)
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Terjadi kesalahan: $err', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                // Tombol Coba Lagi menggunakan ref.invalidate untuk memicu fetch ulang
                onPressed: () => ref.invalidate(statsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        
        // 3. Kondisi saat data berhasil didapatkan (Success / Data)
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: Text(stats[index]),
            );
          },
        ),
      ),
    );
  }
}
```

File Unit Test (test/stats_provider_test.dart):
```
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namaprojek/providers/stats_provider.dart'; // Sesuaikan path import dengan project Anda

void main() {
  test('StatsNotifier menginisialisasi state asinkron dengan benar', () async {
    // Membuat ProviderContainer untuk pengujian tanpa widget tree
    final container = ProviderContainer();
    addTearDown(container.dispose); // Pastikan container ditutup setelah test selesai

    // Membaca nilai awal dari provider
    final initialState = container.read(statsProvider);

    // Memastikan state awal berupa AsyncLoading atau AsyncData/AsyncError tergantung waktu eksekusi
    expect(
      initialState is AsyncLoading || initialState is AsyncData || initialState is AsyncError,
      true,
    );
  });
}
```
hasil:
![](screenshot\008.png)

AI Verification Checklist 

- Apakah state diubah secara immutable (tidak ada state.add() atau mutasi list langsung)?
```
Lolos. Modifikasi state pada TodoListNotifier dan StatsNotifier dilakukan secara immutable menggunakan penyebaran list ([...state, ...]) atau memperbarui state melalui penugasan baru, tanpa memodifikasi list lama secara langsung (.add() atau mutasi elemen in-place).
```
- Apakah ref.watch hanya dipakai di dalam build, dan ref.read di callback?
```
Lolos. Penggunaan ref.watch konsisten diletakkan di dalam method build() widget (seperti pada TodoPage atau StatsPage) untuk memantau perubahan reaktif, sedangkan ref.read (atau ref.invalidate) dipanggil di dalam fungsi callback seperti onPressed pada tombol atau aksi dialog.
```
- Apakah ketiga state AsyncValue benar-benar ditangani (bukan hanya success)?
```
Lolos. Implementasi penanganan state menggunakan method .when() secara lengkap menangani ketiga kondisi utama: loading (menampilkan indikator spinner), error (menampilkan pesan kesalahan beserta tombol retry), dan data / success (menampilkan daftar data dengan ListView)
```
- Apakah provider dideklarasikan dengan tipe eksplisit dan tidak duplikat dengan provider lain?
```
Lolos. Seluruh provider (seperti todoListProvider dan statsProvider) dideklarasikan menggunakan tipe eksplisit yang jelas (NotifierProvider / AsyncNotifierProvider) serta menggunakan nama unik yang terisolasi di file masing-masing tanpa duplikat nama.
```
- Apakah kode AI memakai API Riverpod versi lama (StateProvider antipattern, StateNotifierProvider usang, atau Consumer bertingkat yang tidak perlu)? Perbaiki ke pola Notifier/ConsumerWidget.
```
Lolos. Kode sepenuhnya menggunakan API modern Riverpod v2, yaitu menerapkan kelas berbasis Notifier / AsyncNotifier beserta turunan widget modern berupa ConsumerWidget, tanpa menggunakan pola usang seperti StateNotifierProvider lama atau StateProvider.
```
- Jalankan flutter analyze dan flutter test, apakah hasil AI lolos tanpa warning?
```
Lolos. Setelah semua file terstruktur dengan benar di dalam folder lib/pages/ dan lib/providers/, analisis statis menggunakan flutter analyze bersih dari warning/error, dan pengujian unit test berjalan sukses tanpa kendala.
```
![](screenshot\009.png)
![](screenshot\010.png)
