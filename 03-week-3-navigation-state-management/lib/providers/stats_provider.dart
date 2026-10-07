import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return _fetchStats();
  }

  Future<List<String>> _fetchStats() async {
    // Simulasi delay jaringan selama 2 detik
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulasi kegagalan acak sebesar 30% (menggunakan milidetik saat ini)
    if (DateTime.now().millisecond % 10 < 3) {
      throw Exception('Gagal terhubung ke server statistik');
    }

    return [
      'Total Pengguna Aktif: 1,450',
      'Pendapatan Bulan Ini: Rp 24.5 Juta',
      'Tingkat Kepuasan Pengguna: 94%',
    ];
  }

  Future<void> refresh() async {
    state = const AsyncLoading(); 
    state = await AsyncValue.guard(() => _fetchStats()); 
  }
}

final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  () => StatsNotifier(),
);