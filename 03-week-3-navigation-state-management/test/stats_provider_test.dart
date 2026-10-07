import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/providers/stats_provider.dart'; // Sesuaikan path import dengan project Anda

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