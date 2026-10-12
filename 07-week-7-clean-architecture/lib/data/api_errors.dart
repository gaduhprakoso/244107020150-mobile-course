import 'package:dio/dio.dart';

import '../core/failures.dart';

Failure apiFailureFrom(Object? error) {
  if (error is Failure) return error;
  if (error is! DioException) {
    return const NetworkFailure('Terjadi kesalahan. Silakan coba lagi.');
  }

  if (error.response?.statusCode == 401) {
    return const NetworkFailure('Sesi Anda berakhir. Silakan masuk kembali.');
  }

  final message = switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout =>
      'Koneksi terlalu lama. Periksa jaringan lalu coba lagi.',
    DioExceptionType.connectionError =>
      'Tidak dapat terhubung. Periksa koneksi internet Anda.',
    DioExceptionType.badCertificate ||
    DioExceptionType.badResponse ||
    DioExceptionType.cancel ||
    DioExceptionType.unknown =>
      'Layanan sedang bermasalah. Silakan coba lagi.',
  };
  return NetworkFailure(message);
}
