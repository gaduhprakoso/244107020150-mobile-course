import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Aplikasi'),
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        
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